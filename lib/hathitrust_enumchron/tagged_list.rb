require 'hathitrust_enumchron/atoms'

# Build a "tagged list" -- a list preceded by something
# denoting the type of thing it is (e.g., 'volume')

class HT::TaggedList < Parslet::Parser
  include HT::Atoms

  def initialize(tag_name, tag_strings, list_parser=nil)
    super()
    tag_strings.sort! {|a,b| b.length <=> a.length }
    tags = str(tag_strings.shift)
    while !tag_strings.empty?
      tags = tags | str(tag_strings.shift)
    end
    self.class.rule(:tag) { tags }

    list_type = list_parser || self.default_list
    self.class.rule(:list) { list_type }
    self.class.rule(:tagged_list) { tag >> dot? >> space? >> list.as(tag_name.to_sym) }
  end

  rule(:drange) { HT::Range.new(digits) }
  rule(:lrange) { HT::Range.new(letter) }

  rule(:dlist)  { HT::List.new(list_comma, drange).as(:digits) }
  rule(:llist)  { HT::List.new(list_comma, lrange).as(:letters) }
  rule(:default_list) { dlist | llist }



  root :tagged_list
end
