
module Geos
  class Polygon
    # Build some XmlMarkup for XML. You can set various KML options like
    # tessellate, altitudeMode, etc. Use Rails/Ruby-style code and it
    # will be converted automatically, i.e. :altitudeMode, not
    # :altitude_mode. You can also include interior rings by setting
    # :interior_rings to true. The default is false.
    def to_kml(*args)
      xml, options = Geos::Helper.xml_options(*args)

      xml.Polygon(:id => options[:id]) do
        xml.extrude(options[:extrude]) if options[:extrude]
        xml.tessellate(options[:tessellate]) if options[:tessellate]
        xml.altitudeMode(Geos::Helper.camelize(options[:altitude_mode])) if options[:altitude_mode]
        xml.outerBoundaryIs do
          xml.LinearRing do
            xml.coordinates do
              xml << self.exterior_ring.coord_seq.to_a.collect do |p|
                p.join(',')
              end.join(' ')
            end
          end
        end
        (0...self.num_interior_rings).to_a.each do |n|
          xml.innerBoundaryIs do
            xml.LinearRing do
              xml.coordinates do
                xml << self.interior_ring_n(n).coord_seq.to_a.collect do |p|
                  p.join(',')
                end.join(' ')
              end
            end
          end
        end if options[:interior_rings] && self.num_interior_rings > 0
      end
    end

    # Build some XmlMarkup for GeoRSS. You should include the
    # appropriate georss and gml XML namespaces in your document.
    def to_georss(*args)
      xml = Geos::Helper.xml_options(*args)[0]

      xml.georss(:where) do
        xml.gml(:Polygon) do
          xml.gml(:exterior) do
            xml.gml(:LinearRing) do
              xml.gml(:posList) do
                xml << self.exterior_ring.coord_seq.to_a.collect do |p|
                  "#{p[1]} #{p[0]}"
                end.join(' ')
              end
            end
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
    # * :interior_rings - add interior rings to the output. The default
    #   is false.
    # * :style_options - any style options you want to pass along in the
    #   JSON. These options will be automatically camelized into
    #   Javascripty code.
    def to_jsonable(options = {})
      options = {
        :encoded => true,
        :level => 3,
        :interior_rings => false
      }.merge options

      style_options = Hash.new
      if options[:style_options] && !options[:style_options].empty?
        options[:style_options].each do |k, v|
          style_options[Geos::Helper.camelize(k.to_s)] = v
        end
      end

      if options[:encoded]
        ret = {
          :type => 'polygon',
          :encoded => true,
          :polylines => [ Geos::GoogleMaps::PolylineEncoder.encode(
              self.exterior_ring.coord_seq.to_a,
              options[:level]
            ).merge(:bounds => {
              :sw => self.lower_left.to_a,
              :ne => self.upper_right.to_a
            })
          ],
          :options => style_options
        }

        if options[:interior_rings] && self.num_interior_rings > 0
          (0..(self.num_interior_rings) - 1).to_a.each do |n|
            ret[:polylines] << Geos::GoogleMaps::PolylineEncoder.encode(
              self.interior_ring_n(n).coord_seq.to_a,
              options[:level]
            )
          end
        end
        ret
      else
        ret = {
          :type => 'polygon',
          :encoded => false,
          :polylines => [{
            :points => self.exterior_ring.coord_seq.to_a,
            :bounds => {
              :sw => self.lower_left.to_a,
              :ne => self.upper_right.to_a
            }
          }]
        }
        if options[:interior_rings] && self.num_interior_rings > 0
          (0..(self.num_interior_rings) - 1).to_a.each do |n|
            ret[:polylines] << {
              :points => self.interior_ring_n(n).coord_seq.to_a
            }
          end
        end
        ret
      end
    end

    # Options:
    #
    # * :interior_rings - whether to include any interior rings in the output.
    #   The default is true.
    def to_geojsonable(options = {})
      options = {
        :interior_rings => true
      }.merge(options)

      ret = {
        :type => 'Polygon',
        :coordinates => [ self.exterior_ring.coord_seq.to_a ]
      }

      if options[:interior_rings] && self.num_interior_rings > 0
        ret[:coordinates].concat self.interior_rings.collect { |r|
          r.coord_seq.to_a
        }
      end

      ret
    end
  end
end

