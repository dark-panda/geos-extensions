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
end
