# encoding: UTF-8
# frozen_string_literal: true

# This file adds yaml serialization support to geometries.  The generated yaml
# has this format:
#
#    !ruby/object:Geos::Geometry
#    geom: SRID=4326; POINT (-104.97 39.71)
#
#  So to use this in a rails fixture file you could do something like this:
#
#    geometry_1:
#      id: 1
#      geom: !ruby/object:Geos::Geometry
#        geom: SRID=4326; POINT (-104.97 39.71)
#
# Note this code assumes the use of Psych (not syck) and ruby 1.9 and higher

require 'yaml'

dirname = File.join(File.dirname(__FILE__), 'yaml')

# Ruby 2.0 check
if Object.const_defined?(:Psych) && YAML == Psych
  require File.join(dirname, 'psych')
# Ruby 1.9 check
elsif YAML.const_defined?('ENGINE') && YAML::ENGINE.yamler = 'psych'
  require File.join(dirname, 'psych')
else
  require File.join(dirname, 'syck')
end
