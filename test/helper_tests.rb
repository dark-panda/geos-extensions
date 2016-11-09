# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class HelperTests
  class ArrayWrapTests < Minitest::Test
    include TestHelper

    def test_array
      ary = %w(foo bar)
      assert_same ary, Geos::Helper.array_wrap(ary)
    end

    def test_nil
      assert_equal [], Geos::Helper.array_wrap(nil)
    end

    def test_object
      o = Object.new
      assert_equal [ o ], Geos::Helper.array_wrap(o)
    end

    def test_string
      assert_equal [ "foo" ], Geos::Helper.array_wrap("foo")
    end
  end
end

