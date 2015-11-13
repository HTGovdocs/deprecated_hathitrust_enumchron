module HT; end

require 'hathitrust_enumchron/atoms'
require 'hathitrust_enumchron/list'
require 'hathitrust_enumchron/tagged_list'
require 'hathitrust_enumchron/range'
require 'hathitrust_enumchron/year'




class V < Parslet::Parser
  include HT::Atoms
  rule(:volume) { HT::TaggedList.new(:volume, %w[volumes volume vols vol v v])}
  rule(:number) { HT::TaggedList.new(:number, %w[numbers number nums num nos no ns n numbs numb])}
  rule(:part)   { HT::TaggedList.new(:part, %w[parts part pts pt ps p])}
  rule(:report) { HT::TaggedList.new(:report, %w[reports report repts rept rpts rpt r])}
  rule(:serial) { HT::TaggedList.new(:serial, %w[serials serial sers ser s])}

  # iyear is a year without any tag
  # tyear is a rare "tagged" year (e.g., 'y. 1990')
  rule(:iyear)  { HT::Year.new.iyear.as(:iyear) }
  rule(:tyear)  { HT::Year.new.tyear }

  # A bare number range, not tagged at all, but doesn't work (in the obvious
  # ways) as an iyear.

  rule(:bare_num_range) { HT::List.new(list_comma, HT::Range.new(digits)).as(:bare_num)}

  # Any component
  rule(:comp) {
    volume | tyear | number | part | tyear |
    report | serial |
    iyear | bare_num_range
   }

  # What's the delimited we're using between components?
  rule(:ec_delim) { space? >> (str(',')|str(':')) >> space? | space }

  # Set of components
  rule(:ecs) { (comp >> (ec_delim >> comp).repeat(0)).repeat(0).as(:ec) }

  # ROOT!
  root(:ecs)

end
