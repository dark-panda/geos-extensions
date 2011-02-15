
module Geos
  module ActiveRecord

    # Creates named scopes for geospatial relationships. The scopes created
    # follow the nine relationships established by the standard
    # Dimensionally Extended 9-Intersection Matrix functions plus a couple
    # of extra ones provided by PostGIS.
    #
    # Scopes provided are:
    #
    # * st_contains
    # * st_containsproperly
    # * st_covers
    # * st_coveredby
    # * st_crosses
    # * st_disjoint
    # * st_equals
    # * st_intersects
    # * st_orderingequals
    # * st_overlaps
    # * st_touches
    # * st_within
    # * st_dwithin
    #
    # The first argument to each method is can be a Geos::Geometry-based
    # object or anything readable by Geos.read along with an optional
    # options Hash.
    #
    # == Options
    #
    # * :column - the column to compare against. The default is 'the_geom'.
    # * :use_index - whether to use the "ST_" methods or the "\_ST_"
    #   variants which don't use indexes. The default is true.
    # * :wkb_options - in order to facilitate some conversions, geometries
    #   are converted to WKB. The default is `{:include_srid => true}` to
    #   force the geometry to use PostGIS's Extended WKB.
    #
    # == SRID Detection
    #
    # * if the geometry itself has an SRID, we'll compare it to the
    #   geometry of the column. If they differ, we'll use ST_Transform
    #   to transform the geometry to the proper SRID for comparison. If
    #   they're the same, no conversion is necessary.
    # * if no SRID is specified in the geometry, we'll use ST_SetSRID
    #   to set the SRID to the column's SRID.
    # * in cases where the column has been defined with an SRID of -1
    #   (PostGIS's default), no transformation is done, but we'll set the
    #   SRID of the geometry to -1 to perform the query using ST_SetSRID,
    #   as we'll assume the SRID of the column to be whatever the SRID of
    #   the geometry is.
    module GeospatialScopes
      SCOPE_METHOD = if Rails.version >= '3.0'
        'scope'
      else
        'named_scope'
      end

      RELATIONSHIPS = %w{
        contains
        containsproperly
        covers
        coveredby
        crosses
        disjoint
        equals
        intersects
        orderingequals
        overlaps
        touches
        within
      }.freeze

      def self.included(base)
        RELATIONSHIPS.each do |relationship|
          src, line = <<-EOF, __LINE__ + 1
            #{SCOPE_METHOD} :st_#{relationship}, lambda { |*args|
              raise ArgumentError.new("wrong number of arguments (\#{args.length} for 1-2)") unless
                args.length.between?(1, 2)

              options = {
                :column => 'the_geom',
                :use_index => true
              }.merge(args.extract_options!)

              geom = Geos.read(args.first)
              column_name = ::ActiveRecord::Base.connection.quote_table_name(options[:column])
              column_srid = self.srid_for(options[:column])
              geom_srid = if geom.srid == 0
                -1
              else
                geom.srid
              end

              function = if options[:use_index]
                "ST_#{relationship}"
              else
                "_ST_#{relationship}"
              end

              conditions = if column_srid != geom_srid
                if column_srid == -1 || geom_srid == -1
                  %{\#{function}(\#{column_name}, ST_SetSRID(?, \#{column_srid}))}
                else
                  %{\#{function}(\#{column_name}, ST_Transform(?, \#{column_srid}))}
                end
              else
                %{\#{function}(\#{column_name}, ?)}
              end

              {
                :conditions => [
                  conditions,
                  geom.to_ewkb
                ]
              }
            }
          EOF
          base.class_eval(src, __FILE__, line)
        end

        src, line = <<-EOF, __LINE__ + 1
          #{SCOPE_METHOD} :st_dwithin, lambda { |*args|
            raise ArgumentError.new("wrong number of arguments (\#{args.length} for 2-3)") unless
              args.length.between?(2, 3)

            options = {
              :column => 'the_geom',
              :use_index => true
            }.merge(args.extract_options!)

            geom, distance = Geos.read(args.first), args[1]

            column_name = ::ActiveRecord::Base.connection.quote_table_name(options[:column])
            column_srid = self.srid_for(options[:column])
            geom_srid = if geom.srid == 0
              -1
            else
              geom.srid
            end

            function = if options[:use_index]
              'ST_dwithin'
            else
              '_ST_dwithin'
            end

            conditions = if column_srid != geom_srid
              if column_srid == -1 || geom_srid == -1
                %{\#{function}(\#{column_name}, ST_SetSRID(?, \#{column_srid}), ?)}
              else
                %{\#{function}(\#{column_name}, ST_Transform(?, \#{column_srid}), ?)}
              end
            else
              %{\#{function}(\#{column_name}, ?, ?)}
            end

            {
              :conditions => [
                conditions,
                geom.to_ewkb,
                distance
              ]
            }
          }
        EOF
        base.class_eval(src, __FILE__, line)
      end
    end
  end
end
