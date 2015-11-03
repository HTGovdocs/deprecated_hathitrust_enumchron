require 'hathitrust_enumchron/atoms'

# Build up a parser that parses a list of
# `list_component`'s separated by `list_sep`
# (both of which are valid Parslet parsers)

class HT::List < Parslet::Parser
  include HT::Atoms

  def initialize(list_sep, list_component)
    super()
    self.class.rule(:list_sep) { list_sep }
    self.class.rule(:list_component) { list_component }
  end

  rule(:list)  {  list_component >> (list_sep >> list_component).repeat}
  root :list
end
