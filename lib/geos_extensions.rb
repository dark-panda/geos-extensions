
begin
  if !ENV['USE_BINARY_GEOS']
    require 'ffi-geos'
  end
rescue LoadError
end

require 'geos' unless defined?(Geos)

require File.join(File.dirname(__FILE__), *%w{ geos extensions version })
require File.join(File.dirname(__FILE__), *%w{ geos yaml })

# Some custom extensions to the SWIG-based Geos Ruby extension.
module Geos
  GEOS_EXTENSIONS_BASE = File.join(File.dirname(__FILE__))
  GEOS_EXTENSIONS_VERSION = Geos::Extensions::VERSION

  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos geometry })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos coordinate_sequence })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos point })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos line_string })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos polygon })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos geometry_collection })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos multi_polygon })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos multi_line_string })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ geos multi_point })

  autoload :Helper, File.join(GEOS_EXTENSIONS_BASE, *%w{ geos geos_helper })
  autoload :GoogleMaps, File.join(GEOS_EXTENSIONS_BASE, *%w{ geos google_maps })

  REGEXP_FLOAT = /(-?\d*(?:\.\d+)?|-?\d*(?:\.\d+?)[eE][-+]?\d+)/
  REGEXP_LAT_LNG = /#{REGEXP_FLOAT}\s*,\s*#{REGEXP_FLOAT}/

  REGEXP_WKT = /^\s*(?:SRID=(-?[0-9]+);)?(\s*[PLMCG].+)/im
  REGEXP_WKB_HEX = /^[A-Fa-f0-9\s]+$/

  REGEXP_G_LAT_LNG_BOUNDS = /^
    \(
      \(#{REGEXP_LAT_LNG}\) # sw
      \s*,\s*
      \(#{REGEXP_LAT_LNG}\) # ne
    \)
  $
    |
  ^
    #{REGEXP_LAT_LNG} # sw
    \s*,\s*
    #{REGEXP_LAT_LNG} # ne
  $/x

  REGEXP_G_LAT_LNG = /^
    \(?
      #{REGEXP_LAT_LNG}
    \)?
  $/x

  REGEXP_BOX2D = /^
    BOX\s*\(\s*
      #{REGEXP_FLOAT}\s+#{REGEXP_FLOAT}
      \s*,\s*
      #{REGEXP_FLOAT}\s+#{REGEXP_FLOAT}
    \s*\)
  $/mix

  def self.wkb_reader_singleton
    Thread.current[:geos_extensions_wkb_reader] ||= WkbReader.new
  end

  def self.wkt_reader_singleton
    Thread.current[:geos_extensions_wkt_reader] ||= WktReader.new
  end

  # Returns some kind of Geometry object from the given WKB in
  # binary.
  def self.from_wkb_bin(wkb, options = {})
    geom = self.wkb_reader_singleton.read(wkb)
    geom.srid = options[:srid].to_i if options[:srid]
    geom
  end

  # Returns some kind of Geometry object from the given WKB in hex.
  def self.from_wkb(wkb, options = {})
    geom = self.wkb_reader_singleton.read_hex(wkb)
    geom.srid = options[:srid].to_i if options[:srid]
    geom
  end

  ALLOWED_GEOS_READ_TYPES = [
    :geometry,
    :wkt,
    :wkb,
    :wkb_hex,
    :g_lat_lng_bounds,
    :g_lat_lng,
    :box2d,
    :wkb,
    :nil
  ]

  # Tries its best to return a Geometry object.
  def self.read(geom, options = {})
    allowed = Geos::Helper.array_wrap(options[:allowed] || ALLOWED_GEOS_READ_TYPES)
    allowed = allowed - Geos::Helper.array_wrap(options[:excluded])

    geom = geom.dup.force_encoding('BINARY') if geom.respond_to?(:force_encoding)

    type = case geom
      when Geos::Geometry
        :geometry
      when REGEXP_WKT
        :wkt
      when REGEXP_WKB_HEX
        :wkb_hex
      when REGEXP_G_LAT_LNG_BOUNDS
        :g_lat_lng_bounds
      when REGEXP_G_LAT_LNG
        :g_lat_lng
      when REGEXP_BOX2D
        :box2d
      when String
        :wkb
      when nil
        :nil
      else
        raise ArgumentError.new("Invalid geometry!")
    end

    if !allowed.include?(type)
      raise ArgumentError.new("geom appears to be a #{type} but #{type} is being filtered")
    end

    geos = case type
      when :geometry
        geom
      when :wkt
        Geos.from_wkt($~, options)
      when :wkb_hex
        Geos.from_wkb(geom, options)
      when :g_lat_lng_bounds, :g_lat_lng
        Geos.from_g_lat_lng($~, options)
      when :box2d
        Geos.from_box2d($~)
      when :wkb
        Geos.from_wkb(geom.unpack('H*').first.upcase, options)
      when :nil
        nil
    end

    if geos && options[:srid]
      geos.srid = options[:srid]
    end

    geos
  end

  # Returns some kind of Geometry object from the given WKT. This method
  # will also accept PostGIS-style EWKT and its various enhancements.
  def self.from_wkt(wkt_or_match_data, options = {})
    srid, raw_wkt = if wkt_or_match_data.kind_of?(MatchData)
      [ wkt_or_match_data[1], wkt_or_match_data[2] ]
    else
      wkt_or_match_data.scan(REGEXP_WKT).first
    end

    geom = self.wkt_reader_singleton.read(raw_wkt.upcase)
    geom.srid = (options[:srid] || srid).to_i if options[:srid] || srid
    geom
  end

  # Returns some kind of Geometry object from a String provided by a Google
  # Maps object. For instance, calling toString() on a GLatLng will output
  # (lat, lng), while calling on a GLatLngBounds will produce
  # ((sw lat, sw lng), (ne lat, ne lng)). This method handles both GLatLngs
  # and GLatLngBounds. In the case of GLatLngs, we return a new Geos::Point,
  # while for GLatLngBounds we return a Geos::Polygon that encompasses the
  # bounds. Use the option :points to interpret the incoming value as
  # as GPoints rather than GLatLngs.
  def self.from_g_lat_lng(geometry_or_match_data, options = {})
    match_data = case geometry_or_match_data
      when MatchData
        geometry_or_match_data.captures
      when REGEXP_G_LAT_LNG_BOUNDS, REGEXP_G_LAT_LNG
        $~.captures
      else
        raise "Invalid GLatLng format"
    end

    geom = if match_data.length > 3
      coords = Array.new
      match_data.compact.each_slice(2) { |f|
        coords << f.collect(&:to_f)
      }

      unless options[:points]
        coords.each do |c|
          c.reverse!
        end
      end

      Geos.from_wkt("LINESTRING(%s, %s)" % [
        coords[0].join(' '),
        coords[1].join(' ')
      ]).envelope
    else
      coords = match_data.collect(&:to_f).tap { |c|
        c.reverse! unless options[:points]
      }
      Geos.from_wkt("POINT(#{coords.join(' ')})")
    end

    if options[:srid]
      geom.srid = options[:srid]
    end

    geom
  end

  # Same as from_g_lat_lng but uses GPoints instead of GLatLngs and GBounds
  # instead of GLatLngBounds. Equivalent to calling from_g_lat_lng with a
  # non-false expression for the points parameter.
  def self.from_g_point(geometry, options = {})
    self.from_g_lat_lng(geometry, options.merge(:points => true))
  end

  # Creates a Geometry from a PostGIS-style BOX string.
  def self.from_box2d(geometry_or_match_data)
    match_data = case geometry_or_match_data
      when MatchData
        geometry_or_match_data.captures
      when REGEXP_BOX2D
        $~.captures
      else
        raise "Invalid BOX2D"
    end

    coords = []
    match_data.compact.each_slice(2) { |f|
      coords << f.collect(&:to_f)
    }

    Geos.from_wkt("LINESTRING(%s, %s)" % [
      coords[0].join(' '),
      coords[1].join(' ')
    ]).envelope
  end
end

