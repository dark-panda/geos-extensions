
if RUBY_VERSION >= '1.9'
  require 'simplecov'

  SimpleCov.command_name('Unit Tests')
  SimpleCov.start do
    add_filter '/test/'
  end
end

require 'rubygems'
require 'forwardable'
require 'minitest/autorun'

if RUBY_VERSION >= '1.9'
  require 'minitest/reporters'
end

require File.join(File.dirname(__FILE__), %w{ .. lib geos-extensions })

puts "Ruby version #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} - #{RbConfig::CONFIG['RUBY_INSTALL_NAME']}"
puts "ffi version #{Gem.loaded_specs['ffi'].version}" if Gem.loaded_specs['ffi']
puts "Geos library version #{Geos::VERSION}" if defined?(Geos::VERSION)
puts "GEOS version #{Geos::GEOS_VERSION}"
puts "GEOS extensions version #{Geos::GEOS_EXTENSIONS_VERSION}"
if defined?(Geos::FFIGeos)
  puts "Using #{Geos::FFIGeos.geos_library_paths.join(', ')}"
end

module TestHelper
  DELTA_TOLERANCE = 1e-8
  POINT_WKT = 'POINT(10 10.01)'
  POINT_EWKT = 'SRID=4326; POINT(10 10.01)'
  POINT_WKB = "0101000000000000000000244085EB51B81E052440"
  POINT_WKB_BIN = "\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x24\x40\x85\xEB\x51\xB8\x1E\x05\x24\x40"
  POINT_EWKB = "0101000020E6100000000000000000244085EB51B81E052440"
  POINT_EWKB_BIN = "\x01\x01\x00\x00\x20\xE6\x10\x00\x00\x00\x00\x00\x00\x00\x00\x24\x40\x85\xEB\x51\xB8\x1E\x05\x24\x40"
  POINT_G_LAT_LNG = "(10.01, 10)"
  POINT_G_LAT_LNG_URL_VALUE = "10.01,10"

  POLYGON_WKT = 'POLYGON((0 0, 0 1, 2.5 2.5, 5 2.5, 0 0))'
  POLYGON_EWKT = 'SRID=4326; POLYGON((0 0, 0 1, 2.5 2.5, 5 2.5, 0 0))'
  POLYGON_WKB = "
    01030000000100000005000000000000000000000000000000000000000000000000000
    000000000000000F03F0000000000000440000000000000044000000000000014400000
    00000000044000000000000000000000000000000000
  ".gsub(/\s/, '')
  POLYGON_WKB_BIN = [
    "\x01\x03\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\xF0\x3F\x00\x00\x00\x00\x00\x00\x04\x40\x00\x00\x00\x00",
    "\x00\x00\x04\x40\x00\x00\x00\x00\x00\x00\x14\x40\x00\x00\x00\x00\x00\x00\x04",
    "\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  ].join
  POLYGON_EWKB = "
    0103000020E610000001000000050000000000000000000000000000000000000000000
    00000000000000000000000F03F00000000000004400000000000000440000000000000
    1440000000000000044000000000000000000000000000000000
  ".gsub(/\s/, '')
  POLYGON_EWKB_BIN = [
    "\x01\x03\x00\x00\x20\xE6\x10\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xF0\x3F\x00\x00",
    "\x00\x00\x00\x00\x04\x40\x00\x00\x00\x00\x00\x00\x04\x40\x00\x00\x00",
    "\x00\x00\x00\x14\x40\x00\x00\x00\x00\x00\x00\x04\x40\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  ].join

  POLYGON_WITH_INTERIOR_RING = "POLYGON((0 0, 5 0, 5 5, 0 5, 0 0),(4 4, 4 1, 1 1, 1 4, 4 4))"

  LINESTRING_WKT = "LINESTRING (0 0, 5 5, 5 10, 10 10)"

  GEOMETRYCOLLECTION_WKT = 'GEOMETRYCOLLECTION (
    MULTIPOLYGON (
      ((0 0, 1 0, 1 1, 0 1, 0 0)),
      (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)
      )
    ),
    POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
    POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0), (4 4, 4 1, 1 1, 1 4, 4 4)),
    MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
    LINESTRING (0 0, 2 3),
    MULTIPOINT ((0 0), (2 3)),
    POINT (9 0)
  )'

  MULTIPOINT_WKT = "MULTIPOINT((0 0), (10 10))"

  MULTIPOLYGON_WKT = "MULTIPOLYGON(
    ((0 0, 5 0, 5 5, 0 5, 0 0),(4 4, 4 1, 1 1, 1 4, 4 4)),
    ((10 10, 15 10, 15 15, 10 15, 10 10),(14 14, 14 11, 11 11, 11 14, 14 14))
  )"

  MULTILINESTRING_WKT = "MULTILINESTRING((-20 -20, 10 10), (0 0, 30 30))"

  BOUNDS_G_LAT_LNG = "((0.1, 0.1), (5.2, 5.2))"
  BOUNDS_G_LAT_LNG_URL_VALUE = '0.1,0.1,5.2,5.2'

  def read(*args)
    Geos.read(*args)
  end

  if String.method_defined?(:force_encoding)
    POINT_WKB_BIN.force_encoding('BINARY')
    POINT_EWKB_BIN.force_encoding('BINARY')

    POLYGON_WKB_BIN.force_encoding('BINARY')
    POLYGON_EWKB_BIN.force_encoding('BINARY')
  end

  def assert_saneness_of_point(point)
    assert_kind_of(Geos::Point, point)
    assert_equal(10.01, point.lat)
    assert_equal(10, point.lng)
  end

  def assert_saneness_of_polygon(polygon)
    assert_kind_of(Geos::Polygon, polygon)
    cs = polygon.exterior_ring.coord_seq
    assert_equal([
      [ 0.0, 0.0 ],
      [ 0.0, 1.0 ],
      [ 2.5, 2.5 ],
      [ 5.0, 2.5 ],
      [ 0.0, 0.0 ]
    ], cs.to_a)
  end
end

if RUBY_VERSION >= '1.9'
  MiniTest::Reporters.use!(MiniTest::Reporters::SpecReporter.new)
end

