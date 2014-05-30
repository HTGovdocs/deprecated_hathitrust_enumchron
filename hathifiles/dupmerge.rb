require 'set'
require 'library_stdnums'
require 'zlib'
require 'fileutils'

filename = ARGV[0]
basename = File.basename(filename, '.txt.gz')
STDERR.puts "Filename is #{filename}; basename is #{basename}"
task = false
task = :generate if ARGV[1] == 'generate'
task = :merge    if ARGV[1] == 'merge'
task = :both     if ARGV[1] == 'generate' and ARGV[2] = 'merge'


STDERR.puts "Task is #{task}"
unless task
  STDERR.puts "Exiting: task must be 'generate', 'merge', or 'generate merge'"
  exit
end

# Figure out where the marshalling occurs
marshal_dir = "marshal/#{basename}"
FileUtils::mkpath marshal_dir
i2ufile = File.join(marshal_dir, 'i2u.marshal.gz')
u2ifile = File.join(marshal_dir, 'u2i.marshal.gz')

# Ditto with data_dir
data_dir = "data/#{basename}"
FileUtils::mkpath data_dir
masterfile = File.join(data_dir, 'mastersets.txt.gz')
singlefile = File.join(data_dir, 'singles.txt.gz')


# What's the hathifile look like?

HTID     = 0
ACCESS   = 1
RIGHTS   = 2
HTREC    = 3
EC       = 4
SOURCE   = 5
SIR      = 6 # Source institution's record number
OCLC     = 7
ISBN     = 8
ISSN     = 9
LCCN     = 10
TITLE    = 11
IMPRINT  = 12
DETCODE  = 13
UPDATE   = 14
GDOC     = 15
PUBDATE  = 16
PUBPLACE = 17
LANG     = 18
FMT      = 29

@identifiers_of_note = {
    'oclc' => [OCLC, proc { |x| x.to_i }], # to_i
    'lccn' => [LCCN, StdNum::LCCN.method(:normalize)],
    'issn' => [ISSN, StdNum::ISSN.method(:normalize)],
    'isbn' => [ISBN, StdNum::ISBN.method(:normalize)],
    'sir'  => [SIR, nil], # add source below
}

# Build up two ginormous hashes: one mapping uids to sets of identifiers,
# and the other mapping identifiers to sets of uids. For accuracy,
# we'll normalize all the identifiers (OCLC.to_i, stdnum normalize LCCN/
# ISBN/ISSN), pass through the sir.

@iden_to_uids        = {}
@uid_to_idens        = {}

# Get a place to count stuff, just 'cause it's interesting
@counts = {}
@identifiers_of_note.keys.each { |k| @counts[k] = 0 }

EC_JUST_COPY_PAT = /\A\s*(?:c\.|c|copy)\s*\d{1,2}\s*\Z/i

def process_line(l)
  cols   = l.chomp.split(/\t/)

  ## Is it just a copy? Then skip it like we skip stuff
  ## that has no EC at all.
  #if EC_JUST_COPY_PAT.match(cols[EC])
  #  @counts[:just_a_copy] += 1
  #  return
  #end

  uid    = cols[HTID].to_sym
  source = cols[SOURCE]

  @identifiers_of_note.each_pair do |idtype, dat|
    col, normalizer = *dat
    next unless cols[col] =~ /\S/


    @counts[idtype] += 1
    idens           = cols[col].split(',').compact

    idens.map!(&normalizer) if normalizer
    idens.map! { |x| "#{source}#{x}" } if idtype == 'sir' # special handling


    idens.compact!
    idens.map! { |x| "#{idtype}#{x}" }

    if @uid_to_idens[uid]
      @uid_to_idens[uid] += idens
    else
      @uid_to_idens[uid] = Set.new(idens)
    end

    idens.each do |iden|
      @iden_to_uids[iden] ||= Set.new
      @iden_to_uids[iden] << uid
    end
  end
end


