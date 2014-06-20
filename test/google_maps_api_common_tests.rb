
$: << File.dirname(__FILE__)
require 'test_helper'

begin
  require 'json'
rescue LoadError
  # do nothing
end

class GoogleMapsApiCommonTests
  module Tests
    include TestHelper

    def initialize(*args)
      @point = Geos.read(POINT_WKT)
      @polygon = Geos.read(POLYGON_WKT)
      @linestring = Geos.read(LINESTRING_WKT)
      @multipoint = Geos.read(MULTIPOINT_WKT)
      @multipolygon = Geos.read(MULTIPOLYGON_WKT)
      @multilinestring = Geos.read(MULTILINESTRING_WKT)
      @geometrycollection = Geos.read(GEOMETRYCOLLECTION_WKT)

      super
    end

    def test_to_g_url_value_point
      assert_equal('10.010000,10.000000', @point.to_g_url_value)
      assert_equal('10.010,10.000', @point.to_g_url_value(3))
    end

    def test_to_g_url_value_point_bounds
      assert_equal('10.010000,10.000000,10.010000,10.000000', @point.to_g_url_value_bounds)
      assert_equal('10.010,10.000,10.010,10.000', @point.to_g_url_value_bounds(3))
    end

    def test_to_g_url_value_point_point
      assert_equal('10.010000,10.000000', @point.to_g_url_value_point)
      assert_equal('10.010,10.000', @point.to_g_url_value_point(3))
    end

    def test_to_g_url_value_polygon
      assert_equal('0.000000,0.000000,2.500000,5.000000', @polygon.to_g_url_value)
      assert_equal('0.000,0.000,2.500,5.000', @polygon.to_g_url_value(3))
    end

    def test_to_g_url_value_polygon_bounds
      assert_equal('0.000000,0.000000,2.500000,5.000000', @polygon.to_g_url_value_bounds)
      assert_equal('0.000,0.000,2.500,5.000', @polygon.to_g_url_value_bounds(3))
    end

    def test_to_g_url_value_polygon_point
      assert_equal('1.523810,2.023810', @polygon.to_g_url_value_point)
      assert_equal('1.524,2.024', @polygon.to_g_url_value_point(3))
    end

    def test_to_g_url_value_line_string
      assert_equal('0.000000,0.000000,10.000000,10.000000', @linestring.to_g_url_value)
      assert_equal('0.000,0.000,10.000,10.000', @linestring.to_g_url_value(3))
    end

    def test_to_g_url_value_line_string_bounds
      assert_equal('0.000000,0.000000,10.000000,10.000000', @linestring.to_g_url_value_bounds)
      assert_equal('0.000,0.000,10.000,10.000', @linestring.to_g_url_value_bounds(3))
    end

    def test_to_g_url_value_line_string_point
      assert_equal('0.000000,0.000000,10.000000,10.000000', @linestring.to_g_url_value_point)
      assert_equal('0.000,0.000,10.000,10.000', @linestring.to_g_url_value_point(3))
    end

    def test_to_g_url_value_multi_point
      assert_equal('0.000000,0.000000,10.000000,10.000000', @multipoint.to_g_url_value)
      assert_equal('0.000,0.000,10.000,10.000', @multipoint.to_g_url_value(3))
    end

    def test_to_g_url_value_line_string_bounds
      assert_equal('0.000000,0.000000,10.000000,10.000000', @multipoint.to_g_url_value_bounds)
      assert_equal('0.000,0.000,10.000,10.000', @multipoint.to_g_url_value_bounds(3))
    end

    def test_to_g_url_value_line_string_point
      assert_equal('5.000000,5.000000', @multipoint.to_g_url_value_point)
      assert_equal('5.000,5.000', @multipoint.to_g_url_value_point(3))
    end

    def test_to_g_url_value_multi_polygon
      assert_equal('0.000000,0.000000,15.000000,15.000000', @multipolygon.to_g_url_value)
      assert_equal('0.000,0.000,15.000,15.000', @multipolygon.to_g_url_value(3))
    end

    def test_to_g_url_value_multi_polygon_bounds
      assert_equal('0.000000,0.000000,15.000000,15.000000', @multipolygon.to_g_url_value_bounds)
      assert_equal('0.000,0.000,15.000,15.000', @multipolygon.to_g_url_value_bounds(3))
    end

    def test_to_g_url_value_multi_polygon_point
      assert_equal('7.500000,7.500000', @multipolygon.to_g_url_value_point)
      assert_equal('7.500,7.500', @multipolygon.to_g_url_value_point(3))
    end

    def test_to_g_url_value_multi_line_string
      assert_equal('-20.000000,-20.000000,30.000000,30.000000', @multilinestring.to_g_url_value)
      assert_equal('-20.000,-20.000,30.000,30.000', @multilinestring.to_g_url_value(3))
    end

    def test_to_g_url_value_multi_line_string_bounds
      assert_equal('-20.000000,-20.000000,30.000000,30.000000', @multilinestring.to_g_url_value_bounds)
      assert_equal('-20.000,-20.000,30.000,30.000', @multilinestring.to_g_url_value_bounds(3))
    end

    def test_to_g_url_value_multi_line_string_point
      assert_equal('5.000000,5.000000', @multilinestring.to_g_url_value_point)
      assert_equal('5.000,5.000', @multilinestring.to_g_url_value_point(3))
    end

    def test_to_g_url_value_geometry_collection
      assert_equal('0.000000,0.000000,14.000000,14.000000', @geometrycollection.to_g_url_value)
      assert_equal('0.000,0.000,14.000,14.000', @geometrycollection.to_g_url_value(3))
    end

    def test_to_g_url_value_geometry_collection_bounds
      assert_equal('0.000000,0.000000,14.000000,14.000000', @geometrycollection.to_g_url_value_bounds)
      assert_equal('0.000,0.000,14.000,14.000', @geometrycollection.to_g_url_value_bounds(3))
    end

    def test_to_g_url_value_geometry_collection_point
      assert_equal('6.712121,6.712121', @geometrycollection.to_g_url_value_point)
      assert_equal('6.712,6.712', @geometrycollection.to_g_url_value_point(3))
    end
  end

  class Api2Tests < Minitest::Test
    include Tests

    def setup
      Geos::GoogleMaps.use_api(2)
    end
  end

  class Api3Tests < Minitest::Test
    include Tests

    def setup
      Geos::GoogleMaps.use_api(3)
    end
  end
end
