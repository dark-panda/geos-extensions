
module Geos::GoogleMaps
  module Api3
  end

  module Api3Constants
    UNESCAPED_MARKER_OPTIONS = %w{
      icon
      map
      position
      shadow
      shape
    }.freeze

    UNESCAPED_POLY_OPTIONS = %w{
      clickable
      fillOpacity
      geodesic
      map
      path
      paths
      strokeOpacity
      strokeWeight
      zIndex
    }.freeze
  end

  module Api3::Geometry
    include Geos::GoogleMaps::ApiCommon::Geometry

    # Returns a new LatLngBounds object with the proper LatLngs in place
    # for determining the geometry bounds.
    def to_g_lat_lng_bounds_api3(options = {})
      "new google.maps.LatLngBounds(#{self.lower_left.to_g_lat_lng_api3(options)}, #{self.upper_right.to_g_lat_lng_api3(options)})"
    end

    # Returns a bounds parameter for the Google Maps API 3 geocoder service.
    def to_g_geocoder_bounds_api3(precision = 6)
      "#{self.lower_left.to_g_url_value(precision)}|#{self.upper_right.to_g_url_value(precision)}"
    end

    # Returns a String in Google Maps' LatLngBounds#toString() format.
    def to_g_lat_lng_bounds_string_api3(precision = 10)
      "((#{self.lower_left.to_g_url_value(precision)}), (#{self.upper_right.to_g_url_value(precision)}))"
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
      json = Geos::Helper.escape_json(opts, Geos::GoogleMaps::Api3Constants::UNESCAPED_MARKER_OPTIONS - options[:escape])

      "new google.maps.Marker(#{json})"
    end
  end

  module Api3::CoordinateSequence
    # Returns a Ruby Array of LatLngs.
    def to_g_lat_lng_api3(options = {})
      self.to_a.collect do |p|
        "new google.maps.LatLng(#{p[1]}, #{p[0]})"
      end
    end

    # Returns a new Polyline. Note that this Polyline just uses whatever
    # coordinates are found in the sequence in order, so it might not
    # make much sense at all.
    #
    # The polyline_options Hash follows the Google Maps API arguments to the
    # Polyline constructor and include :clickable, :geodesic, :map, etc. See
    # the Google Maps API documentation for details.
    #
    # The options Hash allows you to specify if certain arguments should be
    # escaped on output. Usually the options in UNESCAPED_POLY_OPTIONS are
    # escaped, but if for some reason you want some other options to be
    # escaped, pass them along in options[:escape]. The options Hash also
    # passes along options to to_g_lat_lng_api3.
    def to_g_polyline_api3(polyline_options = {}, options = {})
      options = {
        :escape => [],
        :lat_lng_options => {}
      }.merge(options)

      opts = Geos::Helper.camelize_keys(polyline_options)
      opts[:path] = "[#{self.to_g_lat_lng_api3(options[:lat_lng_options]).join(', ')}]"
      json = Geos::Helper.escape_json(opts, Geos::GoogleMaps::Api3Constants::UNESCAPED_POLY_OPTIONS - options[:escape])

      "new google.maps.Polyline(#{json})"
    end

    # Returns a new Polygon. Note that this Polygon just uses whatever
    # coordinates are found in the sequence in order, so it might not
    # make much sense at all.
    #
    # The polygon_options Hash follows the Google Maps API arguments to the
    # Polyline constructor and include :clickable, :geodesic, :map, etc. See
    # the Google Maps API documentation for details.
    #
    # The options Hash allows you to specify if certain arguments should be
    # escaped on output. Usually the options in UNESCAPED_POLY_OPTIONS are
    # escaped, but if for some reason you want some other options to be
    # escaped, pass them along in options[:escape]. The options Hash also
    # passes along options to to_g_lat_lng_api3.
    def to_g_polygon_api3(polygon_options = {}, options = {})
      options = {
        :escape => [],
        :lat_lng_options => {}
      }.merge(options)

      opts = Geos::Helper.camelize_keys(polygon_options)
      opts[:paths] = "[#{self.to_g_lat_lng_api3(options[:lat_lng_options]).join(', ')}]"
      json = Geos::Helper.escape_json(opts, Geos::GoogleMaps::Api3Constants::UNESCAPED_POLY_OPTIONS - options[:escape])

      "new google.maps.Polygon(#{json})"
    end
  end

  module Api3::Point
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

  module Api3::Polygon
    include Geos::GoogleMaps::ApiCommon::UrlValueBounds

    # Returns a Polyline of the exterior ring of the Polygon. This does
    # not take into consideration any interior rings the Polygon may
    # have.
    def to_g_polyline_api3(polyline_options = {}, options = {})
      self.exterior_ring.to_g_polyline_api3(polyline_options, options)
    end

    # Returns a Polygon of the exterior ring of the Polygon. This does
    # not take into consideration any interior rings the Polygon may
    # have.
    def to_g_polygon_api3(polygon_options = {}, options = {})
      self.exterior_ring.to_g_polygon_api3(polygon_options, options)
    end
  end

  module Api3::LineString
    include Geos::GoogleMaps::ApiCommon::UrlValueBounds
  end

  module Api3::GeometryCollection
    include Geos::GoogleMaps::ApiCommon::UrlValueBounds

    # Returns a Ruby Array of Polylines for each geometry in the
    # collection.
    def to_g_polyline_api3(polyline_options = {}, options = {})
      self.collect do |p|
        p.to_g_polyline_api3(polyline_options, options)
      end
    end
    alias_method :to_g_polylines_api3, :to_g_polyline_api3

    # Returns a Ruby Array of Polygons for each geometry in the
    # collection. If the :single option is set, a single Polygon object will
    # be returned with all of the geometries set in the Polygon's "path"
    # attribute. You can also use to_g_polygon_single for the same effect.
    def to_g_polygon_api3(polygon_options = {}, options = {})
      if options[:single]
        self.to_g_polygon_single_api3(polygon_options, options)
      else
        self.collect do |p|
          p.to_g_polygon_api3(polygon_options, options)
        end
      end
    end

    # Behaves the same as to_g_polygon_api3 with the :single option set, where
    # a single Google Maps Polygon will be returned with all of the Polygons
    # set in the Polygon's "path" attribute.
    def to_g_polygon_single_api3(polygon_options = {}, options = {})
      options = {
        :escape => [],
        :lat_lng_options => {}
      }.merge(options)

      opts = Geos::Helper.camelize_keys(polygon_options)
      opts[:paths] = %{[#{self.collect { |p|
        "[#{p.exterior_ring.coord_seq.to_g_lat_lng_api3(options[:lat_lng_options]).join(', ')}]"
      }.join(', ')}]}
      json = Geos::Helper.escape_json(opts, Geos::GoogleMaps::Api3Constants::UNESCAPED_POLY_OPTIONS - options[:escape])

      "new google.maps.Polygon(#{json})"
    end
  end
end

Geos::GoogleMaps.use_api(3)
