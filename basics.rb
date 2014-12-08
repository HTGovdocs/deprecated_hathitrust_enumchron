require 'parslet'
require 'concurrent'


class ECParser < Parslet::Parser

  def initialize(*args)
    super
    lv_generator('number', 'numbers', 'nos', 'no', 'n')
    lv_generator('volume', 'volumes', 'vols', 'vol', 'vs', 'v')
    lv_generator('part', 'parts', 'pts', 'pt')
    lv_generator('copy', 'copies', 'cops', 'cop', 'cps', 'cp', 'c')
    lv_generator('series', 'series', 'ser', 'n.s', 'ns')
    lv_generator('report', 'reports', 'repts', 'rept', 'rep', 'r')
    lv_generator('section', 'section', 'sects', 'sect', 'secs', 'sec')
    lv_generator('appendix', 'appendices', 'apps', 'app')
    lv_generator('title', 'titles', 'ti', 't')

  end

  rule(:safe_letter) { match['abdefghijklmopqrsuwxyz']}

  # A generator for explicit parts: a label (vol, num, part, etc.) followed
  # by a list of either a number_list or letter_list

  def lv_generator(singular, plural, *abbr)
    text_sym     = "#{singular}_text".to_sym
    explicit_sym = "#{singular}_explicit".to_sym
    plural_sym   = "#{plural}".to_sym

    label_rule = str(plural) | str(singular)
    abbr_label = abbr.map { |a| str(a) }.inject(&:|)
    label      = label_rule | (abbr_label >> dot?)
    self.class.rule(explicit_sym) { label >> lv_sep >> (numlets | numerics | letters ).as(plural_sym) }

    if @expl.nil?
      @expl = self.send(explicit_sym)
    else
      @expl = @expl | self.send(explicit_sym)
    end
  end

  rule(:space) { match('\s').repeat(1) }
  rule(:space?) { space.maybe }
  rule(:dot) { str('.') }
  rule(:dot?) { dot.maybe }
  rule(:digit) { match('\d') }
  rule(:digits) { digit.repeat(1) }
  rule(:digits?) { digit.repeat(0) }
  rule(:letter) { match('[a-z]') }
  rule(:letters) { letter.repeat(1) }
  rule(:letters?) { letter.repeat(0) }
  rule(:dash) { str('-') }
  rule(:slash) { str('/') }
  rule(:lparen) { str('(') }
  rule(:rparen) { str(')') }
  rule(:colon) { str(':') }
  rule(:comma) { str(',') }
  rule(:plus) { str('+') }

  rule(:list_sep) { comma >> space? }
  rule(:range_sep) { space? >> dash >> space? }

  # What separates a label and its value? A colon, space, or nothing
  rule(:lv_sep) { colon >> space? | space? }


  rule(:digits4) { digit.repeat(4) }
  rule(:digits2) { digit.repeat(2) }

  rule(:year4) { digits4 }
  rule(:year2) { digits2 }
  rule(:year_end) { year4 | year2 }
  rule(:year_dual) { (year4.as(:start) >> slash >> year_end.as(:end)).as(:year_dual) }
  rule(:year_range) { (year4.as(:start) >> dash >> year_end.as(:end)).as(:year_range) }
  rule(:year_dual_range) { (year_dual.as(:start) >> range_sep >> (year_dual | year_end).as(:end)).as(:year_range) }
  rule(:year_list_component) { year_dual_range.as(:range) | year_range.as(:range) | year_dual.as(:dual) | year4.as(:single) }
  rule(:year_list) { year_list_component >> (list_sep >> year_list).repeat(0) }



  # A generic list of letters or letter-ranges
  # The kicker is that we can't have a "list" of letters without a delimiter;
  # we call that a "word" ;-)

  rule(:letter_range) { letter.as(:start) >> range_sep >> letter.as(:end) }
  rule(:letter_list_component) { letter_range.as(:range) | letter.as(:single) }
  rule(:letter_list) { letter_list_component >> (list_sep >> letter_list).repeat(1) }
  rule(:letters) { (letter_list | letter_list_component).as(:letters) }

  # A "safe" letter range starts with (or just consists of) a letter that is
  # not used by itself to indicate a named part (e.g. v for volume)

  rule(:safe_letter_list_component) { letter_range.as(:range) | safe_letter.as(:single) }
  rule(:safe_letter_list) { safe_letter_list_component >> (list_sep >> letter_list).repeat(1) }
  rule(:safe_letters) { (safe_letter_list | safe_letter_list_component).as(:letters) }



  # Same thing, but for numbers/ranges
  rule(:numeric_range) { digits.as(:start) >> range_sep >> digits.as(:end) }
  rule(:numeric_list_component) { numeric_range.as(:range) | digits.as(:single) }
  rule(:numeric_list) { numeric_list_component >> (list_sep >> numeric_list).repeat(0) }
  rule(:numerics) { numeric_list.as(:numeric) }

  # Again, but this time support number-letter combinations, like 4a-5b or
  # 4a-b. We can't really support 5a,b because of conflicts with things
  # like "no. 5a,v3" where the 'v' should mean 'volume'

  rule(:numlet) { digits.as(:numpart) >> letter_list_component.as(:letpart) }
  rule(:numlet_range) { numlet.as(:start) >> range_sep >> numlet.as(:end) }
  rule(:numlets) {(numlet_range.as(:range) | numlet.as(:single)).as(:numlets)}





  # Ordinals
  rule(:ord_first) { str('1st') }
  rule(:ord_second) { str('2nd') }
  rule(:ord_third) { str('3rd') }
  rule(:ord_other) { match['4567890'] >> str('th') }
  rule(:ord) { digits.maybe >> (ord_first | ord_second | ord_third | ord_other) }

  # Months of the year
  rule(:jan) { str('january') | str('jan') >> dot? }
  rule(:feb) { str('february') | str('feb') >> dot? }
  rule(:mar) { str('march') | str('mar') >> dot? }
  rule(:apr) { str('april') | str('apr') >> dot? }
  rule(:may) { str('may') }
  rule(:jun) { str('june') | str('jun') >> dot? }
  rule(:jul) { str('july') | str('jul') >> dot? }
  rule(:aug) { str('august') | str('aug') >> dot? }
  rule(:sept) { str('september') | (str('sept') | str('sep')) >> dot? }
  rule(:oct) { str('october') | str('oct') >> dot? }
  rule(:nov) { str('november') | str('nov') >> dot? }
  rule(:dec) { str('december') | str('dec') >> dot? }
  rule(:month) { jan | feb | mar| apr | may | jun | jul | aug | sept | oct | nov | dec }


  # Year/month, month/year

  # A supplement or an index just sitting by itself; sometimes it has a list
  rule(:suppl_label) { (str('supplement') | str('suppl') >> dot? | str('supp') >> dot?) }
  rule(:ind_label) { str('index') }
  rule(:suppl) { (suppl_label >> lv_sep >> (numerics | safe_letters) | suppl_label).as(:suppl) }
  rule(:ind) { ((ind_label >> lv_sep >> (numerics | safe_letters)) | ind_label).as(:index) }

  # Sometimes there's a "new series"
  rule(:ns) { (str('new series') | str('new ser.') | str('new ser') | str('n.s.')).as(:ns) }

  # An explicit year is one that includes a 'year' or 'yr'
  rule(:year_text) { str('year') | (str('yr') >> dot?) }
  rule(:year_explicit) { year_text >> lv_sep >> year_list.as(:years) }

  # .. and implicit if it doesn't
  rule(:year_implicit) { year_list.as(:iyears) }


  # The "explicit" rule is added to by lv_generator, which sets @expl
  rule(:explicit) { year_explicit | @expl }

  # Sometimes, there's an unknown list of letters or number and we
  # just don't know what it is

  rule(:unknown_list) { (numerics | letter_range.as(:range)).as(:unknown_list) }


  rule(:comp) { explicit |
      year_implicit |
      ind | suppl | ns | ord.as(:uord) |
      unknown_list }

  rule(:ec_delim) { space? >> (comma | colon) >> space? | space }
  rule(:ec) { comp >> (ec_delim >> ec).repeat(1) | comp }
  rule(:ecp) { lparen >> space? >> ec >> space? >> rparen | ec }
  rule(:ecset) { ecp >> (ec_delim.maybe >> ecset).repeat(1) | ecp }


  root(:ecset)
