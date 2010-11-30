
module ActiveRecord
	module ConnectionAdapters
		# Allows access to the name, srid and coord_dimensions of a PostGIS
		# geometry column in PostgreSQL.
		class PostgreSQLGeometryColumn
			attr_accessor :name, :srid, :coord_dimension

			def initialize(name, srid = nil, coord_dimension = nil)
				@name, @srid, @coord_dimension = name, srid, coord_dimension
			end
		end

		class PostgreSQLAdapter < AbstractAdapter
			# Returns the geometry columns for the table.
			def geometry_columns(table_name, name = nil)
				columns(table_name, name).select { |c| c.sql_type == 'geometry' }.collect do |c|
					res = execute(
						"SELECT * FROM geometry_columns WHERE f_table_name = #{quote(table_name)} AND f_geometry_column = #{quote(c.name)}",
						"Geometry column load for #{table_name}"
					)

					returning(PostgreSQLGeometryColumn.new(c.name)) do |g|
						# since we're too stupid at the moment to understand
						# PostgreSQL schemas, let's just go with this:
						if res.ntuples == 1
							coord_dimension_idx, srid_idx =
								res.fields.index('coord_dimension'),
								res.fields.index('srid')

							g.srid = res.getvalue(0, srid_idx).to_i
							g.coord_dimension = res.getvalue(0, coord_dimension_idx).to_i
						end
					end
				end
			end
		end
	end
end
