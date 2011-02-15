
module Geos
  module ActiveRecord
    autoload :GeometryColumns, File.join(GEOS_EXTENSIONS_BASE, %w{ active_record_extensions geometry_columns })
    autoload :GeospatialScopes, File.join(GEOS_EXTENSIONS_BASE, %w{ active_record_extensions geospatial_scopes })
  end
end

