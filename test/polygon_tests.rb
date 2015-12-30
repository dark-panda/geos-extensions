# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class PolygonTests < Minitest::Test
  include TestHelper

  def test_x_max
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(8, geom.x_max)
  end

  def test_x_min
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(-10, geom.x_min)
  end

  def test_y_max
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(9, geom.y_max)
  end

  def test_y_min
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(0, geom.y_min)
  end

  def test_z_max
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(0, geom.z_min)

    geom = read('POLYGON Z ((0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0))')
    assert_equal(4, geom.z_max)
  end

  def test_z_min
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(0, geom.z_min)

    geom = read('POLYGON Z ((0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0))')
    assert_equal(0, geom.z_min)
  end
end
