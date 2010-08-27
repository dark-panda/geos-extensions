
require 'test/unit'
require 'test/test_helper'
require 'geos'
require 'lib/geos_extensions'

class GeosReaderTests < Test::Unit::TestCase
	include TestHelper

	def test_from_wkb_bin
		point = Geos.from_wkb_bin(POINT_WKB_BIN)
		polygon = Geos.from_wkb_bin(POLYGON_WKB_BIN)

		assert_saneness_of_point(point)
		assert_saneness_of_polygon(polygon)
	end

	def test_from_wkb
		point = Geos.from_wkb(POINT_WKB)
		polygon = Geos.from_wkb(POLYGON_WKB)

		assert_saneness_of_point(point)
		assert_saneness_of_polygon(polygon)
	end

	def test_from_wkt
		point = Geos.from_wkt(POINT_WKT)
		polygon = Geos.from_wkt(POLYGON_WKT)

		assert_saneness_of_point(point)
		assert_saneness_of_polygon(polygon)
	end

	def test_from_ewkb_bin
		point = Geos.from_wkb_bin(POINT_EWKB_BIN)
		polygon = Geos.from_wkb_bin(POLYGON_EWKB_BIN)

		assert_saneness_of_point(point)
		assert_equal(4326, point.srid)

		assert_saneness_of_polygon(polygon)
		assert_equal(4326, polygon.srid)
	end

	def test_from_ewkb
		point = Geos.from_wkb(POINT_EWKB)
		polygon = Geos.from_wkb(POLYGON_EWKB)

		assert_saneness_of_point(point)
		assert_equal(4326, point.srid)

		assert_saneness_of_polygon(polygon)
		assert_equal(4326, polygon.srid)
	end

	def test_from_ewkt
		point = Geos.from_wkt(POINT_EWKT)
		polygon = Geos.from_wkt(POLYGON_EWKT)

		assert_saneness_of_point(point)
		assert_equal(4326, point.srid)

		assert_saneness_of_polygon(polygon)
		assert_equal(4326, polygon.srid)
	end

	def test_from_g_lat_lng
		point = Geos.from_g_lat_lng(POINT_G_LAT_LNG)
		assert_saneness_of_point(point)

		point = Geos.from_g_lat_lng(POINT_G_LAT_LNG, :points => true)
		assert_kind_of(Geos::Point, point)
		assert_equal(10, point.lat)
		assert_equal(10.01, point.lng)
	end

	def test_from_g_lat_lng_bounds
		bounds = Geos.from_g_lat_lng(BOUNDS_G_LAT_LNG)

		assert_kind_of(Geos::Polygon, bounds)
		assert_equal([ 0, 0 ], bounds.sw.to_a)
		assert_equal([ 5, 5 ], bounds.ne.to_a)
		assert_equal([ 0, 5 ], bounds.nw.to_a)
		assert_equal([ 5, 0 ], bounds.se.to_a)
	end

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
end
