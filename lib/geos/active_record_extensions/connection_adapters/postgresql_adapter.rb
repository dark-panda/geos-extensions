
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

    class PostgreSQLColumn
      def simplified_type_with_geometry_type(field_type)
        if field_type == 'geometry'
          :geometry
        else
          simplified_type_without_geometry_type(field_type)
        end
      end
      alias_method_chain :simplified_type, :geometry_type
    end

    class PostgreSQLAdapter
      # Returns the geometry columns for the table.
      def geometry_columns(table_name, name = nil)
        return [] if !table_exists?(table_name)

        columns(table_name, name).select { |c| c.sql_type == 'geometry' }.collect do |c|
          res = select_rows(
            "SELECT srid, coord_dimension FROM geometry_columns WHERE f_table_name = #{quote(table_name)} AND f_geometry_column = #{quote(c.name)}",
            "Geometry column load for #{table_name}"
          )

          PostgreSQLGeometryColumn.new(c.name).tap do |g|
            # since we're too stupid at the moment to understand
            # PostgreSQL schemas, let's just go with this:
            if res.length == 1
              g.srid, g.coord_dimension = res.first.collect(&:to_i)
            end
          end
        end
      end
    end
  end
end
