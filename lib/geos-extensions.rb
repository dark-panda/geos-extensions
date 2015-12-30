# encoding: UTF-8
# frozen_string_literal: true

require File.join(File.dirname(__FILE__), *%w{ geos_extensions })

Geos::GoogleMaps.use_api(3)

module Geos
  class InvalidGeometryError < Geos::Error
  end
end
