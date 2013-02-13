
$: << File.dirname(__FILE__)
require 'test_helper'

class GeosReaderTests < MiniTest::Unit::TestCase
  include TestHelper

  def test_from_wkb_bin
    point = Geos.from_wkb_bin(POINT_WKB_BIN)
    polygon = Geos.from_wkb_bin(POLYGON_WKB_BIN)

    assert_saneness_of_point(point)
    assert_saneness_of_polygon(polygon)
  end

  def test_from_wkb_bin_with_srid_option
    point = Geos.from_wkb_bin(POINT_EWKB_BIN, :srid => 900913)
    polygon = Geos.from_wkb_bin(POLYGON_EWKB_BIN, :srid => 900913)

    assert_saneness_of_point(point)
    assert_saneness_of_polygon(polygon)

    assert_equal(900913, point.srid)
    assert_equal(900913, polygon.srid)
  end

  def test_from_wkb
    point = Geos.from_wkb(POINT_WKB)
    polygon = Geos.from_wkb(POLYGON_WKB)

    assert_saneness_of_point(point)
    assert_saneness_of_polygon(polygon)
  end

  def test_from_wkb_with_srid_option
    point = Geos.from_wkb(POINT_EWKB, :srid => 900913)
    polygon = Geos.from_wkb(POLYGON_EWKB, :srid => 900913)

    assert_saneness_of_point(point)
    assert_saneness_of_polygon(polygon)

    assert_equal(900913, point.srid)
    assert_equal(900913, polygon.srid)
  end

  def test_from_wkt
    point = Geos.from_wkt(POINT_WKT)
    polygon = Geos.from_wkt(POLYGON_WKT)

    assert_saneness_of_point(point)
    assert_saneness_of_polygon(polygon)
  end

  def test_from_wkt_with_srid_option
    point = Geos.from_wkt(POINT_EWKT, :srid => 900913)
    polygon = Geos.from_wkt(POLYGON_EWKT, :srid => 900913)

    assert_saneness_of_point(point)
    assert_saneness_of_polygon(polygon)

    assert_equal(900913, point.srid)
    assert_equal(900913, polygon.srid)
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
    assert_equal([ 0.1, 0.1 ], bounds.sw.to_a)
    assert_equal([ 5.2, 5.2 ], bounds.ne.to_a)
    assert_equal([ 0.1, 5.2 ], bounds.nw.to_a)
    assert_equal([ 5.2, 0.1 ], bounds.se.to_a)
  end

  def test_from_g_lat_lng_bounds_url_value
    bounds = Geos.from_g_lat_lng(BOUNDS_G_LAT_LNG_URL_VALUE)

    assert_kind_of(Geos::Polygon, bounds)
    assert_equal([ 0.1, 0.1 ], bounds.sw.to_a)
    assert_equal([ 5.2, 5.2 ], bounds.ne.to_a)
    assert_equal([ 0.1, 5.2 ], bounds.nw.to_a)
    assert_equal([ 5.2, 0.1 ], bounds.se.to_a)
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

  def test_read_wkt_with_newlines
    geom = Geos.read(<<-EOF)
    POLYGON((
      0 0,
      10 10,
      0 10,
      0 0
    ))
    EOF

    assert_equal('POLYGON ((0 0, 10 10, 0 10, 0 0))', geom.to_wkt(:trim => true))
  end

  def test_read_e_notation
    assert_equal('POINT (60081.5 -0.000858307)', Geos.read('-8.58307e-04, 6.00815E+4').to_wkt(:trim => true))
    assert_equal('POINT (60081.5 -0.000858307)', Geos.read('-8.58307e-04, 6.00815e4').to_wkt(:trim => true))
  end

  def test_no_leading_digits
    assert_equal('POINT (0.01 0.02)', Geos.read('.02, .01').to_wkt(:trim => true))
  end

  def test_from_box2d
    assert_equal('POLYGON ((10 54, 123 54, 123 79, 10 79, 10 54))',
      Geos.read('BOX(123.456 78.9, 9.876 54.321)').to_wkt(:rounding_precision => 0))

    assert_equal('POINT (0 0)', Geos.read('BOX(0 0, 0 0)').to_wkt(:trim => true))
  end

  def test_allowed
    assert_raises(ArgumentError) do
      Geos.read(Geos.read(POINT_WKT), :allowed => [])
    end

    assert_equal(
      'POINT (10 10.01)',
      Geos.read(POINT_WKT, :allowed => :wkt).to_wkt(:trim => true)
    )
  end

  def test_allowed_array
    assert_equal(
      'POINT (10 10.01)',
      Geos.read(POINT_WKT, :allowed => [ :wkt ]).to_wkt(:trim => true)
    )
  end

  def test_excluded
    assert_raises(ArgumentError) do
      Geos.read(POINT_WKT, :excluded => :wkt)
    end
  end

  def test_excluded_array
    assert_raises(ArgumentError) do
      Geos.read(POINT_WKT, :excluded => [ :wkt ])
    end
  end

  def test_allowed_and_excluded
    assert_raises(ArgumentError) do
      Geos.read(POINT_WKT, :allowed => :wkt, :excluded => :wkt)
    end
  end
end

