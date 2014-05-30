require 'parslet'

class ECParser < Parslet::Parser

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
  rule(:plus) { str('+') }
  rule(:spcolon) { space | colon }
  rule(:gsep) { spcolon.maybe }


  rule(:rangesep) { space? >> (dash | slash | colon) >> space? }

  rule(:d4) { digit.repeat(4, 4) }
  rule(:d2) { digit.repeat(2, 2) }

  rule(:drange) { digits.as(:start) >> rangesep >> digits.as(:end) | digits.as(:single) }

  # Year ranges: 1999-2000, 1988-89, 88-91
  # More restrictive than generic ranges
  rule(:d4_4) { d4.as(:start) >> rangesep >> d4.as(:end) }
  rule(:d4_2) { d4.as(:start) >> rangesep >> d2.as(:end) }
  rule(:d2_2) { d2.as(:start) >> rangesep >> d2.as(:end) }

  rule(:yrange) { d4_4 | d4_2 | d2_2 | d4.as(:single) | str("'") >> d2.as(:single) }

  # Year lists
  rule(:listsep) { str(',') >> space? }
  rule(:dlist) { drange >> (listsep >> dlist).repeat(0) }
  rule(:ylist) { yrange.as(:year) >> (listsep >> ylist).repeat(0) }

  # Volume
  rule(:volabbr) { str('vols') | str('vol') | str('vs') | str('v') }
  rule(:voltext) { (volabbr >> dot?) | str('volumes') | str('volume') }
  rule(:vol) { voltext >> gsep >> dlist.as(:volumes) }

  # Part
  rule(:partabbr) { str('pts') | str('pt') }
  rule(:parttext) { str('parts') | str('part') | partabbr >> dot? }
  rule(:part) { parttext >> gsep >> dlist.as(:parts) }

  # Number
  rule(:numabbr) {
    str('numbs') |
        str('numb') |
        str('nums') |
        str('num') |
        str('nos') |
        str('no') }
  rule(:numtext) { str('numbers') | str('number') | numabbr >> dot? }
  rule(:numdig) { digits.as(:digits) >> letters.as(:letters) | digits.as(:digits) }
  rule(:numrange) { numdig.as(:start) >> rangesep >> numdig.as(:end) | numdig.as(:single) }
  rule(:numlist) { numrange >> (listsep >> numlist).repeat(0) }
  rule(:number) { numtext >> gsep >> numlist.as(:numbers) }


  # Ordinals
  rule(:ordsuffix) {
        str('st') |
        str('nd') |
        str('rd') |
        str('th')
  }
  rule(:ordsingle) { digits.as(:digits) >> ordsuffix }
  rule(:ordrange) { (ordsingle|digits.as(:digits)).as(:start) >> rangesep >> ord.as(:end) }
  rule(:ord) { ordrange | ordsingle }

  # Edition

  rule(:edabbr) { str('eds') | str('ed') }
  rule(:edtext) { str('editions') | str('edition') | edabbr >> dot? }
  rule(:edition) { ord.as(:edition) >> gsep >> edtext }


  # Report
  rule(:repabbr) { str('rept') | str('repo') | str('rep') }
  rule(:reptext) { str('reports') |
      str('report') |
      repabbr >> dot? }
  rule(:report) { reptext >> gsep >> dlist.as(:reports) }

  # Quarter
  rule(:qabbr) { str('quart') | str('qrtr') | str('qtr') | str('q') }
  rule(:qtext) { str('quarters') | str('quarter') | qabbr >> dot? }
  rule(:qnums) { match('[1234]') }
  rule(:quarter) { qtext >> gsep >> dlist.as(:quarters) }

  # Months / Dates
  rule(:fullmonth) { str('january') |
      str('february') |
      str('march') |
      str('april') |
      str('june') |
      str('july') |
      str('august') |
      str('september') |
      str('october') |
      str('november') |
      str('december') }

  rule(:shortmonth) { str('jan') |
      str('febr') |
      str('feb') |
      str('mar') |
      str('apr') |
      str('may') |
      str('jun') |
      str('jul') |
      str('aug') |
      str('sept') |
      str('sep') |
      str('oct') |
      str('nov') |
      str('dec') }

  rule(:anymonth) { fullmonth | shortmonth >> str('.').maybe }
  rule(:monthrange) { anymonth.as(:start) >> rangesep >> anymonth.as(:end) }
  rule(:month) { monthrange | anymonth.as(:single) }
  rule(:datestr) { anymonth.as(:month) >> space? >> digits.as(:day) }
  rule(:daterange) { datestr.as(:start) >> rangesep >> datestr.as(:end) }
  rule(:date) { daterange | datestr.as(:single) }
  rule(:anydate) { date.as(:date) | month.as(:month) }

  # Supplement: just note that it's there

  rule(:rawsupple) { str('supp') >> str('l').maybe >> dot? | str("supplement") }
  rule(:plussupple) { plus >> rawsupple }
  rule(:suppl) { plussupple.as(:plussupple) | rawsupple.as(:suppl) }


  # Pull it all together
  rule(:comp) { vol | part | number | report  | quarter | anydate | edition | ord.as(:ord) | suppl | ylist }
  rule(:ec_delim) { space? >> (str(',')|str(':')) >> space? | space }
  rule(:ec) { comp >> (ec_delim.maybe >> ec).repeat(0) | dlist.as(:rawdigits) }
  rule(:ecp) { lparen >> space? >> ec >> space? >> rparen | ec }
  rule(:ecset) { ecp >> (ec_delim.maybe >> ecp).repeat(0) | ecp }


  root(:ecset)

end

if __FILE__ == $0
  p = ECParser.new
  File.open('just_parsed.txt', 'w:utf-8') do |ep|
    File.open('just_failed.txt', 'w:utf-8') do |ef|
      File.open(ARGV[0]).each do |l|
        l.chomp!
        l.downcase!
        begin
          pt = p.parse(l)
          ep.puts "#{l} -- #{pt}"
        rescue Parslet::ParseFailed
          ef.puts l
        end
      end
    end
  end
end


__END__



require 'zlib'
require 'pp'

all = Zlib::GzipReader.open('gd_enum.txt.gz')
easy = File.open('easy.txt', 'w:utf-8')
hard = File.open('hard.txt', 'w:utf-8')

cf = Hash.new {0}

all.each do |l|
  l.chomp!
  l.strip!
  case l
  when /\A\d+\Z/
    cf[:just_digits] += 1
    easy.puts l
  when /\Av(?:ol|olume)?\.?\s*\d+\Z/
    cf[:just_single_volume] += 1
    easy.puts l
  when /\A\d{4}\Z/
    cf[:just_single_year] += 1
    easy.puts l
  when /\A(?:no\.|n\.|num\.|num|n|number)\s*\d+\Z/
    cf[:just_single_number] += 1
    easy.puts l
  when /\A(?:p\.|pt\.|part)\s*\d+\Z/
    cf[:just_single_part] += 1
    easy.puts l
  else
    hard.puts l
  end
end

pp cf
