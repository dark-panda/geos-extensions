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
  end
end

