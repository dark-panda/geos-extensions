
$: << File.dirname(__FILE__)
require 'test_helper'

if ENV['TEST_ACTIVERECORD']
  class AdapterTests < ActiveRecord::TestCase
    include TestHelper
    include ActiveRecord::TestFixtures

    def test_simplified_type
      geometry_columns = Foo.columns.select do |c|
        c.type == :geometry
      end

      other_columns = Foo.columns.select do |c|
        c.type != :geometry
      end

      assert_equal(2, geometry_columns.length)
      assert_equal(2, other_columns.length)
    end
  end
end