
module Geos
  class CoordinateSequence
    # Returns a Ruby Array of Arrays of coordinates within the
    # CoordinateSequence in the form [ x, y, z ].
    def to_a
      (0...self.length).to_a.collect do |p|
        [
          self.get_x(p),
          (self.dimensions >= 2 ? self.get_y(p) : nil),
          (self.dimensions >= 3 && self.get_z(p) > 1.7e-306 ? self.get_z(p) : nil)
        ].compact
      end
    end

    # Build some XmlMarkup for KML. You can set various KML options like
    # tessellate, altitudeMode, etc. Use Rails/Ruby-style code and it
    # will be converted automatically, i.e. :altitudeMode, not
    # :altitude_mode.
    def to_kml(*args)
      xml, options = Geos::Helper.xml_options(*args)

      xml.LineString(:id => options[:id]) do
        xml.extrude(options[:extrude]) if options[:extrude]
        xml.tessellate(options[:tessellate]) if options[:tessellate]
        xml.altitudeMode(Geos::Helper.camelize(options[:altitude_mode])) if options[:altitudeMode]
        xml.coordinates do
          self.to_a.each do
            xml << (self.to_a.join(','))
          end
        end
      end
    end

    # Build some XmlMarkup for GeoRSS GML. You should include the
    # appropriate georss and gml XML namespaces in your document.
    def to_georss(*args)
      xml = Geos::Helper.xml_options(*args)[0]

      xml.georss(:where) do
        xml.gml(:LineString) do
          xml.gml(:posList) do
            xml << self.to_a.collect do |p|
              "#{p[1]} #{p[0]}"
            end.join(' ')
          end
        end
      end
    end

    # Returns a Hash suitable for converting to JSON.
    #
    # Options:
    #
    # * :encoded - enable or disable Google Maps encoding. The default is
    #   true.
    # * :level - set the level of the Google Maps encoding algorithm.
    def as_json(options = {})
      options = {
        :encoded => true,
        :level => 3
      }.merge options

      if options[:encoded]
        {
          :type => 'lineString',
          :encoded => true
        }.merge(Geos::GoogleMaps::PolylineEncoder.encode(self.to_a, options[:level]))
      else
        {
          :type => 'lineString',
          :encoded => false,
          :points => self.to_a
        }
      end
    end
    alias :to_jsonable :as_json

    def as_geojson(options = {})
      {
        :type => 'LineString',
        :coordinates => self.to_a
      }
    end
    alias :to_geojsonable :as_geojson

    def to_geojson(options = {})
      self.to_geojsonable(options).to_json
    end
  end
end

