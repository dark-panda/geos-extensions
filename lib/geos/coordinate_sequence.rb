# encoding: UTF-8
# frozen_string_literal: true

module Geos
  class CoordinateSequence
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
    alias_method :to_jsonable, :as_json

    def as_geojson(options = {})
      {
        :type => 'LineString',
        :coordinates => self.to_a
      }
    end
    alias_method :to_geojsonable, :as_geojson

    def to_geojson(options = {})
      self.to_geojsonable(options).to_json
    end

    %w{ x y z }.each do |m|
      class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def #{m}_max
          ret = nil
          self.length.times do |i|
            value = self.get_#{m}(i)
            ret = value if !ret || value >= ret
          end
          ret
        end

        def #{m}_min
          ret = nil
          self.length.times do |i|
            value = self.get_#{m}(i)
            ret = value if !ret || value <= ret
          end
          ret
        end
      EOF
    end

    def snap_to_grid!(*args)
      grid = {
        :offset_x => 0, # 1
        :offset_y => 0, # 2
        :offset_z => 0, # -
        :size_x => 0, # 3
        :size_y => 0, # 4
        :size_z => 0 # -
      }

      if args.length == 1 && args[0].is_a?(Numeric)
        grid[:size_x] = grid[:size_y] = grid[:size_z] = args[0]
      elsif args[0].is_a?(Hash)
        grid.merge!(args[0])
      end

      if grid[:size]
        grid[:size_x] = grid[:size_y] = grid[:size_z] = grid[:size]
      end

      if grid[:offset]
        case grid[:offset]
          when Geos::Geometry
            point = grid[:offset].centroid

            grid[:offset_x] = point.x
            grid[:offset_y] = point.y
            grid[:offset_z] = point.z
          when Array
            grid[:offset_x], grid[:offset_y], grid[:offset_z] = grid[:offset]
          else
            raise ArgumentError.new("Expected :offset option to be a Geos::Point")
        end
      end

      self.length.times do |i|
        if grid[:size_x] != 0
          self.x[i] = ((self.x[i] - grid[:offset_x]) / grid[:size_x]).round * grid[:size_x] + grid[:offset_x]
        end

        if grid[:size_y] != 0
          self.y[i] = ((self.y[i] - grid[:offset_y]) / grid[:size_y]).round * grid[:size_y] + grid[:offset_y]
        end

        if self.has_z? && grid[:size_z] != 0
          self.z[i] = ((self.z[i] - grid[:offset_z]) / grid[:size_z]).round * grid[:size_z] + grid[:offset_z]
        end
      end

      cs = self.remove_duplicate_coords
      @ptr = cs.ptr

      self
    end

    def snap_to_grid(*args)
      self.dup.snap_to_grid!(*args)
    end

    def remove_duplicate_coords
      Geos::CoordinateSequence.new(self.to_a.inject([]) { |memo, v|
        memo << v unless memo.last == v
        memo
      })
    end

    def affine!(options)
      options.default = 0.0

      if self.has_z?
        self.length.times do |i|
          x, y, z = self.x[i], self.y[i], self.z[i]

          self.x[i] = options[:afac] * x + options[:bfac] * y + options[:cfac] * z + options[:xoff]
          self.y[i] = options[:dfac] * x + options[:efac] * y + options[:ffac] * z + options[:yoff]
          self.z[i] = options[:gfac] * x + options[:hfac] * y + options[:ifac] * z + options[:zoff]
        end
      else
        self.length.times do |i|
          x, y = self.x[i], self.y[i]

          self.x[i] = options[:afac] * x + options[:bfac] * y + options[:xoff]
          self.y[i] = options[:dfac] * x + options[:efac] * y + options[:yoff]
        end
      end

      self
    end

    def affine(options)
      self.dup.affine!(options)
    end

    def rotate!(radians, origin = [ 0.0, 0.0 ])
      origin = case origin
        when Array
          origin
        when Geos::Geometry
          center = origin.centroid
          [ center.x, center.y ]
        else
          raise ArgumentError.new("Expected an Array or a Geos::Geometry for the origin")
      end

      self.affine!({
        :afac => Math.cos(radians),
        :bfac => -Math.sin(radians),
        :cfac => 0,
        :dfac => Math.sin(radians),
        :efac => Math.cos(radians),
        :ffac => 0,
        :gfac => 0,
        :hfac => 0,
        :ifac => 1,
        :xoff => origin[0] - Math.cos(radians) * origin[0] + Math.sin(radians) * origin[1],
        :yoff => origin[1] - Math.sin(radians) * origin[0] - Math.cos(radians) * origin[1],
        :zoff => 0
      })
    end

    def rotate(radians, origin = [ 0.0, 0.0 ])
      self.dup.rotate!(radians, origin)
    end

    def rotate_x!(radians)
      self.affine!({
        :afac => 1,
        :bfac => 0,
        :cfac => 0,
        :dfac => 0,
        :efac => Math.cos(radians),
        :ffac => -Math.sin(radians),
        :gfac => 0,
        :hfac => Math.sin(radians),
        :ifac => Math.cos(radians),
        :xoff => 0,
        :yoff => 0,
        :zoff => 0
      })
    end

    def rotate_x(radians)
      self.dup.rotate_x!(radians)
    end

    def rotate_y!(radians)
      self.affine!({
        :afac => Math.cos(radians),
        :bfac => 0,
        :cfac => Math.sin(radians),
        :dfac => 0,
        :efac => 1,
        :ffac => 0,
        :gfac => -Math.sin(radians),
        :hfac => 0,
        :ifac => Math.cos(radians),
        :xoff => 0,
        :yoff => 0,
        :zoff => 0
      })
    end

    def rotate_y(radians)
      self.dup.rotate_y!(radians)
    end

    def rotate_z!(radians)
      self.rotate!(radians)
    end

    def rotate_z(radians)
      self.dup.rotate!(radians)
    end

    def scale!(*args)
      x, y, z = if args.length == 1 && args[0].is_a?(Hash)
        args[0].values_at(:x, :y, :z)
      elsif args.length.between?(1, 3)
        args.values_at(0...3)
      else
        raise ArgumentError.new("Wrong number of arguments #{args.length} for 1-3")
      end

      self.affine!({
        :afac => x || 1,
        :bfac => 0,
        :cfac => 0,
        :dfac => 0,
        :efac => y || 1,
        :ffac => 0,
        :gfac => 0,
        :hfac => 0,
        :ifac => z || 1,
        :xoff => 0,
        :yoff => 0,
        :zoff => 0
      })
    end

    def scale(*args)
      self.dup.scale!(*args)
    end

    def trans_scale!(*args)
      delta_x, delta_y, x_factor, y_factor = if args.length == 1 && args[0].is_a?(Hash)
        args[0].values_at(:delta_x, :delta_y, :x_factor, :y_factor)
      elsif args.length.between?(1, 4)
        args.values_at(0...4)
      else
        raise ArgumentError.new("Wrong number of arguments #{args.length} for 1-4")
      end

      x_factor ||= 1
      y_factor ||= 1
      delta_x ||= 0
      delta_y ||= 0

      self.affine!({
        :afac => x_factor,
        :bfac => 0,
        :cfac => 0,
        :dfac => 0,
        :efac => y_factor,
        :ffac => 0,
        :gfac => 0,
        :hfac => 0,
        :ifac => 1,
        :xoff => delta_x * x_factor,
        :yoff => delta_y * y_factor,
        :zoff => 0
      })
    end

    def trans_scale(*args)
      self.dup.trans_scale!(*args)
    end

    def translate!(*args)
      x, y, z = if args.length == 1 && args[0].is_a?(Hash)
        args[0].values_at(:x, :y, :z)
      elsif args.length.between?(1, 3)
        args.values_at(0...3)
      else
        raise ArgumentError.new("Wrong number of arguments #{args.length} for 1-3")
      end

      self.affine!({
        :afac => 1,
        :bfac => 0,
        :cfac => 0,
        :dfac => 0,
        :efac => 1,
        :ffac => 0,
        :gfac => 0,
        :hfac => 0,
        :ifac => 1,
        :xoff => x || 0,
        :yoff => y || 0,
        :zoff => z || 1
      })
    end

    def translate(*args)
      self.dup.translate!(*args)
    end
  end
end

