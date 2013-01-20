# encoding: UTF-8

# This file adds yaml serialization support to geometries.  The generated yaml
# has this format:
#
#    !ruby/object:Geos::Geometry
#    wkt: POINT (-104.97 39.71)
#    srid: 4326
#
#  So to use this in a rails fixture file you could do something like this:
#
#    geometry_1:
#      id: 1
#      geom: !ruby/object:Geos::Geometry
#        wkt: POINT (-104.97 39.71)
#        srid: 4326
#
# Note this code assumes the use of Psych (not syck) and ruby 1.9 and higher

require 'yaml'

if YAML.const_defined?('ENGINE') && YAML::ENGINE.yamler = 'psych'
  require File.join(File.dirname(__FILE__), 'yaml_psych')
else
  require File.join(File.dirname(__FILE__), 'yaml_syck')
end

