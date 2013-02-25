
begin
  if !ENV['USE_BINARY_GEOS']
    require 'ffi-geos'
  end
rescue LoadError
end

require 'geos' unless defined?(Geos)

require File.join(File.dirname(__FILE__), *%w{ geos extensions version })

# Some custom extensions to the SWIG-based Geos Ruby extension.
module Geos
  GEOS_EXTENSIONS_BASE = File.join(File.dirname(__FILE__))
  GEOS_EXTENSIONS_VERSION = Geos::Extensions::VERSION

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
        Geos.from_wkt(geom, options)
      when :wkb_hex
        Geos.from_wkb(geom, options)
      when :g_lat_lng_bounds, :g_lat_lng
        Geos.from_g_lat_lng(geom, options)
      when :box2d
        Geos.from_box2d(geom)
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
  def self.from_wkt(wkt, options = {})
    srid, raw_wkt = wkt.scan(REGEXP_WKT).first
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
  def self.from_g_lat_lng(geometry, options = {})
    geom = case geometry
      when REGEXP_G_LAT_LNG_BOUNDS
        coords = Array.new
        $~.captures.compact.each_slice(2) { |f|
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
      when REGEXP_G_LAT_LNG
        coords = $~.captures.collect(&:to_f).tap { |c|
          c.reverse! unless options[:points]
        }
        Geos.from_wkt("POINT(#{coords.join(' ')})")
      else
        raise "Invalid GLatLng format"
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
  def self.from_box2d(geometry)
    if geometry =~ REGEXP_BOX2D
      coords = []
      $~.captures.compact.each_slice(2) { |f|
        coords << f.collect(&:to_f)
      }

      Geos.from_wkt("LINESTRING(%s, %s)" % [
        coords[0].join(' '),
        coords[1].join(' ')
      ]).envelope
    else
      raise "Invalid BOX2D"
    end
  end

  # This is our base module that we use for some generic methods used all
  # over the place.
  class Geometry
    protected

    WKB_WRITER_OPTIONS = [ :output_dimensions, :byte_order, :include_srid ].freeze
    def wkb_writer(options = {}) #:nodoc:
      writer = WkbWriter.new
      options.reject { |k, v| !WKB_WRITER_OPTIONS.include?(k) }.each do |k, v|
        writer.send("#{k}=", v)
      end
      writer
    end

    public

    # Spits the geometry out into WKB in binary.
    #
    # You can set the :output_dimensions, :byte_order and :include_srid
    # options via the options Hash.
    def to_wkb_bin(options = {})
      wkb_writer(options).write(self)
    end

    # Quickly call to_wkb_bin with :include_srid set to true.
    def to_ewkb_bin(options = {})
      options = {
        :include_srid => true
      }.merge options
      to_wkb_bin(options)
    end

    # Spits the geometry out into WKB in hex.
    #
    # You can set the :output_dimensions, :byte_order and :include_srid
    # options via the options Hash.
    def to_wkb(options = {})
      wkb_writer(options).write_hex(self)
    end

    # Quickly call to_wkb with :include_srid set to true.
    def to_ewkb(options = {})
      options = {
        :include_srid => true
      }.merge options
      to_wkb(options)
    end

    # Spits the geometry out into WKT. You can specify the :include_srid
    # option to create a PostGIS-style EWKT output.
    def to_wkt(options = {})
      writer = WktWriter.new

      # Older versions of the Geos library don't allow for options here.
      args = if WktWriter.instance_method(:write).arity < -1
        [ options ]
      else
        []
      end

      ret = ''

      if options[:include_srid]
        srid = if options[:srid]
          options[:srid]
        else
          self.srid
        end

        ret << "SRID=#{srid};"
      end

      ret << writer.write(self, *args)
      ret
    end

    # Quickly call to_wkt with :include_srid set to true.
    def to_ewkt(options = {})
      options = {
        :include_srid => true
      }.merge options
      to_wkt(options)
    end

    # Returns a Point for the envelope's upper left coordinate.
    def upper_left
      if defined?(@upper_left)
        @upper_left
      else
        cs = self.envelope.exterior_ring.coord_seq
        @upper_left = Geos::wkt_reader_singleton.read("POINT(#{cs.get_x(3)} #{cs.get_y(3)})")
      end
    end
    alias :nw :upper_left
    alias :northwest :upper_left

    # Returns a Point for the envelope's upper right coordinate.
    def upper_right
      if defined?(@upper_right)
        @upper_right
      else
        cs = self.envelope.exterior_ring.coord_seq
        @upper_right = Geos::wkt_reader_singleton.read("POINT(#{cs.get_x(2)} #{cs.get_y(2)})")
      end
    end
    alias :ne :upper_right
    alias :northeast :upper_right

    # Returns a Point for the envelope's lower right coordinate.
    def lower_right
      if defined?(@lower_right)
        @lower_right
      else
        cs = self.envelope.exterior_ring.coord_seq
        @lower_right = Geos::wkt_reader_singleton.read("POINT(#{cs.get_x(1)} #{cs.get_y(1)})")
      end
    end
    alias :se :lower_right
    alias :southeast :lower_right

    # Returns a Point for the envelope's lower left coordinate.
    def lower_left
      if defined?(@lower_left)
        @lower_left
      else
        cs = self.envelope.exterior_ring.coord_seq
        @lower_left = Geos::wkt_reader_singleton.read("POINT(#{cs.get_x(0)} #{cs.get_y(0)})")
      end
    end
    alias :sw :lower_left
    alias :southwest :lower_left

    # Northern-most Y coordinate.
    def top
      if defined?(@top)
        @top
      else
        @top = self.upper_right.y
      end
    end
    alias :n :top
    alias :north :top

    # Eastern-most X coordinate.
    def right
      if defined?(@right)
        @right
      else
        @right = self.upper_right.x
      end
    end
    alias :e :right
    alias :east :right

    # Southern-most Y coordinate.
    def bottom
      if defined?(@bottom)
        @bottom
      else
        @bottom = self.lower_left.y
      end
    end
    alias :s :bottom
    alias :south :bottom

    # Western-most X coordinate.
    def left
      if defined?(@left)
        @left
      else
        @left = self.lower_left.x
      end
    end
    alias :w :left
    alias :west :left

    # Spits out a bounding box the way Flickr likes it. You can set the
    # precision of the rounding using the :precision option. In order to
    # ensure that the box is indeed a box and not merely a point, the
    # southwest coordinates are floored and the northeast point ceiled.
    def to_flickr_bbox(options = {})
      options = {
        :precision => 1
      }.merge(options)
      precision = 10.0 ** options[:precision]

      [
        (self.west  * precision).floor / precision,
        (self.south * precision).floor / precision,
        (self.east  * precision).ceil / precision,
        (self.north * precision).ceil / precision
      ].join(',')
    end

    def to_geojson(options = {})
      self.to_geojsonable(options).to_json
    end

    def lat_lng
      self.centroid.to_a[0, 2].reverse
    end
    alias :lat_long :lat_lng
    alias :latlng :lat_lng
    alias :latlong :lat_lng
    alias :lat_lon :lat_lng
    alias :latlon :lat_lng

    def lng_lat
      self.centroid.to_a[0, 2]
    end
    alias :long_lat :lng_lat
    alias :lnglat :lng_lat
    alias :longlat :lng_lat
    alias :lon_lat :lng_lat
    alias :lonlat :lng_lat
  end

  class CoordinateSequence
    # Returns a Ruby Array of Arrays of coordinates within the
    # CoordinateSequence in the form [ x, y, z ].
    def to_a
      (0...self.length).to_a.collect do |p|
        [
          self.get_x(p),
          (self.dimensions >= 2 ? self.get_y(p) : nil),
          (self.dimensions >= 3 && self.get_z(p) > 1.7e-306 ? self.get_z(p) : nil)
        ].compact
      end
    end

    # Build some XmlMarkup for KML. You can set various KML options like
    # tessellate, altitudeMode, etc. Use Rails/Ruby-style code and it
    # will be converted automatically, i.e. :altitudeMode, not
    # :altitude_mode.
    def to_kml *args
      xml, options = Geos::Helper.xml_options(*args)

      xml.LineString(:id => options[:id]) do
        xml.extrude(options[:extrude]) if options[:extrude]
        xml.tessellate(options[:tessellate]) if options[:tessellate]
        xml.altitudeMode(Geos::Helper.camelize(options[:altitude_mode])) if options[:altitudeMode]
        xml.coordinates do
          self.to_a.each do
            xml << (self.to_a.join(','))
          end
        end
      end
    end

    # Build some XmlMarkup for GeoRSS GML. You should include the
    # appropriate georss and gml XML namespaces in your document.
    def to_georss *args
      xml = Geos::Helper.xml_options(*args)[0]

      xml.georss(:where) do
        xml.gml(:LineString) do
          xml.gml(:posList) do
            xml << self.to_a.collect do |p|
              "#{p[1]} #{p[0]}"
            end.join(' ')
          end
        end
      end
    end

    # Returns a Hash suitable for converting to JSON.
    #
    # Options:
    #
    # * :encoded - enable or disable Google Maps encoding. The default is
    #   true.
    # * :level - set the level of the Google Maps encoding algorithm.
    def to_jsonable options = {}
      options = {
        :encoded => true,
        :level => 3
      }.merge options

      if options[:encoded]
        {
          :type => 'lineString',
          :encoded => true
        }.merge(Geos::GoogleMaps::PolylineEncoder.encode(self.to_a, options[:level]))
      else
        {
          :type => 'lineString',
          :encoded => false,
          :points => self.to_a
        }
      end
    end

    def to_geojsonable(options = {})
      {
        :type => 'LineString',
        :coordinates => self.to_a
      }
    end

    def to_geojson(options = {})
      self.to_geojsonable(options).to_json
    end
  end


  class Point
    unless method_defined?(:y)
      # Returns the Y coordinate of the Point.
      def y
        self.to_a[1]
      end
    end

    %w{
      latitude lat north south n s
    }.each do |name|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        alias #{name} :y
      EOF
    end

    unless method_defined?(:x)
      # Returns the X coordinate of the Point.
      def x
        self.to_a[0]
      end
    end

    %w{
      longitude lng east west e w
    }.each do |name|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        alias #{name} :x
      EOF
    end

    unless method_defined?(:z)
      # Returns the Z coordinate of the Point.
      def z
        if self.has_z?
          self.to_a[2]
        else
          nil
        end
      end
    end

    # Returns the Point's coordinates as an Array in the following format:
    #
    #  [ x, y, z ]
    #
    # The Z coordinate will only be present for Points which have a Z
    # dimension.
    def to_a
      if defined?(@to_a)
        @to_a
      else
        cs = self.coord_seq
        @to_a = if self.has_z?
          [ cs.get_x(0), cs.get_y(0), cs.get_z(0) ]
        else
          [ cs.get_x(0), cs.get_y(0) ]
        end
      end
    end

    # Optimize some unnecessary code away:
    %w{
      upper_left upper_right lower_right lower_left
      ne nw se sw
      northwest northeast southeast southwest
    }.each do |name|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def #{name}
          self
        end
      EOF
    end

    # Build some XmlMarkup for KML. You can set KML options for extrude and
    # altitudeMode. Use Rails/Ruby-style code and it will be converted
    # appropriately, i.e. :altitude_mode, not :altitudeMode.
    def to_kml *args
      xml, options = Geos::Helper.xml_options(*args)
      xml.Point(:id => options[:id]) do
        xml.extrude(options[:extrude]) if options[:extrude]
        xml.altitudeMode(Geos::Helper.camelize(options[:altitude_mode])) if options[:altitude_mode]
        xml.coordinates(self.to_a.join(','))
      end
    end

    # Build some XmlMarkup for GeoRSS. You should include the
    # appropriate georss and gml XML namespaces in your document.
    def to_georss *args
      xml = Geos::Helper.xml_options(*args)[0]
      xml.georss(:where) do
        xml.gml(:Point) do
          xml.gml(:pos, "#{self.lat} #{self.lng}")
        end
      end
    end

    # Returns a Hash suitable for converting to JSON.
    def to_jsonable options = {}
      cs = self.coord_seq
      if self.has_z?
        { :type => 'point', :lat => cs.get_y(0), :lng => cs.get_x(0), :z => cs.get_z(0) }
      else
        { :type => 'point', :lat => cs.get_y(0), :lng => cs.get_x(0) }
      end
    end

    def to_geojsonable(options = {})
      {
        :type => 'Point',
        :coordinates => self.to_a
      }
    end
  end


  class LineString
    def to_jsonable(options = {})
      self.coord_seq.to_jsonable(options)
    end

    def to_geojsonable(options = {})
      self.coord_seq.to_geojsonable(options)
    end
  end

  class Polygon
    # Build some XmlMarkup for XML. You can set various KML options like
    # tessellate, altitudeMode, etc. Use Rails/Ruby-style code and it
    # will be converted automatically, i.e. :altitudeMode, not
    # :altitude_mode. You can also include interior rings by setting
    # :interior_rings to true. The default is false.
    def to_kml *args
      xml, options = Geos::Helper.xml_options(*args)

      xml.Polygon(:id => options[:id]) do
        xml.extrude(options[:extrude]) if options[:extrude]
        xml.tessellate(options[:tessellate]) if options[:tessellate]
        xml.altitudeMode(Geos::Helper.camelize(options[:altitude_mode])) if options[:altitude_mode]
        xml.outerBoundaryIs do
          xml.LinearRing do
            xml.coordinates do
              xml << self.exterior_ring.coord_seq.to_a.collect do |p|
                p.join(',')
              end.join(' ')
            end
          end
        end
        (0...self.num_interior_rings).to_a.each do |n|
          xml.innerBoundaryIs do
            xml.LinearRing do
              xml.coordinates do
                xml << self.interior_ring_n(n).coord_seq.to_a.collect do |p|
                  p.join(',')
                end.join(' ')
              end
            end
          end
        end if options[:interior_rings] && self.num_interior_rings > 0
      end
    end

    # Build some XmlMarkup for GeoRSS. You should include the
    # appropriate georss and gml XML namespaces in your document.
    def to_georss *args
      xml = Geos::Helper.xml_options(*args)[0]

      xml.georss(:where) do
        xml.gml(:Polygon) do
          xml.gml(:exterior) do
            xml.gml(:LinearRing) do
              xml.gml(:posList) do
                xml << self.exterior_ring.coord_seq.to_a.collect do |p|
                  "#{p[1]} #{p[0]}"
                end.join(' ')
              end
            end
          end
        end
      end
    end

    # Returns a Hash suitable for converting to JSON.
    #
    # Options:
    #
    # * :encoded - enable or disable Google Maps encoding. The default is
    #   true.
    # * :level - set the level of the Google Maps encoding algorithm.
    # * :interior_rings - add interior rings to the output. The default
    #   is false.
    # * :style_options - any style options you want to pass along in the
    #   JSON. These options will be automatically camelized into
    #   Javascripty code.
    def to_jsonable options = {}
      options = {
        :encoded => true,
        :level => 3,
        :interior_rings => false
      }.merge options

      style_options = Hash.new
      if options[:style_options] && !options[:style_options].empty?
        options[:style_options].each do |k, v|
          style_options[Geos::Helper.camelize(k.to_s)] = v
        end
      end

      if options[:encoded]
        ret = {
          :type => 'polygon',
          :encoded => true,
          :polylines => [ Geos::GoogleMaps::PolylineEncoder.encode(
              self.exterior_ring.coord_seq.to_a,
              options[:level]
            ).merge(:bounds => {
              :sw => self.lower_left.to_a,
              :ne => self.upper_right.to_a
            })
          ],
          :options => style_options
        }

        if options[:interior_rings] && self.num_interior_rings > 0
          (0..(self.num_interior_rings) - 1).to_a.each do |n|
            ret[:polylines] << Geos::GoogleMaps::PolylineEncoder.encode(
              self.interior_ring_n(n).coord_seq.to_a,
              options[:level]
            )
          end
        end
        ret
      else
        ret = {
          :type => 'polygon',
          :encoded => false,
          :polylines => [{
            :points => self.exterior_ring.coord_seq.to_a,
            :bounds => {
              :sw => self.lower_left.to_a,
              :ne => self.upper_right.to_a
            }
          }]
        }
        if options[:interior_rings] && self.num_interior_rings > 0
          (0..(self.num_interior_rings) - 1).to_a.each do |n|
            ret[:polylines] << {
              :points => self.interior_ring_n(n).coord_seq.to_a
            }
          end
        end
        ret
      end
    end

    # Options:
    #
    # * :interior_rings - whether to include any interior rings in the output.
    #   The default is true.
    def to_geojsonable(options = {})
      options = {
        :interior_rings => true
      }.merge(options)

      ret = {
        :type => 'Polygon',
        :coordinates => [ self.exterior_ring.coord_seq.to_a ]
      }

      if options[:interior_rings] && self.num_interior_rings > 0
        ret[:coordinates].concat self.interior_rings.collect { |r|
          r.coord_seq.to_a
        }
      end

      ret
    end
  end


  class GeometryCollection
    if !GeometryCollection.included_modules.include?(Enumerable)
      include Enumerable

      # Iterates the collection through the given block.
      def each
        self.num_geometries.times do |n|
          yield self.get_geometry_n(n)
        end
        nil
      end

      # Returns the nth geometry from the collection.
      def [](*args)
        self.to_a[*args]
      end
      alias :slice :[]
    end

    # Returns the last geometry from the collection.
    def last
      self.get_geometry_n(self.num_geometries - 1) if self.num_geometries > 0
    end

    # Returns a Hash suitable for converting to JSON.
    def to_jsonable options = {}
      self.collect do |p|
        p.to_jsonable options
      end
    end

    # Build some XmlMarkup for KML.
    def to_kml *args
      self.collect do |p|
        p.to_kml(*args)
      end
    end

    # Build some XmlMarkup for GeoRSS. Since GeoRSS is pretty trimed down,
    # we just take the entire collection and use the exterior_ring as
    # a Polygon. Not to bright, mind you, but until GeoRSS stops with the
    # suck, what are we to do. You should include the appropriate georss
    # and gml XML namespaces in your document.
    def to_georss *args
      self.exterior_ring.to_georss(*args)
    end

    def to_geojsonable(options = {})
      {
        :type => 'GeometryCollection',
        :geometries => self.to_a.collect { |g| g.to_geojsonable(options) }
      }
    end
  end

  class MultiPolygon < GeometryCollection
    def to_geojsonable(options = {})
      options = {
        :interior_rings => true
      }.merge(options)

      {
        :type => 'MultiPolygon',
        :coordinates => self.to_a.collect { |polygon|
          coords = [ polygon.exterior_ring.coord_seq.to_a ]

          if options[:interior_rings] && polygon.num_interior_rings > 0
            coords.concat polygon.interior_rings.collect { |r|
              r.coord_seq.to_a
            }
          end

          coords
        }
      }
    end
  end

  class MultiLineString < GeometryCollection
    def to_geojsonable(options = {})
      {
        :type => 'MultiLineString',
        :coordinates => self.to_a.collect { |linestring|
          linestring.coord_seq.to_a
        }
      }
    end
  end

  class MultiPoint < GeometryCollection
    def to_geojsonable(options = {})
      {
        :type => 'MultiPoint',
        :coordinates => self.to_a.collect { |point|
          point.to_a
        }
      }
    end
  end
end
