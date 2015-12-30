# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

begin
  require 'builder'
  require 'stringio'
rescue LoadError
  # do nothing
end

begin
  require 'json'
rescue LoadError
  # do nothing
end

class GeosWriterTests < Minitest::Test
  include TestHelper

  def initialize(*args)
    @point = Geos.read(POINT_EWKB)
    @polygon = Geos.read(POLYGON_EWKB)
    @linestring = Geos.read(LINESTRING_WKT)
    @multipoint = Geos.read(MULTIPOINT_WKT)
    @multipolygon = Geos.read(MULTIPOLYGON_WKT)
    @multilinestring = Geos.read(MULTILINESTRING_WKT)
    @geometrycollection = Geos.read(GEOMETRYCOLLECTION_WKT)
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

  def test_to_ewkt_with_srid_option
    if @point.to_ewkt(:srid => 900913) =~ /^SRID=900913;\s*POINT\s*\((\d+\.\d+)\s*(\d+\.\d+)\)$/
      lng, lat = $1.to_f, $2.to_f
    end

    assert_in_delta(10.00, lng, 0.000001)
    assert_in_delta(10.01, lat, 0.000001)

    assert_equal(4326, @point.srid)

    if @point.to_ewkt(:srid => :default) =~ /^SRID=default;\s*POINT\s*\((\d+\.\d+)\s*(\d+\.\d+)\)$/
      lng, lat = $1.to_f, $2.to_f
    end

    assert_in_delta(10.00, lng, 0.000001)
    assert_in_delta(10.01, lat, 0.000001)

    assert_equal(4326, @point.srid)
  end

  def test_to_flickr_bbox
    assert_equal('0.0,0.0,5.0,2.5', @polygon.to_flickr_bbox)
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

      assert_equal("<Polygon id=\"\"><extrude>true</extrude><altitudeMode>relativeToGround</altitudeMode><outerBoundaryIs><LinearRing><coordinates>0.0,0.0 0.0,1.0 2.5,2.5 5.0,2.5 0.0,0.0</coordinates></LinearRing></outerBoundaryIs></Polygon>",
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

  if defined?(JSON)
    def test_to_geojson_coord_seq
      coord_seq = Geos.read(POLYGON_WKT).exterior_ring.coord_seq
      json = coord_seq.to_geojson

      assert_equal({
        "type" => "LineString",
        "coordinates" => [
          [ 0.0, 0.0 ],
          [ 0.0, 1.0 ],
          [ 2.5, 2.5 ],
          [ 5.0, 2.5 ],
          [ 0.0, 0.0 ]
        ]
      }, JSON.load(json))
    end

    def test_to_geojson_polygon
      polygon = Geos.read(POLYGON_WKT)
      json = polygon.to_geojson

      assert_equal({
        "type" => "Polygon",
        "coordinates" => [
          [
            [0.0, 0.0],
            [0.0, 1.0],
            [2.5, 2.5],
            [5.0, 2.5],
            [0.0, 0.0]
          ]
        ]
      }, JSON.load(json))
    end

    def test_to_geojson_polygon_with_interior_ring
      polygon = Geos.read(POLYGON_WITH_INTERIOR_RING)

      assert_equal({
        "type" => "Polygon",
        "coordinates" => [
          [
            [0.0, 0.0],
            [5.0, 0.0],
            [5.0, 5.0],
            [0.0, 5.0],
            [0.0, 0.0]
          ], [
            [4.0, 4.0],
            [4.0, 1.0],
            [1.0, 1.0],
            [1.0, 4.0],
            [4.0, 4.0]
          ]
        ]
      }, JSON.load(polygon.to_geojson))

      assert_equal({
        "type" => "Polygon",
        "coordinates" => [
          [
            [0.0, 0.0],
            [5.0, 0.0],
            [5.0, 5.0],
            [0.0, 5.0],
            [0.0, 0.0]
          ]
        ]
      }, JSON.load(polygon.to_geojson(:interior_rings => false)))
    end

    def test_to_geojson_point
      point = Geos.read(POINT_WKT)

      assert_equal({
        "type" => "Point",
        "coordinates" => [10.0, 10.01]
      }, JSON.load(point.to_geojson))
    end

    def test_to_geojson_line_string
      linestring = Geos.read(LINESTRING_WKT)

      assert_equal({
        "type" => "LineString",
        "coordinates" => [
          [0.0, 0.0],
          [5.0, 5.0],
          [5.0, 10.0],
          [10.0, 10.0]
        ]}, JSON.load(linestring.to_geojson))
    end

    def test_to_geojson_geometry_collection
      collection = Geos.read(GEOMETRYCOLLECTION_WKT)

      assert_equal({
        "type" => "GeometryCollection",
        "geometries" =>  [ {
          "type" => "MultiPolygon",
          "coordinates" =>  [
            [
              [
                [0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]
              ]
            ], [
              [
                [10.0, 10.0], [10.0, 14.0], [14.0, 14.0], [14.0, 10.0], [10.0, 10.0]
              ], [
                [11.0, 11.0], [11.0, 12.0], [12.0, 12.0], [12.0, 11.0], [11.0, 11.0]
              ]
            ]
          ]
        }, {
          "type" => "Polygon",
          "coordinates" => [
            [
              [0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]
            ]
          ]
        }, {
          "type" => "Polygon",
          "coordinates" => [
            [
              [0.0, 0.0], [5.0, 0.0], [5.0, 5.0], [0.0, 5.0], [0.0, 0.0]
            ], [
              [4.0, 4.0], [4.0, 1.0], [1.0, 1.0], [1.0, 4.0], [4.0, 4.0]
            ]
          ]
        }, {
          "type" => "MultiLineString",
          "coordinates" => [
            [
              [0.0, 0.0], [2.0, 3.0]
            ], [
              [10.0, 10.0], [3.0, 4.0]
            ]
          ]
        }, {
          "type" => "LineString",
          "coordinates" => [
            [0.0, 0.0], [2.0, 3.0]
          ]
        }, {
          "type" => "MultiPoint",
          "coordinates" => [
            [0.0, 0.0], [2.0, 3.0]
          ]
        }, {
          "type" => "Point",
          "coordinates" => [9.0, 0.0]
        }
      ] }, JSON.load(collection.to_geojson))

      assert_equal({
        "type" => "GeometryCollection",
        "geometries" => [ {
          "type" => "MultiPolygon",
          "coordinates" => [
            [
              [
                [0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]
              ]
            ], [
              [
                [10.0, 10.0], [10.0, 14.0], [14.0, 14.0], [14.0, 10.0], [10.0, 10.0]
              ]
            ]
          ]
        }, {
          "type" => "Polygon",
          "coordinates" => [
            [
              [0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]
            ]
          ]
        }, {
          "type" => "Polygon",
          "coordinates" => [
            [
              [0.0, 0.0], [5.0, 0.0], [5.0, 5.0], [0.0, 5.0], [0.0, 0.0]
            ]
          ]
        }, {
          "type" => "MultiLineString",
          "coordinates" => [
            [
              [0.0, 0.0], [2.0, 3.0]
            ],
            [
              [10.0, 10.0], [3.0, 4.0]
            ]
          ]
        }, {
          "type" => "LineString",
          "coordinates" => [
            [0.0, 0.0], [2.0, 3.0]
          ]
        }, {
          "type" => "MultiPoint",
          "coordinates" => [
            [0.0, 0.0], [2.0, 3.0]
          ]
        }, {
          "type" => "Point",
          "coordinates" => [9.0, 0.0]
        } ]
      }, JSON.load(collection.to_geojson(:interior_rings => false)))
    end
  end

  def test_to_box2d
    assert_equal("BOX(10.0 10.01, 10.0 10.01)", @point.to_box2d)
    assert_equal("BOX(0.0 0.0, 5.0 2.5)", @polygon.to_box2d)
    assert_equal("BOX(0.0 0.0, 10.0 10.0)", @linestring.to_box2d)
    assert_equal("BOX(0.0 0.0, 10.0 10.0)", @multipoint.to_box2d)
    assert_equal("BOX(0.0 0.0, 15.0 15.0)", @multipolygon.to_box2d)
    assert_equal("BOX(-20.0 -20.0, 30.0 30.0)", @multilinestring.to_box2d)
    assert_equal("BOX(0.0 0.0, 14.0 14.0)", @geometrycollection.to_box2d)
  end

  def test_as_json
    assert_equal({
      :type => "point",
      :lat => 10.01,
      :lng => 10.0
    }, @point.as_json)

    assert_equal({
      :type => "polygon",
      :encoded => true,
      :polylines => [ {
        :points => "??_ibE?_~cH_hgN?_hgN~ggN~po]",
        :levels => "BBBBB",
        :bounds => {
          :sw => [ 0.0, 0.0 ],
          :ne => [ 5.0, 2.5 ]
        }
      } ],
      :options => {}
    }, @polygon.as_json)

    assert_equal({
      :type => "polygon",
      :encoded => false,
      :polylines => [ {
        :points => [ [ 0.0, 0.0 ],  [ 0.0, 1.0 ],  [ 2.5, 2.5 ],  [ 5.0, 2.5 ],  [ 0.0, 0.0 ] ],
        :bounds => {
          :sw => [ 0.0, 0.0 ],
          :ne => [ 5.0, 2.5 ]
        }
      } ]
    }, @polygon.as_json(:encoded => false))

    assert_equal({
      :type => "lineString",
      :encoded => true,
      :points => "??_qo]_qo]_qo]??_qo]",
      :levels => "BBBB"
    }, @linestring.as_json)

    assert_equal({
      :type => "lineString",
      :encoded => false,
      :points => [ [ 0.0, 0.0 ], [ 5.0, 5.0 ], [ 5.0, 10.0 ], [ 10.0, 10.0 ] ]
    }, @linestring.as_json(:encoded => false))

    assert_equal([ {
      :type => "point",
      :lat => 0.0,
      :lng => 0.0
    }, {
      :type => "point",
      :lat => 10.0,
      :lng => 10.0
    } ], @multipoint.as_json)

    assert_equal([ {
      :type => "polygon",
      :encoded => true,
      :polylines => [ {
        :points => "???_qo]_qo]??~po]~po]?",
        :levels => "BBBBB",
        :bounds => {
          :sw => [ 0.0, 0.0 ],
          :ne => [ 5.0, 5.0 ]
        }
      } ],
      :options => {}
    }, {
      :type => "polygon",
      :encoded => true,
      :polylines => [ {
        :points => "_c`|@_c`|@?_qo]_qo]??~po]~po]?",
        :levels => "BBBBB",
        :bounds => {
          :sw => [ 10.0, 10.0 ],
          :ne => [ 15.0, 15.0 ]
        }
      } ],
      :options => {}
    } ], @multipolygon.as_json)

    assert_equal([ {
      :type => "polygon",
      :encoded => false,
      :polylines => [ {
        :points => [ [ 0.0, 0.0 ], [ 5.0, 0.0 ], [ 5.0, 5.0 ], [ 0.0, 5.0 ], [ 0.0, 0.0 ] ],
        :bounds => {
          :sw => [ 0.0, 0.0 ],
          :ne => [ 5.0, 5.0 ]
        }
      } ]
    }, {
      :type => "polygon",
      :encoded => false,
      :polylines => [ {
        :points => [ [ 10.0, 10.0 ], [ 15.0, 10.0 ], [ 15.0, 15.0 ], [ 10.0, 15.0 ], [ 10.0, 10.0 ] ],
        :bounds => {
          :sw => [ 10.0, 10.0 ],
          :ne => [ 15.0, 15.0 ]
        }
      } ]
    } ], @multipolygon.as_json(:encoded => false))

    assert_equal([ {
      :type => "lineString",
      :encoded => true,
      :points => "~fayB~fayB_kbvD_kbvD",
      :levels => "BB"
    }, {
      :type => "lineString",
      :encoded => true,
      :points => "??_kbvD_kbvD",
      :levels => "BB"
    } ], @multilinestring.as_json)

    assert_equal([{
      :type => "lineString",
      :encoded => false,
      :points => [ [ -20.0, -20.0 ], [ 10.0, 10.0 ] ]
    }, {
      :type => "lineString",
      :encoded => false,
      :points => [ [ 0.0, 0.0 ], [ 30.0, 30.0 ] ]
    } ], @multilinestring.as_json(:encoded => false))

    assert_equal([
      [ {
        :type => "polygon",
        :encoded => true,
        :polylines => [ {
          :points => "???_ibE_ibE??~hbE~hbE?",
          :levels => "BBBBB",
          :bounds => {
            :sw => [ 0.0, 0.0 ],
            :ne => [ 1.0, 1.0 ]
          }
        } ],
        :options => {}
      }, {
        :type => "polygon",
        :encoded => true,
        :polylines => [ {
          :points => "_c`|@_c`|@_glW??_glW~flW??~flW",
          :levels => "BBBBB",
          :bounds => {
            :sw => [ 10.0, 10.0 ],
            :ne => [ 14.0, 14.0 ]
          }
        } ],
        :options => {}
      } ],

      {
        :type => "polygon",
        :encoded => true,
        :polylines => [ {
          :points => "???_ibE_ibE??~hbE~hbE?",
          :levels => "BBBBB",
          :bounds => {
            :sw => [ 0.0, 0.0 ],
            :ne => [ 1.0, 1.0 ]
          }
        } ],
        :options => {}
      }, {
        :type => "polygon",
        :encoded => true,
        :polylines => [ {
          :points => "???_qo]_qo]??~po]~po]?",
          :levels => "BBBBB",
          :bounds => {
            :sw => [ 0.0, 0.0 ],
            :ne => [ 5.0, 5.0 ]
          }
        } ],
        :options => {}
      },

      [ {
        :type => "lineString",
        :encoded => true,
        :points => "??_}hQ_seK",
        :levels => "BB"
      }, {
        :type => "lineString",
        :encoded => true,
        :points => "_c`|@_c`|@~zrc@~dvi@",
        :levels => "BB"
      } ],

      {
        :type => "lineString",
        :encoded => true,
        :points => "??_}hQ_seK",
        :levels => "BB"
      },

      [ {
        :type => "point",
        :lat => 0.0,
        :lng => 0.0
      }, {
        :type => "point",
        :lat => 3.0,
        :lng => 2.0
      } ],

      {
        :type => "point",
        :lat => 0.0,
        :lng => 9.0
      }
    ], @geometrycollection.as_json)

    assert_equal([
      [ {
        :type => "polygon",
        :encoded => false,
        :polylines => [ {
          :points => [ [ 0.0, 0.0], [ 1.0, 0.0], [ 1.0, 1.0], [ 0.0, 1.0], [ 0.0, 0.0 ] ],
          :bounds => {
            :sw => [ 0.0, 0.0 ],
            :ne => [ 1.0, 1.0 ]
          }
        } ]
      },

      {
        :type => "polygon",
        :encoded => false,
        :polylines => [ {
          :points => [ [ 10.0, 10.0 ], [ 10.0, 14.0 ], [ 14.0, 14.0 ], [ 14.0, 10.0 ], [ 10.0, 10.0 ] ],
          :bounds => {
            :sw => [ 10.0, 10.0 ],
            :ne => [ 14.0, 14.0 ]
          }
        } ]
      } ],

      {
        :type => "polygon",
        :encoded => false,
        :polylines => [ {
          :points => [ [ 0.0, 0.0 ], [ 1.0, 0.0 ], [ 1.0, 1.0 ], [ 0.0, 1.0 ], [ 0.0, 0.0 ] ],
          :bounds => {
            :sw => [ 0.0, 0.0 ],
            :ne => [ 1.0, 1.0 ]
          }
        } ]
      },

      {
        :type => "polygon",
        :encoded => false,
        :polylines => [ {
          :points => [ [ 0.0, 0.0 ], [ 5.0, 0.0 ], [ 5.0, 5.0 ], [ 0.0, 5.0 ], [ 0.0, 0.0 ] ],
          :bounds => {
            :sw => [ 0.0, 0.0 ],
            :ne => [ 5.0, 5.0 ]
          }
        } ]
      },

      [ {
        :type => "lineString",
        :encoded => false,
        :points => [ [ 0.0, 0.0 ], [ 2.0, 3.0 ] ]
      }, {
        :type => "lineString",
        :encoded => false,
        :points => [ [ 10.0, 10.0 ], [ 3.0, 4.0 ] ]
      } ],

      {
        :type => "lineString",
        :encoded => false,
        :points => [ [ 0.0, 0.0 ], [ 2.0, 3.0 ] ]
      },

      [ {
        :type => "point",
        :lat => 0.0,
        :lng => 0.0
      }, {
        :type => "point",
        :lat => 3.0,
        :lng => 2.0
      } ],

      {
        :type => "point",
        :lat => 0.0,
        :lng => 9.0
      }
    ], @geometrycollection.as_json(:encoded => false))
  end
end
