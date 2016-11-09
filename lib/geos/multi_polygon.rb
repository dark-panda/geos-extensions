# encoding: UTF-8
# frozen_string_literal: true

module Geos
  class MultiPolygon < GeometryCollection
    def to_geojsonable(options = {})
      options = {
        :interior_rings => true
      }.merge(options)

      {
        :type => 'MultiPolygon',
        :coordinates => self.to_a.collect { |polygon|
          coords = [ polygon.exterior_ring.coord_seq.to_a ]

          if options[:interior_rings] && polygon.num_interior_rings > 0
            coords.concat polygon.interior_rings.collect { |r|
              r.coord_seq.to_a
            }
          end

          coords
        }
      }
    end
    alias_method :as_geojson, :to_geojsonable
  end
end

