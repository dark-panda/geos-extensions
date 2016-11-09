# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

begin
  require 'json'
rescue LoadError
  # do nothing
end

class GoogleMapsApi2Tests < Minitest::Test
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

  def setup
    Geos::GoogleMaps.use_api(2)
  end

  def test_to_g_lat_lng
    assert_equal("new google.maps.LatLng(10.01, 10.0)", @point.to_g_lat_lng)
    assert_equal("new GLatLng(10.01, 10.0)", @point.to_g_lat_lng(:short_class => true))
  end

  def test_to_g_lat_lng_bounds_string
    assert_equal('((10.0100000000,10.0000000000), (10.0100000000,10.0000000000))', @point.to_g_lat_lng_bounds_string)
    assert_equal('((0.0000000000,0.0000000000), (2.5000000000,5.0000000000))', @polygon.to_g_lat_lng_bounds_string)
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

  if defined?(JSON)
    def test_to_g_polygon
      assert_equal(
        "new google.maps.Polygon([new google.maps.LatLng(0.0, 0.0), new google.maps.LatLng(1.0, 0.0), new google.maps.LatLng(2.5, 2.5), new google.maps.LatLng(2.5, 5.0), new google.maps.LatLng(0.0, 0.0)], null, null, null, null, null, null)",
        @polygon.to_g_polygon
      )

      assert_equal(
        "new GPolygon([new GLatLng(0.0, 0.0), new GLatLng(1.0, 0.0), new GLatLng(2.5, 2.5), new GLatLng(2.5, 5.0), new GLatLng(0.0, 0.0)], null, null, null, null, null, null)",
        @polygon.to_g_polygon({}, :short_class => true)
      )

      assert_equal(
        "new google.maps.Polygon([new google.maps.LatLng(0.0, 0.0), new google.maps.LatLng(1.0, 0.0), new google.maps.LatLng(2.5, 2.5), new google.maps.LatLng(2.5, 5.0), new google.maps.LatLng(0.0, 0.0)], '#b00b1e', 5, 0.5, '#b00b1e', null, {\"mouseOutTolerence\":5})",
        @polygon.to_g_polygon(
          :stroke_color => '#b00b1e',
          :stroke_weight => 5,
          :stroke_opacity => 0.5,
          :fill_color => '#b00b1e',
          :polygon_options => {
            :mouse_out_tolerence => 5
          }
        )
      )
    end

    def test_to_g_polyline
      assert_equal(
        "new google.maps.Polyline([new google.maps.LatLng(0.0, 0.0), new google.maps.LatLng(1.0, 0.0), new google.maps.LatLng(2.5, 2.5), new google.maps.LatLng(2.5, 5.0), new google.maps.LatLng(0.0, 0.0)], null, null, null, null)",
        @polygon.to_g_polyline
      )

      assert_equal(
        "new GPolyline([new GLatLng(0.0, 0.0), new GLatLng(1.0, 0.0), new GLatLng(2.5, 2.5), new GLatLng(2.5, 5.0), new GLatLng(0.0, 0.0)], null, null, null, null)",
        @polygon.to_g_polyline({}, :short_class => true)
      )

      assert_equal(
        "new google.maps.Polyline([new google.maps.LatLng(0.0, 0.0), new google.maps.LatLng(1.0, 0.0), new google.maps.LatLng(2.5, 2.5), new google.maps.LatLng(2.5, 5.0), new google.maps.LatLng(0.0, 0.0)], '#b00b1e', 5, 0.5, {\"mouseOutTolerence\":5})",
        @polygon.to_g_polyline(
          :color => '#b00b1e',
          :weight => 5,
          :opacity => 0.5,
          :polyline_options => {
            :mouse_out_tolerence => 5
          }
        )
      )
    end

    def test_to_g_marker_long
      marker = @point.to_g_marker

      lat, lng, json = if marker =~ /^new\s+
        google\.maps\.Marker\(
          new\s+google\.maps\.LatLng\(
            (\d+\.\d+)\s*,\s*
            (\d+\.\d+)
          \),\s*
            ((\{\}))
        \)
        /x
        [ $1, $2, $3 ]
      end

      assert_in_delta(10.00, lng.to_f, 0.000001)
      assert_in_delta(10.01, lat.to_f, 0.000001)
      assert_equal(
        {},
        JSON.load(json)
      )
    end

    def test_to_g_marker_short_class
      marker = @point.to_g_marker({}, :short_class => true)

      lat, lng, json = if marker =~ /^new\s+
        GMarker\(
          new\s+GLatLng\(
            (\d+\.\d+)\s*,\s*
            (\d+\.\d+)
          \),\s*
            (\{\})
        \)
        /x
        [ $1, $2, $3 ]
      end

      assert_in_delta(10.00, lng.to_f, 0.000001)
      assert_in_delta(10.01, lat.to_f, 0.000001)
      assert_equal(
        {},
        JSON.load(json)
      )
    end


    def test_to_g_marker_with_options
      marker = @point.to_g_marker(
        :bounce_gravity => 1,
        :bouncy => true
      )

      lat, lng, json = if marker =~ /^new\s+
        google\.maps\.Marker\(
          new\s+google\.maps\.LatLng\(
            (\d+\.\d+)\s*,\s*
            (\d+\.\d+)
          \),\s*
            (\{[^}]+\})
        \)
        /x
        [ $1, $2, $3 ]
      end

      assert_in_delta(10.00, lng.to_f, 0.000001)
      assert_in_delta(10.01, lat.to_f, 0.000001)
      assert_equal(
        { "bounceGravity" => 1, "bouncy" => true },
        JSON.load(json)
      )
    end

    def test_to_g_json_point
      assert_equal(
        { :coordinates => [ 10.0, 10.01, 0 ] },
        @point.to_g_json_point
      )
    end

    def test_to_g_lat_lon_box
      assert_equal(
        { :east => 5.0, :west => 0.0, :north => 2.5, :south => 0.0},
        @polygon.to_g_lat_lon_box
      )
    end
  end
end