end


RangeEndpoints = Struct.new(:firstval, :lastval) do
  def to_irange
    Integer(firstval)..Integer(lastval)
  end

  def to_charrange
    (firstval.to_s)..(lastval.to_s)
  end
end


class ECList < Array

end

class IntList < ECList
end

class LetterList < ECList
end

def to_i_or_irange(x)
  if x.respond_to? :to_irange
    x.to_irange
  else
    Integer(x)
  end
end

def to_char_or_charrange(x)
  if x.respond_to? :to_charrange
    x.to_charrange
  else
    x.to_s
  end
end

def year_endpoint_transform(f,s)
  f = f.to_s
  s = s.to_s
  if f.size == 4 and s.size == 2
    if Integer(f[2..3]) > Integer(s)
      s = (Integer(f) / 100 + 1).to_s + s
    else
      s = f[0..1] + s
    end
  end

  if f.size == s.size and s.size == 2
    # TODO
    # Need to interpret this based on incoming years;
    # Right now, assume 1999/2001
    if Integer(f) > Integer(s)
      f = '19' + f
      s = '20' + s
    else # assume 20th century
      f = '19' + f
      s = '19' + s
    end
  end
  f = Integer(f)
  s = Integer(s)
  return f,s
end

def slashed_year(f,s, year1 = 1900, year2 = 2050)
  f,s = year_endpoint_transform(f,s)
  raise "Weird slashed year thingy" if s <= f
  if s == f + 1
    DualYear.new(f.to_i,s.to_i)
  else
    YearRange.new(f.to_i,s.to_i)
  end
