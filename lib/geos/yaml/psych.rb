# encoding: UTF-8

module Geos
  class Geometry
    def init_with(coder)
      # Convert wkt to a geos pointer
      @ptr = Geos.read(coder['geom']).ptr
    end

    def encode_with(coder)
      # Note we enforce ASCII encoding so the geom in the YAML file is
      # readable -- otherwise psych converts it to a binary string.
      coder['geom'] = self.to_ewkt(
        :include_srid => self.srid != 0
      ).force_encoding('ASCII')
    end
  end
end
