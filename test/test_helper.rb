
require 'rubygems'
require 'test/unit'

if ENV['TEST_ACTIVERECORD']
  ACTIVERECORD_GEM_VERSION = ENV['ACTIVERECORD_GEM_VERSION'] || '~> 3.0.3'
  gem 'activerecord', ACTIVERECORD_GEM_VERSION

  POSTGIS_PATHS = [
    ENV['POSTGIS_PATH'],
    '/opt/local/share/postgresql*/contrib/postgis-*',
    '/usr/share/postgresql*/contrib/postgis-*',
    '/usr/pgsql-*/share/contrib/postgis-*',
  ].compact

  puts "Testing against ActiveRecord #{Gem.loaded_specs['activerecord'].version.to_s}"
  require 'active_support'
  require 'active_support/core_ext/module/aliasing'
  require 'active_record'
  require 'active_record/fixtures'
  require 'logger'
end

require File.join(File.dirname(__FILE__), %w{ .. lib geos_extensions })

puts "Ruby version #{RUBY_VERSION} - #{RbConfig::CONFIG['RUBY_INSTALL_NAME']}"
puts "ffi version #{Gem.loaded_specs['ffi'].version}" if Gem.loaded_specs['ffi']
puts "Geos library version #{Geos::VERSION}" if defined?(Geos::VERSION)
puts "GEOS version #{Geos::GEOS_VERSION}"
puts "GEOS extensions version #{Geos::GEOS_EXTENSIONS_VERSION}"
if defined?(Geos::FFIGeos)
  puts "Using #{Geos::FFIGeos.geos_library_paths.join(', ')}"
end

if ENV['TEST_ACTIVERECORD']
  ActiveRecord::Base.logger = Logger.new("debug.log")
  ActiveRecord::Base.configurations = {
    'arunit' => {
      :adapter => 'postgresql',
      :database => 'geos_extensions_unit_tests',
      :min_messages => 'warning',
      :schema_search_path => 'public'
    }
  }

  ActiveRecord::Base.establish_connection 'arunit'
  ARBC = ActiveRecord::Base.connection

  if postgresql_version = ARBC.query('SELECT version()').flatten.to_s
    puts "PostgreSQL info from version(): #{postgresql_version}"
  end

  puts "Checking for PostGIS install"
  2.times do
    begin
      if postgis_version = ARBC.query('SELECT postgis_full_version()').flatten.to_s
        puts "PostGIS info from postgis_full_version(): #{postgis_version}"
        break
      end
    rescue ActiveRecord::StatementInvalid
      puts "Trying to install PostGIS. If this doesn't work, you'll have to do this manually!"

      plpgsql = ARBC.query(%{SELECT count(*) FROM pg_language WHERE lanname = 'plpgsql'}).to_s
      if plpgsql == '0'
        ARBC.execute(%{CREATE LANGUAGE plpgsql})
      end

      %w{
        postgis.sql
        spatial_ref_sys.sql
      }.each do |file|
        if !(found = Dir.glob(POSTGIS_PATHS).collect { |path|
          File.join(path, file)
        }.first)
          puts "ERROR: Couldn't find #{file}. Try setting the POSTGIS_PATH to give us a hint!"
          exit
        else
          ARBC.execute(File.read(found))
        end
      end
    end
  end

  if !ARBC.table_exists?('foos')
    ActiveRecord::Migration.create_table(:foos) do |t|
      t.text :name
    end

    ARBC.execute(%{SELECT AddGeometryColumn('public', 'foos', 'the_geom', -1, 'GEOMETRY', 2)})
    ARBC.execute(%{SELECT AddGeometryColumn('public', 'foos', 'the_other_geom', 4326, 'GEOMETRY', 2)})
  end

  class Foo < ActiveRecord::Base
    include Geos::ActiveRecord::GeometryColumns
    include Geos::ActiveRecord::GeospatialScopes
    create_geometry_column_accessors!
  end
end

module TestHelper
  POINT_WKT = 'POINT(10 10.01)'
  POINT_EWKT = 'SRID=4326; POINT(10 10.01)'
  POINT_EWKT_WITH_DEFAULT = 'SRID=default; POINT(10 10.01)'
  POINT_WKB = "0101000000000000000000244085EB51B81E052440"
  POINT_WKB_BIN = "\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x24\x40\x85\xEB\x51\xB8\x1E\x05\x24\x40"
  POINT_EWKB = "0101000020E6100000000000000000244085EB51B81E052440"
  POINT_EWKB_BIN = "\x01\x01\x00\x00\x20\xE6\x10\x00\x00\x00\x00\x00\x00\x00\x00\x24\x40\x85\xEB\x51\xB8\x1E\x05\x24\x40"
  POINT_G_LAT_LNG = "(10.01, 10)"
  POINT_G_LAT_LNG_URL_VALUE = "10.01,10"

  POLYGON_WKT = 'POLYGON((0 0, 1 1, 2.5 2.5, 5 5, 0 0))'
  POLYGON_EWKT = 'SRID=4326; POLYGON((0 0, 1 1, 2.5 2.5, 5 5, 0 0))'
  POLYGON_WKB = "
    0103000000010000000500000000000000000000000000000000000000000000000000F
    03F000000000000F03F0000000000000440000000000000044000000000000014400000
    00000000144000000000000000000000000000000000
  ".gsub(/\s/, '')
  POLYGON_WKB_BIN = [
    "\x01\x03\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xF0\x3F\x00",
    "\x00\x00\x00\x00\x00\xF0\x3F\x00\x00\x00\x00\x00\x00\x04\x40\x00\x00\x00\x00",
    "\x00\x00\x04\x40\x00\x00\x00\x00\x00\x00\x14\x40\x00\x00\x00\x00\x00\x00\x14",
    "\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  ].join
  POLYGON_EWKB = "
    0103000020E610000001000000050000000000000000000000000000000000000000000
    0000000F03F000000000000F03F00000000000004400000000000000440000000000000
    1440000000000000144000000000000000000000000000000000
  ".gsub(/\s/, '')
  POLYGON_EWKB_BIN = [
    "\x01\x03\x00\x00\x20\xE6\x10\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\xF0\x3F\x00\x00\x00\x00\x00\x00\xF0\x3F\x00\x00",
    "\x00\x00\x00\x00\x04\x40\x00\x00\x00\x00\x00\x00\x04\x40\x00\x00\x00",
    "\x00\x00\x00\x14\x40\x00\x00\x00\x00\x00\x00\x14\x40\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  ].join

  POLYGON_WITH_INTERIOR_RING = "POLYGON((0 0, 5 0, 5 5, 0 5, 0 0),(4 4, 4 1, 1 1, 1 4, 4 4))"

  BOUNDS_G_LAT_LNG = "((0.1, 0.1), (5.2, 5.2))"
  BOUNDS_G_LAT_LNG_URL_VALUE = '0.1,0.1,5.2,5.2'

  def assert_saneness_of_point(point)
    assert_kind_of(Geos::Point, point)
    assert_equal(10.01, point.lat)
    assert_equal(10, point.lng)
  end

  def assert_saneness_of_polygon(polygon)
    assert_kind_of(Geos::Polygon, polygon)
    cs = polygon.exterior_ring.coord_seq
    assert_equal([
      [ 0, 0 ],
      [ 1, 1 ],
      [ 2.5, 2.5 ],
      [ 5, 5 ],
      [ 0, 0 ]
    ], cs.to_a)
  end
end
