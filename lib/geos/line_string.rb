
module Geos
  class LineString
    def to_jsonable(options = {})
      self.coord_seq.to_jsonable(options)
    end

    def to_geojsonable(options = {})
      self.coord_seq.to_geojsonable(options)
    end
  end
end

