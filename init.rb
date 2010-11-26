
require 'geos'
require File.join(File.dirname(__FILE__), 'lib', 'geos_extensions')

if defined?(Rails)
	require File.join(File.dirname(__FILE__), 'lib', 'active_record_extensions', 'connection_adapters', 'postgresql_adapter')
	require File.join(File.dirname(__FILE__), 'lib', 'active_record_extensions', 'geometry_columns')
	require File.join(File.dirname(__FILE__), 'lib', 'active_record_extensions', 'geospatial_scopes')
end
