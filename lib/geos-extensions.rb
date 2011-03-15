
require File.join(File.dirname(__FILE__), *%w{ geos_extensions })

if defined?(ActiveRecord)
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ active_record_extensions connection_adapters postgresql_adapter })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ active_record_extensions geometry_columns })
  require File.join(GEOS_EXTENSIONS_BASE, *%w{ active_record_extensions geospatial_scopes })
end

if defined?(Rails)
  require File.join(File.dirname(__FILE__), %w{ .. rails railtie })
end

