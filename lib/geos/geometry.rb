
module Geos
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
end

