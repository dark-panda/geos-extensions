
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
		# PostGIS-style extended WKT and such. See create_geospatial_accessors!
		# for details.
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

			def self.included(base) #:nodoc:
				base.extend(ClassMethods)
			end

			module ClassMethods
				protected
					@geometry_columns = nil

				public
					# Returns a list of available geometry columns in the
					# table.
					#
					# === Examples:
					#
					#	SomeTable.geometry_columns
					#	# => { "the_geom"=>#<struct #<Class:0xaaac440> srid=4326, coord_dimension=2>}
					#	SomeTable.geometry_columns[:the_geom].srid
					#	# => 4326
					def geometry_columns
						if @geometry_columns.nil?
							@geometry_columns = connection.geometry_columns(self.table_name)
							@geometry_columns.freeze
						end
						@geometry_columns
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
					def create_geospatial_accessors!(options = nil)
						create_these = if options.nil?
							self.geometry_columns.keys
						elsif options[:except] && options[:only]
							raise ArgumentError, "You can only specify either :except or :only (#{options.keys.inspect})"
						elsif options[:except]
							except = Array(options[:except])
							self.geometry_columns.keys.reject { |c| except.include?(c.to_sym) }
						elsif options[:only]
							only = Array(options[:only])
							self.geometry_columns.keys.select { |c| only.include?(c.to_sym) }
						end

						create_these.each do |k|
							self.class_eval <<-EOF
								def #{k}=(geom)
									self["#{k}"] = case geom
										when Geos::Geometry
											geom.to_ewkb
										when /^SRID=[0-9]+;/
											Geos.from_wkt(geom).to_ewkb
										when /^SRID=default;/
											geom = geom.sub(/default/, self.class.geometry_columns[:#{k}].srid.to_s)
											Geos.from_wkt(geom).to_ewkb
										when /^[PLMCG]/
											Geos.from_wkt(geom).to_wkb
										when /^[A-Fa-f0-9]+$/
											geom
										else
											geom.unpack('H*').first.upcase
									end

									GEOMETRY_COLUMN_OUTPUT_FORMATS.each do |f|
										@#{k}_\#{f} = nil
									end
								end

								def #{k}_geos
									@#{k}_geos ||= Geos.from_wkb(self['#{k}'])
								end

								def #{k}(options = {})
									case options
										when String, Symbol
											if GEOMETRY_COLUMN_OUTPUT_FORMATS.include?(options.to_sym)
												return self.send(:"#{k}_\#{options}")
											else
												raise ArgumentError, "Invalid option: \#{options}"
											end
										when Hash
											options = options.symbolize_keys
											if options[:format]
												if GEOMETRY_COLUMN_OUTPUT_FORMATS.include?(options[:format])
													return self.send(:"#{k}_\#{options[:format]}")
												else
													raise ArgumentError, "Invalid option: \#{options[:format]}"
												end
											end
									end
									self['#{k}']
								end
							EOF

							GEOMETRY_COLUMN_OUTPUT_FORMATS.reject { |f| f == :geos }.each do |f|
								self.class_eval <<-EOF
									def #{k}_#{f}
										@#{k}_#{f} ||= self.#{k}_geos.to_#{f}
									end
								EOF
							end
						end
					end

					# Stubs for documentation purposes:

					# Returns a Geos geometry.
					def geometry_column_name_geos; end

					# Returns a hex-encoded WKB String.
					def geometry_column_name_wkb; end

					# Returns a WKB String in binary.
					def geometry_column_name_wkb_bin; end

					# Returns a WKT String.
					def geometry_column_name_wkt; end

					# Returns a hex-encoded EWKB String.
					def geometry_column_name_ewkb; end

					# Returns an EWKB String in binary.
					def geometry_column_name_ewkb_bin; end

					# Returns an EWKT String.
					def geometry_column_name_ewkt; end

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
					def geometry_column_name=(geom); end

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
					def geometry_column_name(options = {}); end

					undef geometry_column_name_geos
					undef geometry_column_name_wkb
					undef geometry_column_name_wkb_bin
					undef geometry_column_name_wkt
					undef geometry_column_name_ewkb
					undef geometry_column_name_ewkb_bin
					undef geometry_column_name_ewkt
					undef geometry_column_name=
					undef geometry_column_name
			end
		end
	end
end
