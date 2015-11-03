require 'parslet'

# Some simple rules for common things we're going
# to need.
module HT
  module Atoms
    include Parslet
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
    rule(:comma) { str(',') }

    rule(:list_and) { comma | plus }
    rule(:list_comma) { space? >> list_and >> space? }
    rule(:list_sep) { list_comma }

  end
end
