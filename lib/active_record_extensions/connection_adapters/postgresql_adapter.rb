
module ActiveRecord
	module ConnectionAdapters
		class PostgreSQLAdapter < AbstractAdapter
			# Returns the geometry columns for the table.
			def geometry_columns(table_name)
				returning(HashWithIndifferentAccess.new) do |ret|
					res = execute(
						"SELECT * FROM geometry_columns WHERE f_table_name = #{quote(table_name)}",
						"Geometry column load for #{table_name}"
					)
					if res.ntuples > 0
						geometry_column_idx, coord_dimension_idx, srid_idx =
							res.fields.index('f_geometry_column'),
							res.fields.index('coord_dimension'),
							res.fields.index('srid')

						res.ntuples.times do |i|
							ret[res.getvalue(i, geometry_column_idx)] =
								Struct.new(:srid, :coord_dimension).new(
									res.getvalue(i, srid_idx).to_i,
									res.getvalue(i, coord_dimension_idx).to_i
								)
						end
					end
				end
			end
		end
	end
end
