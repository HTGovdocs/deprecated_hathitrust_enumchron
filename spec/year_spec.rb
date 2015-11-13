require 'minitest_helper'

require 'hathitrust_enumchron/year'
require 'hathitrust_enumchron/atoms'

include HT::Atoms

describe "singles" do
  p = HT::YearList.new

  it "parses a single year" do
    value(p.parse("1988")).must_equal({year: [{single: "1988"}]})
  end

  it "parses a slashed year" do
    value(p.parse("1988/1989")).must_equal(
      {year: [{single: {slashed: {start: "1988", end: "1989"}}}]})
  end
end
