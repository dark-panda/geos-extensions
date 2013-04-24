
module Geos
  class LineString
    def as_json(options = {})
      self.coord_seq.as_json(options)
    end
    alias :to_jsonable :as_json

    def as_geojson(options = {})
      self.coord_seq.to_geojsonable(options)
    end
    alias :to_geojsonable :as_geojson
  end
end

