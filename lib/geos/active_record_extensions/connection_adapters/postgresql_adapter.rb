
module ActiveRecord
  module ConnectionAdapters
    # Allows access to the name, srid and coord_dimensions of a PostGIS
    # geometry column in PostgreSQL.
    class PostgreSQLSpatialColumn
      attr_accessor :name, :srid, :coord_dimension, :spatial_type

      def initialize(name, options = {})
        options = {
          :srid => nil,
          :coord_dimension => nil,
          :spatial_type => :geometry
        }.merge(options)

        @name = name
        @srid = options[:srid]
        @coord_dimension = options[:coord_dimension]
        @spatial_type = options[:spatial_type]
      end
    end

    class PostgreSQLColumn
      def simplified_type_with_spatial_type(field_type)
        if field_type =~ /^geometry(\(|$)/
          :geometry
        elsif field_type =~ /^geography(\(|$)/
          :geography
        else
          simplified_type_without_spatial_type(field_type)
        end
      end
      alias_method_chain :simplified_type, :spatial_type
    end

    class PostgreSQLAdapter
      def geometry_columns?
        true
      end

      def geography_columns?
        Geos::ActiveRecord.POSTGIS[:lib] >= '1.5'
      end

      # Returns the geometry columns for the table.
      def geometry_columns(table_name, name = nil)
        return [] if !geometry_columns? ||
          !table_exists?(table_name)

        columns(table_name, name).select { |c| c.type == :geometry }.collect do |c|
          res = select_rows(
            "SELECT srid, coord_dimension FROM geometry_columns WHERE f_table_name = #{quote(table_name)} AND f_geometry_column = #{quote(c.name)}",
            "Geometry column load for #{table_name}"
          )

          PostgreSQLSpatialColumn.new(c.name).tap do |g|
            # since we're too stupid at the moment to understand
            # PostgreSQL schemas, let's just go with this:
            if res.length == 1
              g.srid, g.coord_dimension = res.first.collect(&:to_i)
            end
          end
        end
      end

      # Returns the geography columns for the table.
      def geography_columns(table_name, name = nil)
        return [] if !geography_columns? ||
          !table_exists?(table_name)

        columns(table_name, name).select { |c| c.type == :geography }.collect do |c|
          res = select_rows(
            "SELECT srid, coord_dimension FROM geography_columns WHERE f_table_name = #{quote(table_name)} AND f_geography_column = #{quote(c.name)}",
            "Geography column load for #{table_name}"
          )

          PostgreSQLSpatialColumn.new(c.name, :spatial_type => :geography).tap do |g|
            # since we're too stupid at the moment to understand
            # PostgreSQL schemas, let's just go with this:
            if res.length == 1
              g.srid, g.coord_dimension = res.first.collect { |value|
                value.try(:to_i)
              }
            end
          end
        end
      end

      # Returns both the geometry and geography columns for the table.
      def spatial_columns(table_name, name = nil)
        geometry_columns(table_name, name) +
          geography_columns(table_name, name)
      end
    end

    # Alias for backwards compatibility:
    PostgreSQLGeometryColumn = PostgreSQLSpatialColumn
  end
end

module Geos
  module ActiveRecord
    def self.POSTGIS
      return @POSTGIS if defined?(@POSTGIS)

      @POSTGIS = if (version_string = ::ActiveRecord::Base.connection.select_rows("SELECT postgis_full_version()").flatten.first).present?
        hash = {
          :use_stats => version_string =~ /USE_STATS/
        }

        {
          :lib => /POSTGIS="([^"]+)"/,
          :geos => /GEOS="([^"]+)"/,
          :proj => /PROJ="([^"]+)"/,
          :libxml => /LIBXML="([^"]+)"/
        }.each do |k, v|
          hash[k] = version_string.scan(v).flatten.first
        end

        hash.freeze
      else
        {}.freeze
      end
    end
  end
end

