require 'parslet'

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

  end

  # A generator for explicit parts: a label (vol, num, part, etc.) followed
  # by a list of either a number_list or letter_list

  def lv_generator(singular, plural, *abbr)
    text_sym = "#{singular}_text".to_sym
    explicit_sym = "#{singular}_explicit".to_sym
    plural_sym = "#{plural}".to_sym

    label_rule = str(plural) | str(singular)
    abbr_label = abbr.map{|a| str(a)}.inject(&:|)
    label =  label_rule | (abbr_label >> dot?)
    self.class.rule(explicit_sym)  { label >> lv_sep >> (numerics | letters).as(plural_sym)}

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

  rule(:list_sep) { comma >> space?}
  rule(:range_sep) { space? >> dash >> space? }

  # What separates a label and its value? A colon, space, or nothing
  rule(:lv_sep) { colon >> space? | space? }


  rule(:digits4) { digit.repeat(4) }
  rule(:digits2) { digit.repeat(2) }

  rule(:year4)     { digits4 }
  rule(:year2)     { digits2 }
  rule(:year_end)  { year4 | year2  }
  rule(:year_dual) { (year4.as(:start) >> slash >> year_end.as(:end)).as(:year_dual) }
  rule(:year_range) { (year4.as(:start) >> dash >> year_end.as(:end)).as(:year_range) }
  rule(:year_dual_range) { (year_dual.as(:start) >> range_sep >> (year_dual | year_end).as(:end)).as(:year_range)}
  rule(:year_list_component) { year_dual_range.as(:range) | year_range.as(:range) | year_dual.as(:dual) | year4.as(:single) }
  rule(:year_list) { year_list_component >> (list_sep >> year_list).repeat(0) }

  # A generic list of letters or letter-ranges
  # The kicker is that we can't have a "list" of letters without a delimiter;
  # we call that a "word" ;-)

  rule(:letter_range) { letter.as(:start) >> range_sep >> letter.as(:end)}
  rule(:letter_list_component) { letter_range.as(:range) | letter.as(:single) }
  rule(:letter_list) { letter_list_component >> (list_sep >> letter_list).repeat(1) }
  rule(:letters) { (letter_list | letter_range).as(:letters) }

  # Same thing, but for numbers/ranges
  rule(:numeric_range) { digits.as(:start) >> range_sep >> digits.as(:end)}
  rule(:numeric_list_component) { numeric_range.as(:range) | digits.as(:single) }
  rule(:numeric_list) {numeric_list_component >> (list_sep >> numeric_list).repeat(0) }
  rule(:numerics) { numeric_list.as(:numeric) }



  # An explicit year is one that includes a 'year' or 'yr'
  rule(:year_text) { str('year') | (str('yr') >> dot? )}
  rule(:year_explicit) { year_text >> lv_sep >> year_list.as(:years) }

  # .. and implicit if it doesn't
  rule(:year_implicit) { year_list.as(:iyears) }


  # The "explicit" rule is added to by lv_generator, which sets @expl
  rule(:explicit) { year_explicit | @expl }

  # Sometimes, there's an unknown list of letters or number and we
  # just don't know what it is

  rule(:unknown_list) { (numerics | letters).as(:unknown_list) }


  # Sometimes it'll be labeled as "index". Just note that.
  rule(:index) { str('index').as(:index) }


  rule(:comp) { explicit |
                year_implicit |
                index |
                unknown_list }

  rule(:ec_delim) { space? >> (comma | colon)  >> space? | space }
  rule(:ec) { comp >> (ec_delim >> ec).repeat(1) | comp }
  rule(:ecp) { lparen >> space? >> ec >> space? >> rparen | ec }
  rule(:ecset) { ecp >> (ec_delim.maybe >> ecset).repeat(1) | ecp }


  root(:ecset)





end


if __FILE__ == $0
  p = ECParser.new
  File.open('just_parsed.txt', 'w:utf-8') do |ep|
    File.open('just_failed.txt', 'w:utf-8') do |ef|
      infile = ARGV[0].nil? ? $stdin : File.open(ARGV[0])
      infile.each do |l|
        orig = l
        l.chomp!
        l.downcase!
        l.gsub!('*', '')
        l.gsub!(/\t/, ' ')
        begin
          pt = p.parse(l)
          ep.puts "#{orig}\t#{pt}"
        rescue Parslet::ParseFailed
          ef.puts l
        end
      end
    end
  end
end
