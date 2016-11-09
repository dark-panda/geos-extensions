# encoding: UTF-8
# frozen_string_literal: true

module Geos
  class GeometryCollection
    if !GeometryCollection.included_modules.include?(Enumerable)
      include Enumerable

      # Iterates the collection through the given block.
      def each
        self.num_geometries.times do |n|
          yield self.get_geometry_n(n)
        end
        nil
      end

      # Returns the nth geometry from the collection.
      def [](*args)
        self.to_a[*args]
      end
      alias_method :slice, :[]
    end

    # Returns the last geometry from the collection.
    def last
      self.get_geometry_n(self.num_geometries - 1) if self.num_geometries > 0
    end

    # Returns a Hash suitable for converting to JSON.
    def as_json(options = {})
      self.collect do |p|
        p.to_jsonable options
      end
    end
    alias_method :to_jsonable, :as_json

    # Build some XmlMarkup for KML.
    def to_kml(*args)
      self.collect do |p|
        p.to_kml(*args)
      end
    end

    # Build some XmlMarkup for GeoRSS. Since GeoRSS is pretty trimed down,
    # we just take the entire collection and use the exterior_ring as
    # a Polygon. Not to bright, mind you, but until GeoRSS stops with the
    # suck, what are we to do. You should include the appropriate georss
    # and gml XML namespaces in your document.
    def to_georss(*args)
      self.exterior_ring.to_georss(*args)
    end

    def as_geojson(options = {})
      {
        :type => 'GeometryCollection',
        :geometries => self.to_a.collect { |g| g.to_geojsonable(options) }
      }
    end
    alias_method :to_geojsonable, :as_geojson
  end
end

