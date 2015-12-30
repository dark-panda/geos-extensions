# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class LineStringTests < Minitest::Test
  include TestHelper

  def test_x_max
    geom = read('LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0)')
    assert_equal(8, geom.x_max)
  end

  def test_x_min
    geom = read('LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0)')
    assert_equal(-10, geom.x_min)
  end

  def test_y_max
    geom = read('LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0)')
    assert_equal(9, geom.y_max)
  end

  def test_y_min
    geom = read('LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0)')
    assert_equal(0, geom.y_min)
  end

  def test_z_max
    geom = read('LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0)')
    assert_equal(0, geom.z_max)

    geom = read('LINESTRING Z (0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0)')
    assert_equal(4, geom.z_max)
  end

  def test_z_min
    geom = read('LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0)')
    assert_equal(0, geom.z_min)

    geom = read('LINESTRING Z (0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0)')
    assert_equal(0, geom.z_min)
  end

  def test_snap_to_grid
    writer.trim = true

    wkt = 'LINESTRING (-10.12 0, -10.12 5, -10.12 5, -10.12 6, -10.12 6, -10.12 6, -10.12 7, -10.12 7, -10.12 7, -10.12 8, -10.12 8, -9 8, -9 9, -10.12 0)'
    expected = 'LINESTRING (-10 0, -10 5, -10 6, -10 7, -10 8, -9 8, -9 9, -10 0)'

    simple_bang_tester(:snap_to_grid, expected, wkt, 1)
  end

  def test_snap_to_grid_empty
    writer.trim = true

    assert(read('LINESTRING EMPTY').snap_to_grid!.empty?, " Expected an empty LineString")
  end

  def test_snap_to_grid_with_srid
    writer.trim = true

    wkt = 'LINESTRING (0.1 0.1, 0.1 5.1, 5.1 5.1, 5.1 0.1, 0.1 0.1)'
    expected = 'LINESTRING (0 0, 0 5, 5 5, 5 0, 0 0)'

    srid_copy_tester(:snap_to_grid, expected, 0, :zero, wkt, 1)
    srid_copy_tester(:snap_to_grid, expected, 4326, :lenient, wkt, 1)
    srid_copy_tester(:snap_to_grid, expected, 4326, :strict, wkt, 1)
  end
end
