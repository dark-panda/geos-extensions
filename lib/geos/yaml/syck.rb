# encoding: UTF-8
# frozen_string_literal: true

module Geos
  class Geometry
    yaml_as "tag:ruby.yaml.org,2002:object:Geos::Geometry"

    def taguri
      "tag:ruby.yaml.org,2002:object:#{self.class.name}"
    end

    def self.yaml_new(klass, tag, val)
      Geos.read(val['geom'])
    end

    def to_yaml( opts = {} )
      YAML::quick_emit(self.object_id, opts) do |out|
        out.map(taguri) do |map|
          map.add('geom', self.to_ewkt(
            :include_srid => self.srid != 0
          ))
        end
      end
    end
  end

  class Point
    yaml_as "tag:ruby.yaml.org,2002:object:Geos::Point"
  end

  class LineString
    yaml_as "tag:ruby.yaml.org,2002:object:Geos::LineString"
  end

  class Polygon
    yaml_as "tag:ruby.yaml.org,2002:object:Geos::Polygon"
  end

  class GeometryCollection
    yaml_as "tag:ruby.yaml.org,2002:object:Geos::GeometryCollection"
  end
end