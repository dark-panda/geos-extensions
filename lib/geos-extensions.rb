
require File.join(File.dirname(__FILE__), *%w{ geos_extensions })

if defined?(ActiveRecord)
  require File.join(Geos::GEOS_EXTENSIONS_BASE, *%w{ geos active_record_extensions })
end

if defined?(Rails) && Rails::VERSION::MAJOR >= 3
  require File.join(Geos::GEOS_EXTENSIONS_BASE, %w{ geos rails engine })
end

Geos::GoogleMaps.use_api(2)

