# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class YamlTests < Minitest::Test
  include TestHelper

  # This is for 1.8 support, makes tests easier
  unless YAML.const_defined?('ENGINE')
    YAML::ENGINE = 'syck'
  end

  def test_point_wkt
    geom = Geos.read('POINT(5 7)')
    yaml = YAML.dump(geom)

    expected = <<-EOS
--- !ruby/object:Geos::Point
geom: POINT (5.0000000000000000 7.0000000000000000)
EOS

    assert_equal(expected, yaml)

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Point, new_geom)
    assert_in_delta(5, new_geom.x, DELTA_TOLERANCE)
    assert_in_delta(7, new_geom.y, DELTA_TOLERANCE)
  end

  def test_line_string
    geom = Geos.read('LINESTRING (0 0, 10 10)')
    yaml = YAML.dump(geom)

    expected = <<-EOS
--- !ruby/object:Geos::LineString
geom: LINESTRING (0.0000000000000000 0.0000000000000000, 10.0000000000000000 10.0000000000000000)
EOS
    assert_equal(expected, yaml)

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::LineString, new_geom)

    assert_equal(2, new_geom.num_points)

    point = geom.point_n(0)
    assert_equal(0, point.x)
    assert_equal(0, point.y)

    point = geom.point_n(1)
    assert_equal(10, point.x)
    assert_equal(10, point.y)
  end

  def test_polygon
    geom = Geos.read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    yaml = YAML.dump(geom)

    expected = if YAML::ENGINE == 'syck' || RUBY_ENGINE == 'jruby'
      <<-EOS
--- !ruby/object:Geos::Polygon
geom: POLYGON ((0.0000000000000000 0.0000000000000000, 5.0000000000000000 0.0000000000000000, 5.0000000000000000 5.0000000000000000, 0.0000000000000000 5.0000000000000000, 0.0000000000000000 0.0000000000000000))
EOS
  else
    <<-EOS
--- !ruby/object:Geos::Polygon
geom: POLYGON ((0.0000000000000000 0.0000000000000000, 5.0000000000000000 0.0000000000000000,
  5.0000000000000000 5.0000000000000000, 0.0000000000000000 5.0000000000000000, 0.0000000000000000
  0.0000000000000000))
EOS
    end

    assert_equal(expected, yaml)

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Polygon, new_geom)

    assert_equal(0, new_geom.num_interior_rings)
    assert_equal(5, new_geom.exterior_ring.num_points)
  end

  def test_geometry_collection
    geom = Geos.read('GEOMETRYCOLLECTION (POINT(5 7))')
    yaml = YAML.dump(geom)

    expected = <<-EOS
--- !ruby/object:Geos::GeometryCollection
geom: GEOMETRYCOLLECTION (POINT (5.0000000000000000 7.0000000000000000))
    EOS
    assert_equal(expected, yaml)

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::GeometryCollection, new_geom)
    assert_equal(1, new_geom.to_a.count)
  end

  def test_load_point_with_srid
    yaml = <<-EOS
--- !ruby/object:Geos::Point
geom: SRID=4326;POINT (5.0000000000000000 7.0000000000000000)
EOS

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Point, new_geom)
    assert_equal(4326, new_geom.srid)
    assert_equal(5, new_geom.x)
    assert_equal(7, new_geom.y)
  end

  def test_load_wkb_hex
    yaml = <<-EOS
--- !ruby/object:Geos::Point
geom: 010100000000000000000014400000000000001C40
EOS

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Point, new_geom)
    assert_equal(5, new_geom.x)
    assert_equal(7, new_geom.y)
  end

  def test_load_ewkb_hex
    yaml = <<-EOS
--- !ruby/object:Geos::Point
geom: 0101000020E610000000000000000014400000000000001C40
EOS

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Point, new_geom)
    assert_equal(4326, new_geom.srid)
    assert_equal(5, new_geom.x)
    assert_equal(7, new_geom.y)
  end

  def test_load_g_lat_lng_bounds_string
    yaml = <<-EOS
--- !ruby/object:Geos::Polygon
geom: ((0.1, 0.1), (5.2, 5.2))
EOS

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Polygon, new_geom)
    assert_equal(0.1, new_geom.sw.x)
    assert_equal(0.1, new_geom.sw.y)
  end

  def test_load_g_lat_lng_bounds_url_value
    yaml = <<-EOS
--- !ruby/object:Geos::Polygon
geom: 0.1,0.1,5.2,5.2
EOS

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Polygon, new_geom)
    assert_equal(0.1, new_geom.sw.x)
    assert_equal(0.1, new_geom.sw.y)
  end

  def test_load_g_lat_lng_string
    yaml = <<-EOS
--- !ruby/object:Geos::Point
geom: (5, 7)
EOS

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Point, new_geom)
    assert_equal(7, new_geom.x)
    assert_equal(5, new_geom.y)
  end

  def test_load_g_lat_lng_url_value
    yaml = <<-EOS
--- !ruby/object:Geos::Point
geom: "5,7"
EOS

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Point, new_geom)
    assert_equal(7, new_geom.x)
    assert_equal(5, new_geom.y)
  end

  def test_load_box2d
    yaml = <<-EOS
--- !ruby/object:Geos::Polygon
geom: BOX(0.1 0.1, 5.2 5.2)
EOS

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Polygon, new_geom)
    assert_equal(0.1, new_geom.sw.x)
    assert_equal(0.1, new_geom.sw.y)
  end
end