end

DualYear  = Struct.new(:firstval, :lastval)
YearRange = Struct.new(:firstval, :lastval)


class ECTransform < Parslet::Transform

  rule(:single=>simple(:x)) { x }
  rule(:range => {:start=>simple(:s), :end=>simple(:e)}) { RangeEndpoints.new(s,e) }
  rule(:range => simple(:x)) { x }

  rule(:numeric => simple(:x)) {IntList[to_i_or_irange(x)]}
  rule(:numeric => sequence(:a)) { IntList[a.map { |x| to_i_or_irange(x)}]}

  rule(:letters => simple(:x)) {LetterList[to_char_or_charrange(x)]}
  rule(:letters => sequence(:a)) { LetterList[a.map { |x| to_char_or_charrange(x)}]}

  rule(:year_dual => {:start => simple(:s), :end=>simple(:e)}) { slashed_year(s,e)}
  rule(:year_range =>{:start => simple(:s), :end=>simple(:e)}) { YearRange.new(*year_endpoint_transform(s,e))}


end



if __FILE__ == $0
  p = ECParser.new
  t = ECTransform.new

  class FakeTP
    def initialize(*args)

    end

    def post(*args, &blk)
      blk.call(*args)
    end
  end

  if defined? JRUBY_VERSION
    thread_pool = Concurrent::ThreadPoolExecutor.new(
        :min_threads     => 3,
        :max_threads     => 3,
        :max_queue       => 9,
        :overflow_policy => :caller_runs
    )
  else
    thread_pool = FakeTP.new
  end


  def preprocess_line(l)
      l.chomp!           # remove trailing cr
      l.downcase!        # lowercase
      l.gsub!('*', '')   # asterisks to nothing
      l.gsub!(/\t/, ' ') # tabs to spaces
      l.strip!           # leading and trailing spaces
      l.gsub!(/[\.,:;\s]+\Z/, '') # trailing punctuation/space
      l
  end


  File.open('just_parsed.txt', 'w:utf-8') do |ep|
    File.open('just_failed.txt', 'w:utf-8') do |ef|
      infile = ARGV[0].nil? ? $stdin : File.open(ARGV[0])
      infile.each do |x|
        thread_pool.post(x) do
          begin
            orig = x
            pt = p.parse(preprocess_line(x))
            ep.puts '%-20s %s' % [x, t.apply(pt)]
          rescue Parslet::ParseFailed
            ef.puts x
          rescue => e
            ef.puts '%-20s %s' % [x, e]
          end
        end
      end

    end
  end
end
