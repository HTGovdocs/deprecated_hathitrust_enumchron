require 'hathitrust_enumchron/atoms'

# Build up a range-or-single based on the passed
# in rule to determine what an atom on either side of
# the range might look like (e.g., if you want digits ,
# pass in a digit)

class HT::Range < Parslet::Parser
  include HT::Atoms

  rule(:range_sep_str) { dash | slash }
  rule(:range_sep) { space? >> range_sep_str >> space? }
  rule(:strict_range) { base_start.as(:start) >> range_sep >> base_end.as(:end) }
  rule(:range)   { strict_range.as(:range) | base_start.as(:single) }
  root :range

  def initialize(base_start, base_end = nil)
    base_end ||= base_start
    super()
    self.class.rule(:base_start) { base_start }
    self.class.rule(:base_end)   { base_end }
  end
end
