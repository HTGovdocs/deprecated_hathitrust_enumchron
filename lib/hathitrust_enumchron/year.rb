require 'hathitrust_enumchron/atoms'
require 'hathitrust_enumchron/list'
require 'hathitrust_enumchron/range'
require 'hathitrust_enumchron/single_or_slashed_double'

# OK. So we'd like to support all of the following:
#  * 1980
#  * 1980/81
#  * 1980-1981
#  * 1980-1981
#  * 1980/81-1982
#  * 1980/81-1981/82
#  ...and any of those in a list separated by commas or `+` (or, more
#  specifically, anything that's a `list_sep` in atoms.rb)

# Eventually we'll have to get months and dates involved,
# but for now, this class will concentrate on these.

class HT::YearRange < Parslet::Parser
  include HT::Atoms

  rule(:fullyear)   { (str('1') | str('2')) >> digit.repeat(3,3) }
  rule(:halfyear) { digit.repeat(2,2)}
  rule(:year_end) { fullyear | halfyear }
  rule(:year_or_year_slash) { HT::SingleOrSlashedDouble.new(fullyear, year_end) }

  rule(:year_range_start)  { year_or_year_slash }
  rule(:year_range_end)    { year_or_year_slash | halfyear }
  rule(:year_range)        { HT::Range.new(year_range_start, year_range_end)}
  root(:year_range)
end

class HT::YearList < Parslet::Parser
  include HT::Atoms

  rule(:year_range) { HT::YearRange.new }
  rule(:year_list)  { HT::List.new(list_sep, year_range).repeat(1).as(:year)}
  root(:year_list)
end

class HT::YearTransform < Parslet::Transform
  extend HT::SSDTransform
  rule(slashed: simple(:x)) { x }
  rule({single: simple(:x)}) { HT::SingleYear.new(x) }
end


class HT::SingleYear
  attr_accessor :start
  def initialize(start)
    @start = start
  end

  alias_method :year, :start
end
