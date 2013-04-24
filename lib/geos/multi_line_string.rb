
module Geos
  class MultiLineString < GeometryCollection
    def to_geojsonable(options = {})
      {
        :type => 'MultiLineString',
        :coordinates => self.to_a.collect { |linestring|
          linestring.coord_seq.to_a
        }
      }
    end
    alias :as_geojson :to_geojsonable
  end
end