if [:generate, :both].include? task
  Zlib::GzipReader.new(File.open(filename, 'r:utf-8')).each_with_index do |l, i|
    process_line(l)
    print '.' if i % 100_000 == 0
  end


  u2idump = Zlib::GzipWriter.new(File.new(u2ifile, 'w:utf-8'))
  i2udump = Zlib::GzipWriter.new(File.new(i2ufile, 'w:utf-8'))

  Marshal.dump(@iden_to_uids, i2udump)
  i2udump.close

  Marshal.dump(@uid_to_idens, u2idump)
  u2idump.close


  puts "\nGot a total of #{@iden_to_uids.size} identifiers and #{@uid_to_idens.size} uids"
  puts @counts
end

# Exit if we're just generating
exit if task == :generate

# If we're just merging, read from disk
if task == :merge
  puts "Loading iden_to_uids"
  @iden_to_uids = Marshal.load(Zlib::GzipReader.new(File.open(i2ufile)))
  puts "Loading uid_to_idens"
  @uid_to_idens = Marshal.load(Zlib::GzipReader.new(File.open(u2ifile)))
end

# OK. Now I have two giants lists. Now we need to
# combine them.

# Recursive UIDS -- get all the UIDS for an identifier

def recursive_uids(baseiden, seen=Set.new)
  return [] unless @iden_to_uids[baseiden] # base case
  return if seen.include? baseiden
  newuids = Set.new
  seen << baseiden
  @iden_to_uids[baseiden].each do |uid|
    next unless @uid_to_idens[uid]
    @uid_to_idens[uid].each do |iden|
      next if seen.include? iden
      newuids += recursive_uids(iden, seen)
      seen << baseiden
      @iden_to_uids[iden] = false
    end
    @uid_to_idens[uid] = false
  end
  newuids
end


puts "Starting a merge"
@iden_to_uids.each_key do |iden|
  next unless @iden_to_uids[iden]
  new_uids = recursive_uids(iden)
  if new_uids.size > 0
    @iden_to_uids[iden] += new_uids
  end
end

@iden_to_uids.delete_if { |k, v| v == false }

puts "After merge, got a total of #{@iden_to_uids.size} identifiers and #{@uid_to_idens.size} uids"

singles = Zlib::GzipWriter.new(File.open(singlefile, 'w:utf-8'))
out     = Zlib::GzipWriter.new(File.open(masterfile, 'w:utf-8'))
@iden_to_uids.each_pair do |iden, uidset|
  if uidset.size == 1
    singles.puts "#{uidset.first}"
  else
    uidset.each do |uid|
      out.puts "#{uid}\t#{iden}"
    end
  end
end

singles.close
out.close


__END__

# get a mapping of uid => set_of_idens
# and iden => set_of_uids
Dir.glob('dups/*.txt').each do |f|
  File.open(f).each_line do |l|
    iden, uids = l.chomp.split(/\t/)
    uids = uids.split(/\|/).map(&:to_i)
    iden_to_uids[iden] = Set.new(uids)
    uids.each do |uid|
      uid_to_iden[uid] ||= Set.new
      uid_to_iden[uid] << iden
    end
  end
end

puts "Got a total of #{iden_to_uids.size} identifiers and #{uid_to_iden.size} uids"

# OK. Now we need to combine then.
#
changed = false
while changed != 0
  puts "Merged #{changed} times" if changed
  changed = 0
  iden_to_uids.each_pair do |masteriden, uidset|
    uidset.each do |uid|
      uid_to_iden[uid].each do |iden|
        next if iden == masteriden
        next unless iden_to_uids[iden]
        iden_to_uids[masteriden] += iden_to_uids[iden]
        iden_to_uids.delete(iden)
        changed += 1
      end
    end
  end
end

puts "After merge, got a total of #{iden_to_uids.size} identifiers and #{uid_to_iden.size} uids"

File.open('dupsets.txt', 'w:utf-8') do |out|
  iden_to_uids.each_pair do |iden, uidset|
    uidset.each do |uid|
      out.puts "#{uid}\t#{iden}"
    end
  end
end
