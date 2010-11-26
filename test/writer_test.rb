
require 'test/unit'
require 'test/test_helper'
require 'geos'
require 'lib/geos_extensions'

begin
	require 'rubygems'
	require 'json'
rescue LoadError
	# do nothing
end

begin
	require 'rubygems'
	require 'builder'
	require 'stringio'
rescue LoadError
	# do nothing
end

class GeosWriterTests < Test::Unit::TestCase
	include TestHelper

	def initialize(*args)
		@point = Geos.read(POINT_EWKB)
		@polygon = Geos.read(POLYGON_EWKB)
		super(*args)
	end

	def test_to_wkb_bin
		assert_equal(POINT_WKB_BIN, @point.to_wkb_bin)
		assert_equal(POLYGON_WKB_BIN, @polygon.to_wkb_bin)
	end

	def test_to_wkb
		assert_equal(POINT_WKB, @point.to_wkb)
		assert_equal(POLYGON_WKB, @polygon.to_wkb)
	end

	#def test_to_wkt
		#assert_equal(POINT_WKT, @point.to_wkt)
		#assert_equal(POLYGON_WKT, @polygon.to_wkt)
	#end

	def test_to_ewkb_bin
		assert_equal(POINT_EWKB_BIN, @point.to_ewkb_bin)
		assert_equal(POLYGON_EWKB_BIN, @polygon.to_ewkb_bin)
	end

	def test_to_ewkb
		assert_equal(POINT_EWKB, @point.to_ewkb)
		assert_equal(POLYGON_EWKB, @polygon.to_ewkb)
	end

	#def test_to_ewkt
		#assert_equal(POINT_EWKT, @point.to_ewkt)
		#assert_equal(POLYGON_EWKT, @polygon.to_ewkt)
	#end

	def test_to_g_lat_lng
		assert_equal("new google.maps.LatLng(10.01, 10.0)", @point.to_g_lat_lng)
		assert_equal("new GLatLng(10.01, 10.0)", @point.to_g_lat_lng(:short_class => true))
	end

	def test_to_flickr_bbox
		assert_equal('0.0,0.0,5.0,5.0', @polygon.to_flickr_bbox)
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

		def test_to_g_marker
			assert_equal(
				"new google.maps.Marker(new google.maps.LatLng(10.01, 10.0), {})",
				@point.to_g_marker
			)

			assert_equal(
				"new GMarker(new GLatLng(10.01, 10.0), {})",
				@point.to_g_marker({}, :short_class => true)
			)

			assert_equal(
				"new google.maps.Marker(new google.maps.LatLng(10.01, 10.0), {\"bouncy\":true,\"bounceGravity\":1})",
				@point.to_g_marker(
					:bounce_gravity => 1,
					:bouncy => true
				)
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

	if defined?(Builder::XmlMarkup)
		def test_to_kml_point
			out = StringIO.new
			xml = Builder::XmlMarkup.new(:target => out)
			@point.to_kml(xml, {
				:extrude => true,
				:altitude_mode => :relative_to_ground
			})
			out.rewind

			assert_equal("<Point id=\"\"><extrude>true</extrude><altitudeMode>relativeToGround</altitudeMode><coordinates>10.0,10.01</coordinates></Point>", out.read)
		end

		def test_to_kml_polygon
			out = StringIO.new
			xml = Builder::XmlMarkup.new(:target => out)
			@polygon.to_kml(xml, {
				:extrude => true,
				:altitude_mode => :relative_to_ground
			})
			out.rewind

			assert_equal("<Polygon id=\"\"><extrude>true</extrude><altitudeMode>relativeToGround</altitudeMode><outerBoundaryIs><LinearRing><coordinates>0.0,0.0 1.0,1.0 2.5,2.5 5.0,5.0 0.0,0.0</coordinates></LinearRing></outerBoundaryIs></Polygon>",
				out.read
			)
		end

		def test_to_kml_polygon_with_interior_ring
			out = StringIO.new
			polygon = Geos.read(POLYGON_WITH_INTERIOR_RING)
			xml = Builder::XmlMarkup.new(:target => out)
			polygon.to_kml(xml, :interior_rings => true)
			out.rewind

			assert_equal(
				"<Polygon id=\"\"><outerBoundaryIs><LinearRing><coordinates>0.0,0.0 5.0,0.0 5.0,5.0 0.0,5.0 0.0,0.0</coordinates></LinearRing></outerBoundaryIs><innerBoundaryIs><LinearRing><coordinates>4.0,4.0 4.0,1.0 1.0,1.0 1.0,4.0 4.0,4.0</coordinates></LinearRing></innerBoundaryIs></Polygon>",
				out.read
			)
		end

		def test_to_georss
		end
	end
=begin
	def test_read
		[
			POINT_WKT,
			POINT_EWKT,
			POINT_WKB,
			POINT_WKB_BIN,
			POINT_EWKB,
			POINT_EWKB_BIN,
			POINT_G_LAT_LNG,
			POINT_G_LAT_LNG_URL_VALUE
		].each do |geom|
			point = Geos.read(geom)
			assert_saneness_of_point(point)
		end

		[
			POLYGON_WKT,
			POLYGON_EWKT,
			POLYGON_WKB,
			POLYGON_WKB_BIN,
			POLYGON_EWKB,
			POLYGON_EWKB_BIN
		].each do |geom|
			polygon = Geos.read(geom)
			assert_saneness_of_polygon(polygon)
		end
	end
=end
end