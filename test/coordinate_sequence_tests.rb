# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class CoordinateSequenceTests < Minitest::Test
  include TestHelper

  def test_x_max
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert_equal(10, cs.x_max)
  end

  def test_x_min
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert_equal(-10, cs.x_min)
  end

  def test_y_max
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert_equal(20, cs.y_max)
  end

  def test_y_min
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert_equal(-15, cs.y_min)
  end

  def test_z_max
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert(cs.z_max.nan?, " Expected NaN")

    cs = Geos::CoordinateSequence.new([ -10, -15, -20 ], [ 0, 5, 10 ], [ 10, 20, 30 ])
    assert_equal(30, cs.z_max)
  end

  def test_z_min
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert(cs.z_min.nan?, " Expected NaN")

    cs = Geos::CoordinateSequence.new([ -10, -15, -20 ], [ 0, 5, 10 ], [ 10, 20, 30 ])
    assert_equal(-20, cs.z_min)
  end
end
