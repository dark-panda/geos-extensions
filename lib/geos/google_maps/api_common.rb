
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
      end

      module UrlValueBounds
        # Spit out Google's toUrlValue format.
        def to_g_url_value(precision = 6)
          e = self.envelope
          "#{e.southwest.to_g_url_value(precision)},#{e.northeast.to_g_url_value(precision)}"
        end
      end
    end
  end
end

