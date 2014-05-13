
module Geos
  module GoogleMaps
    module ApiCommon
      module Geometry
        # Spit out Google's JSON geocoder Point format. The extra 0 is added
        # on as Google's format seems to like including the Z coordinate.
        def to_g_json_point
          {
            :coordinates => (self.centroid.to_a << 0)
          }
        end

        # Spit out Google's JSON geocoder ExtendedData LatLonBox format.
        def to_g_lat_lon_box
          {
            :north => self.north,
            :east => self.east,
            :south => self.south,
            :west => self.west
          }
        end

        # Spit out Google's toUrlValue format.
        def to_g_url_value(precision = 6)
          c = self.centroid
          "#{Geos::Helper.number_with_precision(c.lat, precision)},#{Geos::Helper.number_with_precision(c.lng, precision)}"
        end
        alias_method :to_g_url_value_point, :to_g_url_value

        # Force to Google's toUrlValue as a set of bounds.
        def to_g_url_value_bounds(precision = 6)
          url_value = self.to_g_url_value(precision)
          "#{url_value},#{url_value}"
        end
      end

      module UrlValueBounds
        # Spit out Google's toUrlValue format.
        def to_g_url_value(precision = 6)
          e = self.envelope
          "#{e.southwest.to_g_url_value(precision)},#{e.northeast.to_g_url_value(precision)}"
        end
        alias_method :to_g_url_value_bounds, :to_g_url_value

        # Force to Google's toUrlValue as a point.
        def to_g_url_value_point(precision = 6)
          self.centroid.to_g_url_value(precision)
        end
      end
    end
  end
end

