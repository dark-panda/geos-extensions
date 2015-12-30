# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class GeometryCollectionTests < Minitest::Test
  include TestHelper

  def test_x_max
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')

    assert_equal(8, geom.x_max)
  end

  def test_x_min
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')

    assert_equal(-10, geom.x_min)
  end

  def test_y_max
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')

    assert_equal(12, geom.y_max)
  end

  def test_y_min
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')

    assert_equal(0, geom.y_min)
  end

  def test_z_max
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')
    assert_equal(0, geom.z_max)

    geom = read('GEOMETRYCOLLECTION Z (
      POLYGON Z ((0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0)),
      LINESTRING Z (0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0),
      POINT Z (3 12 6)
    )')
    assert_equal(6, geom.z_max)

    # GEOS lets you mix dimensionality, while PostGIS doesn't.
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12 10)
    )')
    assert_equal(10, geom.z_max)
  end

  def test_z_min
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')
    assert_equal(0, geom.z_min)

    geom = read('GEOMETRYCOLLECTION Z (
      POLYGON Z ((0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0)),
      LINESTRING Z (0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0),
      POINT Z (3 12 6)
    )')
    assert_equal(0, geom.z_min)

    # GEOS lets you mix dimensionality, while PostGIS doesn't.
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12 -10)
    )')
    assert_equal(-10, geom.z_min)
  end

  def test_snap_to_grid
    writer.trim = true

    wkt = 'GEOMETRYCOLLECTION (LINESTRING (-10.12 0, -10.12 5, -10.12 5, -10.12 6, -10.12 6, -10.12 6, -10.12 7, -10.12 7, -10.12 7, -10.12 8, -10.12 8, -9 8, -9 9, -10.12 0), POLYGON ((-10.12 0, -10.12 5, -10.12 5, -10.12 6, -10.12 6, -10.12 6, -10.12 7, -10.12 7, -10.12 7, -10.12 8, -10.12 8, -9 8, -9 9, -10.12 0)), POINT (10.12 10.12))'

    expected = 'GEOMETRYCOLLECTION (LINESTRING (-10 0, -10 5, -10 5, -10 6, -10 6, -10 6, -10 7, -10 7, -10 7, -10 8, -10 8, -9 8, -9 9, -10 0), POLYGON ((-10 0, -10 5, -10 5, -10 6, -10 6, -10 6, -10 7, -10 7, -10 7, -10 8, -10 8, -9 8, -9 9, -10 0)), POINT (10 10))'

    simple_bang_tester(:snap_to_grid, expected, wkt, 1)
  end

  def test_snap_to_grid_empty
    writer.trim = true

    assert(read('GEOMETRYCOLLECTION EMPTY').snap_to_grid!.empty?, " Expected an empty GeometryCollection")
  end

  def test_snap_to_grid_with_srid
    writer.trim = true

    wkt = 'GEOMETRYCOLLECTION (
      LINESTRING (-10.12 0, -10.12 5, -10.12 5, -10.12 6, -10.12 6, -10.12 6, -10.12 7, -10.12 7, -10.12 7, -10.12 8, -10.12 8, -9 8, -9 9, -10.12 0),
      POLYGON ((-10.12 0, -10.12 5, -10.12 5, -10.12 6, -10.12 6, -10.12 6, -10.12 7, -10.12 7, -10.12 7, -10.12 8, -10.12 8, -9 8, -9 9, -10.12 0)),
      POINT (10.12 10.12)
    )'

    expected = 'GEOMETRYCOLLECTION (LINESTRING (-10 0, -10 5, -10 5, -10 6, -10 6, -10 6, -10 7, -10 7, -10 7, -10 8, -10 8, -9 8, -9 9, -10 0), POLYGON ((-10 0, -10 5, -10 5, -10 6, -10 6, -10 6, -10 7, -10 7, -10 7, -10 8, -10 8, -9 8, -9 9, -10 0)), POINT (10 10))'

    srid_copy_tester(:snap_to_grid, expected, 0, :zero, wkt, 1)
    srid_copy_tester(:snap_to_grid, expected, 4326, :lenient, wkt, 1)
    srid_copy_tester(:snap_to_grid, expected, 4326, :strict, wkt, 1)
  end

  def test_snap_to_grid_with_illegal_result
    writer.trim = true

    assert_raises(Geos::InvalidGeometryError) do
      read('GEOMETRYCOLLECTION (POINT (0 2), LINESTRING (0 1, 0 11), POLYGON ((0 1, 0 1, 0 6, 0 6, 0 1)))').
        snap_to_grid(1)
    end
  end
end
