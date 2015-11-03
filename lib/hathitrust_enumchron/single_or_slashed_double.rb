require 'hathitrust_enumchron/atoms'


# Create a parser that will parse either `base_start`
# or `base_start/base_end` Generally you see this for
# bianual years (1993/94) or maybe months (Jan/Feb)

class HT::SingleOrSlashedDouble < Parslet::Parser
  include HT::Atoms

  # Note that base_end defaults to be the same as base_start
  def initialize(base_start, base_end = nil)
    base_end ||= base_start
    super()
    self.class.rule(:base_start) { base_start }
    self.class.rule(:base_end)   { base_end }
  end

  rule(:slashsep) { slash }
  rule(:single) { base_start }
  rule(:double) { base_start.as(:start) >> slashsep >> base_end.as(:end)}
  rule(:ssd) { double.as(:slashed) | single.as(:single) }
  root(:ssd)
end
