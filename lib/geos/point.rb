# encoding: UTF-8
# frozen_string_literal: true

module Geos
  class Point
    unless method_defined?(:y)
      # Returns the Y coordinate of the Point.
      def y
        self.to_a[1]
      end
    end

    %w{
      latitude lat north south n s
    }.each do |name|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        alias_method :#{name}, :y
      EOF
    end

    unless method_defined?(:x)
      # Returns the X coordinate of the Point.
      def x
        self.to_a[0]
      end
    end

    %w{
      longitude lng east west e w
    }.each do |name|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        alias_method :#{name}, :x
      EOF
    end

    unless method_defined?(:z)
      # Returns the Z coordinate of the Point.
      def z
        if self.has_z?
          self.to_a[2]
        else
          nil
        end
      end
    end

    # Returns the Point's coordinates as an Array in the following format:
    #
    #  [ x, y, z ]
    #
    # The Z coordinate will only be present for Points which have a Z
    # dimension.
    def to_a
      if defined?(@to_a)
        @to_a
      else
        cs = self.coord_seq
        @to_a = if self.has_z?
          [ cs.get_x(0), cs.get_y(0), cs.get_z(0) ]
        else
          [ cs.get_x(0), cs.get_y(0) ]
        end
      end
    end

    # Optimize some unnecessary code away:
    %w{
      upper_left upper_right lower_right lower_left
      ne nw se sw
      northwest northeast southeast southwest
    }.each do |name|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def #{name}
          self
        end
      EOF
    end

    # Build some XmlMarkup for KML. You can set KML options for extrude and
    # altitudeMode. Use Rails/Ruby-style code and it will be converted
    # appropriately, i.e. :altitude_mode, not :altitudeMode.
    def to_kml(*args)
      xml, options = Geos::Helper.xml_options(*args)
      xml.Point(:id => options[:id]) do
        xml.extrude(options[:extrude]) if options[:extrude]
        xml.altitudeMode(Geos::Helper.camelize(options[:altitude_mode])) if options[:altitude_mode]
        xml.coordinates(self.to_a.join(','))
      end
    end

    # Build some XmlMarkup for GeoRSS. You should include the
    # appropriate georss and gml XML namespaces in your document.
    def to_georss(*args)
      xml = Geos::Helper.xml_options(*args)[0]
      xml.georss(:where) do
        xml.gml(:Point) do
          xml.gml(:pos, "#{self.lat} #{self.lng}")
        end
      end
    end

    # Returns a Hash suitable for converting to JSON.
    def as_json(options = {})
      cs = self.coord_seq
      if self.has_z?
        { :type => 'point', :lat => cs.get_y(0), :lng => cs.get_x(0), :z => cs.get_z(0) }
      else
        { :type => 'point', :lat => cs.get_y(0), :lng => cs.get_x(0) }
      end
    end
    alias_method :to_jsonable, :as_json

    def as_geojson(options = {})
      {
        :type => 'Point',
        :coordinates => self.to_a
      }
    end
    alias_method :to_geojsonable, :as_geojson

    # Dumps points similarly to the PostGIS `ST_DumpPoints` function.
    def dump_points(cur_path = [])
      cur_path.push(self.dup)
    end

    %w{ max min }.each do |op|
      %w{ x y }.each do |dimension|
        self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def #{dimension}_#{op}
            unless self.empty?
              self.#{dimension}
            end
          end
        EOF
      end

      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def z_#{op}
          unless self.empty?
            if self.has_z?
              self.z
            else
              0
            end
          end
        end
      EOF
    end
  end
end

