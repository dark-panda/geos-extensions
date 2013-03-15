
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
      end
    end
  end
end

