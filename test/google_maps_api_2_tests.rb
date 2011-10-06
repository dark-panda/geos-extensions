
$: << File.dirname(__FILE__)
require 'test_helper'

begin
  require 'json'
rescue LoadError
  # do nothing
end

class GoogleMapsApi2Tests < Test::Unit::TestCase
  include TestHelper

  def setup
    Geos::GoogleMaps.use_api(2)

    @point = Geos.read(POINT_EWKB)
    @polygon = Geos.read(POLYGON_EWKB)
  end

  def test_to_g_lat_lng
    assert_equal("new google.maps.LatLng(10.01, 10.0)", @point.to_g_lat_lng)
    assert_equal("new GLatLng(10.01, 10.0)", @point.to_g_lat_lng(:short_class => true))
  end

  def test_to_g_lat_lng_bounds_string
    assert_equal('((10.0100000000,10.0000000000), (10.0100000000,10.0000000000))', @point.to_g_lat_lng_bounds_string)
    assert_equal('((0.0000000000,0.0000000000), (5.0000000000,5.0000000000))', @polygon.to_g_lat_lng_bounds_string)
  end

  def test_to_jsonable
    assert_equal({
      :type => "point",
      :lat => 10.01,
      :lng => 10.0
    }, @point.to_jsonable)

    assert_equal({
      :type => "polygon",
      :polylines => [{
        :points => "??_ibE_ibE_~cH_~cH_hgN_hgN~po]~po]",
        :bounds => {
          :sw => [ 0.0, 0.0 ],
          :ne => [ 5.0, 5.0 ]
        },
        :levels=>"BBBBB"
      }],
      :options => {},
      :encoded => true
    }, @polygon.to_jsonable)
  end

  if defined?(JSON)
    def test_to_g_polygon
      assert_equal(
        "new google.maps.Polygon([new google.maps.LatLng(0.0, 0.0), new google.maps.LatLng(1.0, 1.0), new google.maps.LatLng(2.5, 2.5), new google.maps.LatLng(5.0, 5.0), new google.maps.LatLng(0.0, 0.0)], null, null, null, null, null, null)",
        @polygon.to_g_polygon
      )

      assert_equal(
        "new GPolygon([new GLatLng(0.0, 0.0), new GLatLng(1.0, 1.0), new GLatLng(2.5, 2.5), new GLatLng(5.0, 5.0), new GLatLng(0.0, 0.0)], null, null, null, null, null, null)",
        @polygon.to_g_polygon({}, :short_class => true)
      )

      assert_equal(
        "new google.maps.Polygon([new google.maps.LatLng(0.0, 0.0), new google.maps.LatLng(1.0, 1.0), new google.maps.LatLng(2.5, 2.5), new google.maps.LatLng(5.0, 5.0), new google.maps.LatLng(0.0, 0.0)], '#b00b1e', 5, 0.5, '#b00b1e', null, {\"mouseOutTolerence\":5})",
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
        "new google.maps.Polyline([new google.maps.LatLng(0.0, 0.0), new google.maps.LatLng(1.0, 1.0), new google.maps.LatLng(2.5, 2.5), new google.maps.LatLng(5.0, 5.0), new google.maps.LatLng(0.0, 0.0)], null, null, null, null)",
        @polygon.to_g_polyline
      )

      assert_equal(
        "new GPolyline([new GLatLng(0.0, 0.0), new GLatLng(1.0, 1.0), new GLatLng(2.5, 2.5), new GLatLng(5.0, 5.0), new GLatLng(0.0, 0.0)], null, null, null, null)",
        @polygon.to_g_polyline({}, :short_class => true)
      )

      assert_equal(
        "new google.maps.Polyline([new google.maps.LatLng(0.0, 0.0), new google.maps.LatLng(1.0, 1.0), new google.maps.LatLng(2.5, 2.5), new google.maps.LatLng(5.0, 5.0), new google.maps.LatLng(0.0, 0.0)], '#b00b1e', 5, 0.5, {\"mouseOutTolerence\":5})",
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

      assert_in_delta(lng.to_f, 10.00, 0.000001)
      assert_in_delta(lat.to_f, 10.01, 0.000001)
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

      assert_in_delta(lng.to_f, 10.00, 0.000001)
      assert_in_delta(lat.to_f, 10.01, 0.000001)
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

      assert_in_delta(lng.to_f, 10.00, 0.000001)
      assert_in_delta(lat.to_f, 10.01, 0.000001)
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
        { :east => 5.0, :west => 0.0, :north => 5.0, :south => 0.0},
        @polygon.to_g_lat_lon_box
      )
    end
  end
end
