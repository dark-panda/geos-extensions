# encoding: UTF-8
# frozen_string_literal: true

module Geos
  class LineString
    def as_json(options = {})
      self.coord_seq.as_json(options)
    end
    alias_method :to_jsonable, :as_json

    def as_geojson(options = {})
      self.coord_seq.to_geojsonable(options)
    end
    alias_method :to_geojsonable, :as_geojson

    # Dumps points similarly to the PostGIS `ST_DumpPoints` function.
    def dump_points(cur_path = [])
      cur_path.concat(self.to_a)
    end

    %w{ max min }.each do |op|
      %w{ x y }.each do |dimension|
        self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def #{dimension}_#{op}
            unless self.empty?
              self.coord_seq.#{dimension}_#{op}
            end
          end
        EOF
      end

      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def z_#{op}
          unless self.empty?
            if self.has_z?
              self.coord_seq.z_#{op}
            else
              0
            end
          end
        end
      EOF
    end

    def snap_to_grid!(*args)
      if !self.empty?
        cs = self.coord_seq.snap_to_grid!(*args)

        if cs.length == 0
          @ptr = Geos.create_empty_line_string(:srid => self.srid).ptr
        elsif cs.length <= 1
          raise Geos::InvalidGeometryError.new("snap_to_grid! produced an invalid number of points in for a LineString - found #{cs.length} - must be 0 or > 1")
        else
          @ptr = Geos.create_line_string(cs).ptr
        end
      end

      self
    end

    def snap_to_grid(*args)
      ret = self.dup.snap_to_grid!(*args)
      ret.srid = pick_srid_according_to_policy(self.srid)
      ret
    end

    def line_interpolate_point(fraction)
      if !fraction.between?(0, 1)
        raise ArgumentError.new("fraction must be between 0 and 1")
      end

      case fraction
        when 0
          self.start_point
        when 1
          self.end_point
        else
          length = self.length
          total_length = 0
          segs = self.num_points - 1

          segs.times do |i|
            p1 = self[i]
            p2 = self[i + 1]

            seg_length = p1.distance(p2) / length

            if fraction < total_length + seg_length
              dseg = (fraction - total_length) / seg_length

              args = []
              args << p1.x + ((p2.x - p1.x) * dseg)
              args << p1.y + ((p2.y - p1.y) * dseg)
              args << p1.z + ((p2.z - p1.z) * dseg) if self.has_z?

              args << { :srid => pick_srid_according_to_policy(self.srid) } unless self.srid == 0

              return Geos.create_point(*args)
            end

            total_length += seg_length
          end

          # if all else fails...
          self.end_point
      end
    end
    alias_method :interpolate_point, :line_interpolate_point

    %w{
      affine
      rotate
      rotate_x
      rotate_y
      rotate_z
      scale
      trans_scale
      translate
    }.each do |m|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def #{m}!(*args)
          unless self.empty?
            self.coord_seq.#{m}!(*args)
          end

          self
        end

        def #{m}(*args)
          ret = self.dup.#{m}!(*args)
          ret.srid = pick_srid_according_to_policy(self.srid)
          ret
        end
      EOF
    end
  end
end

