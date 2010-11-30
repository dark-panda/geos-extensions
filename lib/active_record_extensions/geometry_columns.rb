
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
	require File.join(GEOS_BASE, *%w{ active_record_extensions connection_adapters postgresql_adapter })
end

module Geos
	module ActiveRecord #:nodoc:

		# This little module helps us out with geometry columns. At least, in
		# PostgreSQL it does.
		#
		# This module will add a method called geometry_columns to your model
		# which will contain information that can be gleaned from the
		# geometry_columns table that PostGIS creates.
		#
		# You can also have the module automagically create some accessor
		# methods for you to make your life easier. These accessor methods will
		# override the ActiveRecord defaults and allow you to set geometry
		# column values using Geos geometry objects directly or with
		# PostGIS-style extended WKT and such. See
		# create_geometry_column_accessors! for details.
		#
		# === Caveats:
		#
		# * This module currently only works with PostGIS.
		# * This module doesn't really "get" PostgreSQL catalogs and schemas
		#   and such. That would be a little more involved but it would be
		#   nice if Rails was aware of such things.
		module GeometryColumns
			GEOMETRY_COLUMN_OUTPUT_FORMATS = [ :geos, :wkt, :wkb, :ewkt, :ewkb, :wkb_bin, :ewkb_bin ].freeze

			class InvalidGeometry < ::ActiveRecord::ActiveRecordError
				def initialize(geom)
					super("Invalid geometry: #{geom}")
				end
			end

			class SRIDNotFound < ::ActiveRecord::ActiveRecordError
				def initialize(table_name, column)
					super("Couldn't find SRID for #{table_name}.#{column}")
				end
			end

			def self.included(base) #:nodoc:
				base.extend(ClassMethods)
				base.send(:include, Geos::ActiveRecord::GeospatialScopes)
			end

			module ClassMethods
				protected
					@geometry_columns = nil

				public
					# Returns an Array of available geometry columns in the
					# table. These are PostgreSQLColumns with values set for
					# the srid and coord_dimensions properties.
					def geometry_columns
						if @geometry_columns.nil?
							@geometry_columns = connection.geometry_columns(self.table_name)
							@geometry_columns.freeze
						end
						@geometry_columns
					end

					# Grabs a geometry column based on name.
					def geometry_column_by_name(name)
						@geometry_column_by_name ||= self.geometry_columns.inject(HashWithIndifferentAccess.new) do |memo, obj|
							memo[obj.name] = obj
							memo
						end
						@geometry_column_by_name[name]
					end

					# Quickly grab the SRID for a geometry column.
					def srid_for(column)
						self.geometry_column_by_name(column).try(:srid) || -1
					end

					# Quickly grab the number of dimensions for a geometry column.
					def coord_dimension_for(column)
						self.geometry_column_by_name(column).coord_dimension
					end

				protected
					# Sets up nifty setters and getters for geometry columns.
					# The methods created look like this:
					#
					# * geometry_column_name_geos
					# * geometry_column_name_wkb
					# * geometry_column_name_wkb_bin
					# * geometry_column_name_wkt
					# * geometry_column_name_ewkb
					# * geometry_column_name_ewkb_bin
					# * geometry_column_name_ewkt
					# * geometry_column_name=(geom)
					# * geometry_column_name(options = {})
					#
					# Where "geometry_column_name" is the name of the actual
					# column.
					#
					# You can specify which geometry columns you want to apply
					# these accessors using the :only and :except options.
					def create_geometry_column_accessors!(options = nil)
						create_these = if options.nil?
							self.geometry_columns
						elsif options[:except] && options[:only]
							raise ArgumentError, "You can only specify either :except or :only (#{options.keys.inspect})"
						elsif options[:except]
							except = Array(options[:except])
							self.geometry_columns.reject { |c| except.include?(c.to_sym) }
						elsif options[:only]
							only = Array(options[:only])
							self.geometry_columns.select { |c| only.include?(c.to_sym) }
						end

						create_these.each do |k|
							src, line = <<-EOF, __LINE__ + 1
								def #{k.name}=(geom)
									geos = case geom
										when /^SRID=default;/
											if #{k.srid.inspect}
												geom = geom.sub(/default/, #{k.srid.inspect}.to_s)
												Geos.from_wkt(geom)
											else
												raise SRIDNotFound.new(self.table_name, #{k.name})
											end
										else
											Geos.read(geom)
									end

									self['#{k.name}'] = if geos
										if geos.srid == 0
											geos.to_wkb
										else
											geos.to_ewkb
										end
									end

									GEOMETRY_COLUMN_OUTPUT_FORMATS.each do |f|
										instance_variable_set("@#{k.name}_\#{f}", nil)
									end
								end

								def #{k.name}_geos
									@#{k.name}_geos ||= Geos.from_wkb(self['#{k.name}'])
								end

								def #{k.name}(options = {})
									case options
										when String, Symbol
											if GEOMETRY_COLUMN_OUTPUT_FORMATS.include?(options.to_sym)
												return self.send(:"#{k.name}_\#{options}")
											else
												raise ArgumentError, "Invalid option: \#{options}"
											end
										when Hash
											options = options.symbolize_keys
											if options[:format]
												if GEOMETRY_COLUMN_OUTPUT_FORMATS.include?(options[:format])
													return self.send(:"#{k.name}_\#{options[:format]}")
												else
													raise ArgumentError, "Invalid option: \#{options[:format]}"
												end
											end
									end
									self['#{k.name}']
								end
							EOF
							self.class_eval(src, __FILE__, line)

							GEOMETRY_COLUMN_OUTPUT_FORMATS.reject { |f| f == :geos }.each do |f|
								src, line = <<-EOF, __LINE__ + 1
									def #{k.name}_#{f}
										@#{k.name}_#{f} ||= self.#{k.name}_geos.to_#{f} rescue nil
									end
								EOF
								self.class_eval(src, __FILE__, line)
							end
						end
					end

					# Stubs for documentation purposes:

					# Returns a Geos geometry.
					def __geometry_column_name_geos; end

					# Returns a hex-encoded WKB String.
					def __geometry_column_name_wkb; end

					# Returns a WKB String in binary.
					def __geometry_column_name_wkb_bin; end

					# Returns a WKT String.
					def __geometry_column_name_wkt; end

					# Returns a hex-encoded EWKB String.
					def __geometry_column_name_ewkb; end

					# Returns an EWKB String in binary.
					def __geometry_column_name_ewkb_bin; end

					# Returns an EWKT String.
					def __geometry_column_name_ewkt; end

					# An enhanced setter that tries to deduce how you're
					# setting the value. The setter can handle Geos::Geometry
					# objects, WKT, EWKT and WKB and EWKB in both hex and
					# binary.
					#
					# When dealing with SRIDs, you can have the SRID set
					# automatically on WKT by setting the value as
					# "SRID=default;GEOMETRY(...)", i.e.:
					#
					#	geometry_column_name = "SRID=default;POINT(1.0 1.0)"
					#
					# The SRID will be filled in automatically if available.
					# Note that we're only setting the SRID on the geometry,
					# but we're not doing any sort of re-projection or anything
					# of the sort. If you need to convert from one SRID to
					# another, you're stuck for the moment, but we'll be adding
					# support for reprojections/transoformations via proj4rb
					# soon.
					#
					# For WKB, you're better off manipulating the WKB directly
					# or using proper Geos geometry objects.
					def __geometry_column_name=(geom); end

					# An enhanced getter that accepts an options Hash or
					# String/Symbol that can be used to determine the output
					# format. In the options Hash, use :format, or set the
					# format directly as a String or Symbol.
					#
					# This basically allows you to do the following, which
					# are equivalent:
					#
					#	geometry_column_name(:wkt)
					#	geometry_column_name(:format => :wkt)
					#	geometry_column_name_wkt
					def __geometry_column_name(options = {}); end

					undef __geometry_column_name_geos
					undef __geometry_column_name_wkb
					undef __geometry_column_name_wkb_bin
					undef __geometry_column_name_wkt
					undef __geometry_column_name_ewkb
					undef __geometry_column_name_ewkb_bin
					undef __geometry_column_name_ewkt
					undef __geometry_column_name=
					undef __geometry_column_name
			end
		end
	end
end
