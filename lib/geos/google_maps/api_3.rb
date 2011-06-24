
module Geos::GoogleMaps::Api3
  module Geometry
    UNESCAPED_MARKER_OPTIONS = %w{
      icon
      map
      position
      shadow
      shape
    }.freeze

    # Returns a new LatLngBounds object with the proper GLatLngs in place
    # for determining the geometry bounds.
    def to_g_lat_lng_bounds_api3(options = {})
      "new google.maps.LatLngBounds(#{self.lower_left.to_g_lat_lng_api3(options)}, #{self.upper_right.to_g_lat_lng_api3(options)})"
    end

    # Returns a String in Google Maps' LatLngBounds#toString() format.
    def to_g_lat_lng_bounds_string_api3(precision = 10)
      "((#{self.lower_left.to_g_url_value_api3(precision)}), (#{self.upper_right.to_g_url_value_api3(precision)}))"
    end

    # Returns a new Polyline.
    def to_g_polyline_api3(polyline_options = {}, options = {})
      self.coord_seq.to_g_polyline_api3(polyline_options, options)
    end

    # Returns a new Polygon.
    def to_g_polygon_api3(polygon_options = {}, options = {})
      self.coord_seq.to_g_polygon_api3(polygon_options, options)
    end

    # Returns a new Marker at the centroid of the geometry. The options
    # Hash works the same as the Google Maps API MarkerOptions class does,
    # but allows for underscored Ruby-like options which are then converted
    # to the appropriate camel-cased Javascript options.
    def to_g_marker_api3(marker_options = {}, options = {})
      options = {
        :escape => [],
        :lat_lng_options => {}
      }.merge(options)

      opts = Geos::Helper.camelize_keys(marker_options)
      opts[:position] = self.centroid.to_g_lat_lng(options[:lat_lng_options])
      json = Geos::Helper.escape_json(opts, UNESCAPED_MARKER_OPTIONS - options[:escape])

      "new google.maps.Marker(#{json})"
    end
  end

  module CoordinateSequence
    # Returns a Ruby Array of GLatLngs.
    def to_g_lat_lng_api3(options = {})
      self.to_a.collect do |p|
        "new google.maps.LatLng(#{p[1]}, #{p[0]})"
      end
    end

    # Returns a new GPolyline. Note that this GPolyline just uses whatever
    # coordinates are found in the sequence in order, so it might not
    # make much sense at all.
    #
    # The options Hash follows the Google Maps API arguments to the
    # GPolyline constructor and include :color, :weight, :opacity and
    # :options. 'null' is used in place of any unset options.
    def to_g_polyline_api3(polyline_options = {}, options = {})
      klass = if options[:short_class]
        'GPolyline'
      else
        'google.maps.Polyline'
      end

      poly_opts = if polyline_options[:polyline_options]
        Geos::Helper.camelize_keys(polyline_options[:polyline_options])
      end

      args = [
        (polyline_options[:color] ? "'#{Geos::Helper.escape_javascript(polyline_options[:color])}'" : 'null'),
        (polyline_options[:weight] || 'null'),
        (polyline_options[:opacity] || 'null'),
        (poly_opts ? poly_opts.to_json : 'null')
      ].join(', ')

      "new #{klass}([#{self.to_g_lat_lng(options).join(', ')}], #{args})"
    end

    # Returns a new GPolygon. Note that this GPolygon just uses whatever
    # coordinates are found in the sequence in order, so it might not
    # make much sense at all.
    #
    # The options Hash follows the Google Maps API arguments to the
    # GPolygon constructor and include :stroke_color, :stroke_weight,
    # :stroke_opacity, :fill_color, :fill_opacity and :options. 'null' is
    # used in place of any unset options.
    def to_g_polygon_api3(polygon_options = {}, options = {})
      klass = if options[:short_class]
        'GPolygon'
      else
        'google.maps.Polygon'
      end

      poly_opts = if polygon_options[:polygon_options]
        Geos::Helper.camelize_keys(polygon_options[:polygon_options])
      end

      args = [
        (polygon_options[:stroke_color] ? "'#{Geos::Helper.escape_javascript(polygon_options[:stroke_color])}'" : 'null'),
        (polygon_options[:stroke_weight] || 'null'),
        (polygon_options[:stroke_opacity] || 'null'),
        (polygon_options[:fill_color] ? "'#{Geos::Helper.escape_javascript(polygon_options[:fill_color])}'" : 'null'),
        (polygon_options[:fill_opacity] || 'null'),
        (poly_opts ? poly_opts.to_json : 'null')
      ].join(', ')
      "new #{klass}([#{self.to_g_lat_lng_api3(options).join(', ')}], #{args})"
    end
  end

  module Point
    # Returns a new LatLng.
    def to_g_lat_lng_api3(options = {})
      no_wrap = if options[:no_wrap]
        ', true'
      end

      "new google.maps.LatLng(#{self.lat}, #{self.lng}#{no_wrap})"
    end

    # Returns a new Point
    def to_g_point_api3(options = {})
      "new google.maps.Point(#{self.x}, #{self.y})"
    end
  end

  module Polygon
    # Returns a GPolyline of the exterior ring of the Polygon. This does
    # not take into consideration any interior rings the Polygon may
    # have.
    def to_g_polyline_api3(polyline_options = {}, options = {})
      self.exterior_ring.to_g_polyline_api3(polyline_options, options)
    end

    # Returns a GPolygon of the exterior ring of the Polygon. This does
    # not take into consideration any interior rings the Polygon may
    # have.
    def to_g_polygon_api3(polygon_options = {}, options = {})
      self.exterior_ring.to_g_polygon_api3(polygon_options, options)
    end
  end

  module GeometryCollection
    # Returns a Ruby Array of GPolylines for each geometry in the
    # collection.
    def to_g_polyline_api3(polyline_options = {}, options = {})
      self.collect do |p|
        p.to_g_polyline_api3(polyline_options, options)
      end
    end

    # Returns a Ruby Array of GPolygons for each geometry in the
    # collection.
    def to_g_polygon_api3(polygon_options = {}, options = {})
      self.collect do |p|
        p.to_g_polygon_api3(polygon_options, options)
      end
    end
  end
end

Geos::GoogleMaps.use_api(2)
