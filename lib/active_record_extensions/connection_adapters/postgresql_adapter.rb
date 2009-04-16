
module ActiveRecord
	module ConnectionAdapters
		class PostgreSQLColumn < Column
			attr_accessor :srid, :coord_dimensions
		end

		class PostgreSQLAdapter < AbstractAdapter
			# Returns the geometry columns for the table.
			def geometry_columns(table_name, name = nil)
				columns_with_geometry_detection(table_name, name).select do |c|
					c.type == :geometry
				end
			end

			def columns_with_geometry_detection(table_name, name = nil)
				columns = columns_without_geometry_detection(table_name, name)
				columns.each do |c|
					if c.type == :geometry
						res = execute(
							"SELECT * FROM geometry_columns WHERE f_table_name = #{quote(table_name)} AND f_geometry_column = #{quote(c.name)}",
							"Geometry column load for #{table_name}"
						)

						# since we're too stupid at the moment to understand
						# PostgreSQL schemas, let's just go with this:
						if res.ntuples == 1
							geometry_column_idx, coord_dimension_idx, srid_idx =
								res.fields.index('f_geometry_column'),
								res.fields.index('coord_dimension'),
								res.fields.index('srid')
							c.srid = res.getvalue(0, srid_idx).to_i
							c.coord_dimensions = res.getvalue(0, coord_dimension_idx).to_i
						end
					end
				end
				columns
			end
			alias_method_chain :columns, :geometry_detection
		end
	end
end
