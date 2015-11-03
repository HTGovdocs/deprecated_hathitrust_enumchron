$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'hathitrust_enumchron'


def spec_data(relative_path)
  return File.expand_path(File.join("data", relative_path), File.dirname(__FILE__))
end

require 'minitest/spec'
require 'minitest/autorun'
