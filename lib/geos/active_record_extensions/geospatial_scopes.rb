
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
    # The first argument to each of these methods can be a Geos::Geometry-based
    # object or anything readable by Geos.read along with an optional
    # options Hash.
    #
    # For ordering, we have the following:
    #
    # The following scopes take no arguments:
    #
    #  * order_by_ndims
    #  * order_by_npoints
    #  * order_by_nrings
    #  * order_by_numgeometries
    #  * order_by_numinteriorring
    #  * order_by_numinteriorrings
    #  * order_by_numpoints
    #  * order_by_length3d
    #  * order_by_length
    #  * order_by_length2d
    #  * order_by_perimeter
    #  * order_by_perimeter2d
    #  * order_by_perimeter3d
    #
    # These next scopes allow you to specify a geometry argument for
    # measurement:
    #
    #  * order_by_distance
    #  * order_by_distance_sphere
    #  * order_by_maxdistance
    #  * order_by_hausdorffdistance (additionally allows you to set the
    #    densify_frac argument)
    #  * order_by_distance_spheroid (requires an additional SPHEROID
    #    string to calculate against)
    #
    # These next scopes allow you to specify a SPHEROID string to calculate
    # against:
    #
    #  * order_by_length2d_spheroid
    #  * order_by_length3d_spheroid
    #  * order_by_length_spheroid
    #
    # == Options
    #
    # * :column - the column to compare against. The default is 'the_geom'.
    # * :use_index - whether to use the "ST_" methods or the "\_ST_"
    #   variants which don't use indexes. The default is true.
    # * :wkb_options - in order to facilitate some conversions, geometries
    #   are converted to WKB. The default is `{:include_srid => true}` to
    #   force the geometry to use PostGIS's Extended WKB.
    # * :desc - the order_by scopes have an additional :desc option to alllow
    #   for DESC ordering.
    # * :nulls - the order_by scopes also allow you to specify whether you
    #   want NULL values to be sorted first or last.
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
      SCOPE_METHOD = if ::ActiveRecord::VERSION::MAJOR >= 3
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

      ZERO_ARGUMENT_MEASUREMENTS = %w{
        ndims
        npoints
        nrings
        numgeometries
        numinteriorring
        numinteriorrings
        numpoints
        length3d
        length
        length2d
        perimeter
        perimeter2d
        perimeter3d
      }

      ONE_GEOMETRY_ARGUMENT_MEASUREMENTS = %w{
        distance
        distance_sphere
        maxdistance
      }

      ONE_ARGUMENT_MEASUREMENTS = %w{
        length2d_spheroid
        length3d_spheroid
        length_spheroid
      }

      def self.included(base)
        base.class_eval do
          class << self
            protected
              def set_srid_or_transform(column_srid, geom_srid, geos)
                sql = if column_srid != geom_srid
                  if column_srid == -1 || geom_srid == -1
                    %{ST_SetSRID(?, #{column_srid})}
                  else
                    %{ST_Transform(?, #{column_srid})}
                  end
                else
                  %{?}
                end

                sanitize_sql([ sql, geos.to_ewkb ])
              end

              def read_geos(geom, column_srid)
                if geom.is_a?(String) && geom =~ /^SRID=default;/
                  geom = geom.sub(/default/, column_srid.to_s)
                end
                Geos.read(geom)
              end

              def read_geom_srid(geos)
                if geos.srid == 0
                  -1
                else
                  geos.srid
                end
              end

              def default_options(options)
                {
                  :column => 'the_geom',
                  :use_index => true
                }.merge(options || {})
              end

              def function_name(function, use_index)
                if use_index
                  "ST_#{function}"
                else
                  "_ST_#{function}"
                end
              end

              def build_function_call(function, geom = nil, options = {}, function_options = {})
                options = default_options(options)

                function_options = {
                  :additional_args => 0
                }.merge(function_options)

                ''.tap do |ret|
                  column_name = self.connection.quote_table_name(options[:column])
                  ret << "#{function_name(function, options[:use_index])}(#{self.quoted_table_name}.#{column_name}"

                  if geom
                    column_srid = self.srid_for(options[:column])

                    geos = read_geos(geom, column_srid)
                    geom_srid = read_geom_srid(geos)

                    ret << %{, #{self.set_srid_or_transform(column_srid, geom_srid, geos)}}
                  end

                  ret << ', ?' * function_options[:additional_args]
                  ret << %{)#{options[:append]}}
                end
              end

              def additional_ordering(options = nil)
                options ||= {}

                ''.tap do |ret|
                    if options[:desc]
                      ret << ' DESC'
                    end

                    if options[:nulls]
                      ret << " NULLS #{options[:nulls].to_s.upcase}"
                    end
                end
              end

              def assert_arguments_length(args, min, max)
                raise ArgumentError.new("wrong number of arguments (#{args.length} for #{min}-#{max})") unless
                  args.length.between?(min, max)
              end
          end
        end

        RELATIONSHIPS.each do |relationship|
          src, line = <<-EOF, __LINE__ + 1
            #{SCOPE_METHOD} :st_#{relationship}, lambda { |*args|
              assert_arguments_length(args, 1, 2)

              {
                :conditions => build_function_call(
                  '#{relationship}',
                  *args
                )
              }
            }
          EOF
          base.class_eval(src, __FILE__, line)
        end

        base.class_eval do
          send(SCOPE_METHOD, :st_dwithin, lambda { |*args|
            assert_arguments_length(args, 2, 3)
            geom, distance, options = args

            {
              :conditions => [
                build_function_call('dwithin', geom, options, :additional_args => 1),
                distance
              ]
            }
          })
        end

        ZERO_ARGUMENT_MEASUREMENTS.each do |measurement|
          src, line = <<-EOF, __LINE__ + 1
            #{SCOPE_METHOD} :order_by_#{measurement}, lambda { |*args|
              assert_arguments_length(args, 0, 1)
              options = args[0]

              function_call = build_function_call('#{measurement}', nil, options)
              function_call << additional_ordering(options)

              {
                :order => function_call
              }
            }
          EOF
          base.class_eval(src, __FILE__, line)
        end

        ONE_GEOMETRY_ARGUMENT_MEASUREMENTS.each do |measurement|
          src, line = <<-EOF, __LINE__ + 1
            #{SCOPE_METHOD} :order_by_#{measurement}, lambda { |*args|
              assert_arguments_length(args, 1, 2)
              geom, options = args

              function_call = build_function_call('#{measurement}', geom, options)
              function_call << additional_ordering(options)

              {
                :order => function_call
              }
            }
          EOF
          base.class_eval(src, __FILE__, line)
        end

        ONE_ARGUMENT_MEASUREMENTS.each do |measurement|
          src, line = <<-EOF, __LINE__ + 1
            #{SCOPE_METHOD} :order_by_#{measurement}, lambda { |*args|
              assert_arguments_length(args, 1, 2)
              argument, options = args

              function_call = build_function_call('#{measurement}', nil, options, :additional_args => 1)
              function_call << additional_ordering(options)

              {
                :order => sanitize_sql([ function_call, argument ])
              }
            }
          EOF
          base.class_eval(src, __FILE__, line)
        end

        base.class_eval do
          send(SCOPE_METHOD, :order_by_hausdorffdistance, lambda { |*args|
            assert_arguments_length(args, 1, 3)
            options = args.extract_options!
            geom, densify_frac = args

            function_call = build_function_call(
              'hausdorffdistance',
              geom,
              options,
              :additional_args => (densify_frac.present? ? 1 : 0)
            )
            function_call << additional_ordering(options)

            {
              :order => sanitize_sql([
                function_call,
                densify_frac
              ])
            }
          })

          send(SCOPE_METHOD, :order_by_distance_spheroid, lambda { |*args|
            assert_arguments_length(args, 2, 3)
            geom, spheroid, options = args

            function_call = build_function_call(
              'distance_spheroid',
              geom,
              options,
              :additional_args => 1
            )
            function_call << additional_ordering(options)

            {
              :order => sanitize_sql([
                function_call,
                spheroid
              ])
            }
          })
        end
      end
    end
  end
end
