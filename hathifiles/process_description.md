## Duplicate detection process

### Just stuff with enumchron

* Start with the full hathifile
* throw out everything without an enumchron
* throw out 21_229 items whose enumchron looks like it's just a copy number
* End up with 5_082_842 items that have an enumchron we're interested in
* Consider two items to be "related" if they share any OCLC, ISBN, ISSN, LCCN, or "source instituion record" (sir)
* Recursively (i.e., transitively) merge those relations to make "clusters"
* Ignore the 320_309 clusters with exactly one item in them
* Do analysis on the 499_864 clusters with multiple items

### With a full file

* Start with 11_145_679 items; don't throw *anything* out
* Consider two items to be "related" if they share any OCLC, ISBN, ISSN, LCCN, or "source instituion record" (sir)
* Recursively (i.e., transitively) merge those relations to make "clusters"
* End up with the following clusters
  * 4_914_542 "clusters" with one item (singles)
  * 1_103_933 clusters with multiple items
  * ...for total of 6_018_475 clusters
* Compared to the current method:
  * 5_075_352 "clusters" with one item
  * 1_105_966 clusters with multiple items
  * ...for a total of 6_181_318 clusters


require 'zlib'
require 'json'
require 'marc'
require 'marc_alephsequential'

in = Zlib::GzipReader.new(File.open('/htsolr/catalog/prep/govdocs/umich/umich_gov_docs_20130502.ndj.gz', 'r:utf-8'))
out = 'umich_uid.ndj'

out.close
out = Zlib::GzipWriter.new(File.open('all_uids.ndj.gz', 'w:utf-8'))

def uidify(l, prefix)
  j = JSON.parse(l)
  j['fields'].each do |f|
    if f['001']
      f['001'] = prefix + f['001']
      break
    end
  end
  JSON.fast_generate(j)
end

Zlib::GzipReader.new(File.open('cic_all_uniq.ndj.gz', 'r:utf-8')).each do |l|
  out.puts(uidify(l, 'cic'))
end

Zlib::GzipReader.new(File.open('all_minn_records.ndj.gz', 'r:utf-8')).each do |l|
  out.puts(uidify(l, 'cic'))
end

out.close


def sudoc_normalize(sudoc)
  sudoc.gsub!(/\s*(\p{Punct})\s*/, "\\1")
  sudoc.gsub! /(\p{L})(\p{N})/, "\\1 \\2"
  sudoc.gsub! /(\p{N})(\p{L})/, "\\1 \\2"
  sudoc
end

