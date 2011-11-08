
$: << File.dirname(__FILE__)
require 'test_helper'

begin
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

  def test_to_wkt
    if @point.to_wkt =~ /^POINT\s*\((\d+\.\d+)\s*(\d+\.\d+)\)$/
      lng, lat = $1.to_f, $2.to_f
    end

    assert_in_delta(10.00, lng, 0.000001)
    assert_in_delta(10.01, lat, 0.000001)
  end

  def test_to_ewkb_bin
    assert_equal(POINT_EWKB_BIN, @point.to_ewkb_bin)
    assert_equal(POLYGON_EWKB_BIN, @polygon.to_ewkb_bin)
  end

  def test_to_ewkb
    assert_equal(POINT_EWKB, @point.to_ewkb)
    assert_equal(POLYGON_EWKB, @polygon.to_ewkb)
  end

  def test_to_ewkt
    if @point.to_ewkt =~ /^SRID=4326;\s*POINT\s*\((\d+\.\d+)\s*(\d+\.\d+)\)$/
      lng, lat = $1.to_f, $2.to_f
    end

    assert_in_delta(10.00, lng, 0.000001)
    assert_in_delta(10.01, lat, 0.000001)
  end

  def test_to_flickr_bbox
    assert_equal('0.0,0.0,5.0,5.0', @polygon.to_flickr_bbox)
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
      out = StringIO.new
      polygon = Geos.read(POLYGON_WITH_INTERIOR_RING)
      xml = Builder::XmlMarkup.new(:target => out)
      polygon.to_georss(xml)
      out.rewind

      assert_equal(
        "<georss:where><gml:Polygon><gml:exterior><gml:LinearRing><gml:posList>0.0 0.0 0.0 5.0 5.0 5.0 5.0 0.0 0.0 0.0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></georss:where>",
        out.read
      )
    end

    def test_to_wkt_handles_binary_geos_arity
      if @point.to_wkt(:rounding_precision => 0) =~ /^POINT\s*\((\d+(\.\d+)?)\s*(\d+(\.\d+)?)\)$/
        lng, lat = $1.to_f, $3.to_f
      end

      if defined?(Geos::FFIGeos)
        assert_equal(lng, 10.0, 0.000001)
        assert_equal(lat, 10.0, 0.000001)
      else
        assert_equal(lng, 10.00, 0.000001)
        assert_equal(lat, 10.01, 0.000001)
      end
    end
  end
end
