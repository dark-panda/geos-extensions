# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class PointTests < Minitest::Test
  include TestHelper

  def test_x_max
    geom = read('POINT (-10 -15)')
    assert_equal(-10, geom.x_max)
  end

  def test_x_min
    geom = read('POINT (-10 -15)')
    assert_equal(-10, geom.x_min)
  end

  def test_y_max
    geom = read('POINT (-10 -15)')
    assert_equal(-15, geom.y_max)
  end

  def test_y_min
    geom = read('POINT (-10 -15)')
    assert_equal(-15, geom.y_min)
  end

  def test_z_max
    geom = read('POINT (-10 -15)')
    assert_equal(0, geom.z_max)

    geom = read('POINT Z (-10 -15 -20)')
    assert_equal(-20, geom.z_max)
  end

  def test_z_min
    geom = read('POINT (-10 -15)')
    assert_equal(0, geom.z_min)

    geom = read('POINT Z (-10 -15 -20)')
    assert_equal(-20, geom.z_min)
  end
end
