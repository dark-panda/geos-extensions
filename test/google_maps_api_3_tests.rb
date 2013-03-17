
$: << File.dirname(__FILE__)
require 'test_helper'

begin
  require 'json'
rescue LoadError
  # do nothing
end

class GoogleMapsApi3Tests < MiniTest::Unit::TestCase
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
    Geos::GoogleMaps.use_api(3)
  end

  def test_to_g_lat_lng
    assert_equal("new google.maps.LatLng(10.01, 10.0)", @point.to_g_lat_lng)
    assert_equal("new google.maps.LatLng(10.01, 10.0, true)", @point.to_g_lat_lng(:no_wrap => true))
  end

  def test_to_g_lat_lng_bounds_string
    assert_equal('((10.0100000000,10.0000000000), (10.0100000000,10.0000000000))', @point.to_g_lat_lng_bounds_string)
    assert_equal('((0.0000000000,0.0000000000), (5.0000000000,5.0000000000))', @polygon.to_g_lat_lng_bounds_string)
  end

  def test_to_g_geocoder_bounds
    assert_equal('10.010000,10.000000|10.010000,10.000000', @point.to_g_geocoder_bounds)
    assert_equal('0.000000,0.000000|5.000000,5.000000', @polygon.to_g_geocoder_bounds)
  end

  def test_to_g_url_value_point
    assert_equal('10.010000,10.000000', @point.to_g_url_value)
    assert_equal('10.010,10.000', @point.to_g_url_value(3))
  end

  def test_to_g_url_value_polygon
    assert_equal('0.000000,0.000000,5.000000,5.000000', @polygon.to_g_url_value)
    assert_equal('0.000,0.000,5.000,5.000', @polygon.to_g_url_value(3))
  end

  def test_to_g_url_value_line_string
    assert_equal('0.000000,0.000000,10.000000,10.000000', @linestring.to_g_url_value)
    assert_equal('0.000,0.000,10.000,10.000', @linestring.to_g_url_value(3))
  end

  def test_to_g_url_value_multi_point
    assert_equal('0.000000,0.000000,10.000000,10.000000', @multipoint.to_g_url_value)
    assert_equal('0.000,0.000,10.000,10.000', @multipoint.to_g_url_value(3))
  end

  def test_to_g_url_value_multi_polygon
    assert_equal('0.000000,0.000000,15.000000,15.000000', @multipolygon.to_g_url_value)
    assert_equal('0.000,0.000,15.000,15.000', @multipolygon.to_g_url_value(3))
  end

  def test_to_g_url_value_multi_line_string
    assert_equal('-20.000000,-20.000000,30.000000,30.000000', @multilinestring.to_g_url_value)
    assert_equal('-20.000,-20.000,30.000,30.000', @multilinestring.to_g_url_value(3))
  end

  def test_to_g_url_value_geometry_collection
    assert_equal('0.000000,0.000000,14.000000,14.000000', @geometrycollection.to_g_url_value)
    assert_equal('0.000,0.000,14.000,14.000', @geometrycollection.to_g_url_value(3))
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
    def poly_tester(type, expected, poly)
      json = poly.gsub(/new google.maps.LatLng\(([^)]+)\)/, '[ \1 ]').gsub(/"map":\s*map/, %{"map": "map"})

      assert(json =~ /^new google.maps.#{type}\((.+)\)$/)

      assert_equal(expected, JSON.load($~[1]))
    end

    def test_to_g_polygon
      poly_tester('Polygon', {
        "paths" => [
          [0.0, 0.0], [1.0, 1.0], [2.5, 2.5], [5.0, 5.0], [0.0, 0.0]
        ]
      }, @polygon.to_g_polygon)

      poly_tester('Polygon', {
        'strokeColor' => '#b00b1e',
        'strokeWeight' => 5,
        'strokeOpacity' => 0.5,
        'fillColor' => '#b00b1e',
        'map' => 'map',
        'paths' => [
          [ 0.0, 0.0 ],
          [ 1.0, 1.0 ],
          [ 2.5, 2.5 ],
          [ 5.0, 5.0 ],
          [ 0.0, 0.0 ]
        ]
      }, @polygon.to_g_polygon(
        :stroke_color => '#b00b1e',
        :stroke_weight => 5,
        :stroke_opacity => 0.5,
        :fill_color => '#b00b1e',
        :map => 'map'
      ))
    end

    def test_to_g_polygon_with_multi_polygon
      multi_polygon = Geos.read(
        'MULTIPOLYGON(
          ((0 0, 0 5, 5 5, 5 0, 0 0)),
          ((10 10, 10 15, 15 15, 15 10, 10 10)),
          ((20 20, 20 25, 25 25, 25 20, 20 20))
        )'
      )

      options = {
        :stroke_color => '#b00b1e',
        :stroke_weight => 5,
        :stroke_opacity => 0.5,
        :fill_color => '#b00b1e',
        :map => 'map'
      }

      expected = [ {
        "paths" => [[0.0, 0.0], [5.0, 0.0], [5.0, 5.0], [0.0, 5.0], [0.0, 0.0]],
        "strokeColor" => "#b00b1e",
        "strokeOpacity" => 0.5,
        "fillColor" => "#b00b1e",
        "strokeWeight" => 5,
        "map" => "map"
      }, {
        "paths" =>  [[10.0, 10.0], [15.0, 10.0], [15.0, 15.0], [10.0, 15.0], [10.0, 10.0]],
        "strokeColor" => "#b00b1e",
        "strokeOpacity" => 0.5,
        "fillColor" => "#b00b1e",
        "strokeWeight" => 5,
        "map" => "map"
      }, {
        "paths" => [[20.0, 20.0], [25.0, 20.0], [25.0, 25.0], [20.0, 25.0], [20.0, 20.0]],
        "strokeColor" => "#b00b1e",
        "strokeOpacity" => 0.5,
        "fillColor" => "#b00b1e",
        "strokeWeight" => 5,
        "map" => "map"
      } ]

      multi_polygon.to_g_polygon(options).each_with_index do |polygon, i|
        poly_tester('Polygon', expected[i], polygon)
      end

      poly_tester("Polygon", {
        "paths" => [
          [[0.0, 0.0], [5.0, 0.0], [5.0, 5.0], [0.0, 5.0], [0.0, 0.0]],
          [[10.0, 10.0], [15.0, 10.0], [15.0, 15.0], [10.0, 15.0], [10.0, 10.0]],
          [[20.0, 20.0], [25.0, 20.0], [25.0, 25.0], [20.0, 25.0], [20.0, 20.0]]
        ],
        "strokeColor" => "#b00b1e",
        "strokeOpacity" => 0.5,
        "fillColor" => "#b00b1e",
        "strokeWeight" => 5,
        "map" => "map"
      }, multi_polygon.to_g_polygon(options, {
        :single => true
      }))

      poly_tester("Polygon", {
        "paths" => [
          [[0.0, 0.0], [5.0, 0.0], [5.0, 5.0], [0.0, 5.0], [0.0, 0.0]],
          [[10.0, 10.0], [15.0, 10.0], [15.0, 15.0], [10.0, 15.0], [10.0, 10.0]],
          [[20.0, 20.0], [25.0, 20.0], [25.0, 25.0], [20.0, 25.0], [20.0, 20.0]]
        ],
        "strokeColor" => "#b00b1e",
        "strokeOpacity" => 0.5,
        "fillColor" => "#b00b1e",
        "strokeWeight" => 5,
        "map" => "map"
      }, multi_polygon.to_g_polygon_single(options))
    end

    def test_to_g_polyline
      poly_tester("Polyline", {
        "path" => [
          [0.0, 0.0], [1.0, 1.0], [2.5, 2.5], [5.0, 5.0], [0.0, 0.0]
        ]
      }, @polygon.to_g_polyline)

      poly_tester("Polyline", {
        "strokeColor" => "#b00b1e",
        "strokeWeight" => 5,
        "strokeOpacity" => 0.5,
        "map" => "map",
        "path" => [
          [0.0, 0.0], [1.0, 1.0], [2.5, 2.5], [5.0, 5.0], [0.0, 0.0]
        ]
      }, @polygon.to_g_polyline(
        :stroke_color => '#b00b1e',
        :stroke_weight => 5,
        :stroke_opacity => 0.5,
        :map => 'map'
      ))
    end

    def test_to_g_marker
      marker = @point.to_g_marker

      lat, lng = if marker =~ /^new\s+
        google\.maps\.Marker\(\{
          "position":\s*
          new\s+google\.maps\.LatLng\(
            (\d+\.\d+),\s*
            (\d+\.\d+)
          \)
        \}\)
        /x
        [ $1, $2 ]
      end

      assert_in_delta(10.00, lng.to_f, 0.000001)
      assert_in_delta(10.01, lat.to_f, 0.000001)
    end


    def test_to_g_marker_with_options
      marker = @point.to_g_marker({
        :raise_on_drag => true,
        :cursor => 'test'
      }, {
        :escape => %w{ position }
      })

      json = if marker =~ /^new\s+
        google\.maps\.Marker\((
          \{[^}]+\}
        )/x
        $1
      end

      assert_equal(
        { "raiseOnDrag" => true, "cursor" => 'test' },
        JSON.load(json).reject { |k, v|
          %w{ position }.include?(k)
        }
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
