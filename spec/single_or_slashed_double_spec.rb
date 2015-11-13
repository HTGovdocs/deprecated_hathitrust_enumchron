require 'minitest_helper'

require 'hathitrust_enumchron/single_or_slashed_double'
require 'hathitrust_enumchron/atoms'

include HT::Atoms

describe "single" do

  it "works with numbers" do
    p = HT::SingleOrSlashedDouble.new(digits)
    expect(p.parse('1990')).must_equal("1990")
  end

  it "works with letters" do
    p = HT::SingleOrSlashedDouble.new(letters)
    expect(p.parse('bill')).must_equal("bill")
  end

  it "fails as expected" do
    p = HT::SingleOrSlashedDouble.new(letters)
    expect(proc{p.parse('1990')}).must_raise Parslet::ParseFailed
  end

end


describe "slashed" do
  it "works with numbers" do
    p = HT::SingleOrSlashedDouble.new(digits)
    expect(p.parse('1990/1991')).must_equal({:slashed=>{:start=>"1990", :end=>"1991"}})
  end

  it "works with letters" do
    p = HT::SingleOrSlashedDouble.new(letters)
    expect(p.parse('sep/oct')).must_equal({:slashed=>{:start=>"sep", :end=>"oct"}})
  end

end

describe "slashed with different start/end" do
  it "works with numbers" do
    p = HT::SingleOrSlashedDouble.new(digits, digit.repeat(2,2))
    expect(p.parse('1990/91')).must_equal({:slashed=>{:start=>"1990", :end=>"91"}})
  end

  it "fails if end doesn't match" do
    p = HT::SingleOrSlashedDouble.new(digits, digit.repeat(2,2))
    expect(proc{p.parse('1990/1991')}).must_raise Parslet::ParseFailed
  end
end
