
require File.join(Geos::GEOS_EXTENSIONS_BASE, *%w{ geos active_record_extensions connection_adapters postgresql_adapter })

module Geos
  module ActiveRecord
    autoload :GeometryColumns, File.join(Geos::GEOS_EXTENSIONS_BASE, %w{ geos active_record_extensions geometry_columns })
    autoload :GeospatialScopes, File.join(Geos::GEOS_EXTENSIONS_BASE, %w{ geos active_record_extensions geospatial_scopes })
  end
end

