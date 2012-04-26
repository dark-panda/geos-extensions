
require File.join(Geos::GEOS_EXTENSIONS_BASE, *%w{ geos active_record_extensions connection_adapters postgresql_adapter })

module Geos
  module ActiveRecord
    autoload :SpatialColumns, File.join(Geos::GEOS_EXTENSIONS_BASE, %w{ geos active_record_extensions spatial_columns })
    autoload :GeometryColumns, File.join(Geos::GEOS_EXTENSIONS_BASE, %w{ geos active_record_extensions spatial_columns })
    autoload :SpatialScopes, File.join(Geos::GEOS_EXTENSIONS_BASE, %w{ geos active_record_extensions spatial_scopes })
    autoload :GeospatialScopes, File.join(Geos::GEOS_EXTENSIONS_BASE, %w{ geos active_record_extensions spatial_scopes })
  end
end

