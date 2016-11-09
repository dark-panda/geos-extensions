# encoding: UTF-8
# frozen_string_literal: true

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
    alias_method :as_geojson, :to_geojsonable
  end
end

