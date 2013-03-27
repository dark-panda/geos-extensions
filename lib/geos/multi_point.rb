
module Geos
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

