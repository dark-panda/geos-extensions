
module Geos
  module GoogleMaps
    autoload :PolylineEncoder, File.join(GEOS_EXTENSIONS_BASE, *%w{ geos google_maps polyline_encoder })
  end
end
