
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
    # * st_dfullywithin
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
    # * :allow_null - relationship scopes have the option of treating NULL
    #   geometry values as TRUE, i.e.
    #
    #     ST_within(the_geom, ...) OR the_geom IS NULL
    #
    # * :desc - the order_by scopes have an additional :desc option to alllow
    #   for DESC ordering.
    # * :nulls - the order_by scopes also allow you to specify whether you
    #   want NULL values to be sorted first or last.
    #
    # Because it's quite common to only want to flip the ordering to DESC,
    # you can also just pass :desc on its own rather than as an options Hash.
    #
    # == SRID Detection
    #
    # * the default SRID according to the SQL-MM standard is 0, but versions
    #   of PostGIS prior to 2.0 would return -1. We do some detection here
    #   and set the value of Geos::ActiveRecord.UNKNOWN_SRIDS[type]
    #   accordingly.
    # * if the geometry itself has an SRID, we'll compare it to the
    #   geometry of the column. If they differ, we'll use ST_Transform
    #   to transform the geometry to the proper SRID for comparison. If
    #   they're the same, no conversion is necessary.
    # * if no SRID is specified in the geometry, we'll use ST_SetSRID
    #   to set the SRID to the column's SRID.
    # * in cases where the column has been defined with an SRID of
    #   UNKNOWN_SRIDS[type], no transformation is done, but we'll set the SRID
    #   of the geometry to UNKNOWN_SRIDS[type] to perform the query using
    #   ST_SetSRID, as we'll assume the SRID of the column to be whatever
    #   the SRID of the geometry is.
    # * when using geography types, the SRID is never transformed since
    #   it's assumed that all of your geometries will be in 4326.
    module SpatialScopes
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
      }

      ZERO_ARGUMENT_MEASUREMENTS = %w{
        area
        ndims
        npoints
        nrings
        numgeometries
        numinteriorring
        numinteriorrings
        numpoints
        length
        length2d
        perimeter
        perimeter2d
      }

      ONE_GEOMETRY_ARGUMENT_MEASUREMENTS = %w{
        distance
        distance_sphere
        maxdistance
      }

      ONE_GEOMETRY_ARGUMENT_AND_ONE_ARGUMENT_RELATIONSHIPS = %w{
        dwithin
        dfullywithin
      }

      ONE_ARGUMENT_MEASUREMENTS = %w{
        length2d_spheroid
        length_spheroid
      }

      # Some functions were renamed in PostGIS 2.0.
      if Geos::ActiveRecord.POSTGIS[:lib] >= '2.0'
        RELATIONSHIPS.concat(%w{
          3dintersects
        })

        ZERO_ARGUMENT_MEASUREMENTS.concat(%w{
          3dlength
          3dperimeter
        })

        ONE_ARGUMENT_MEASUREMENTS.concat(%w{
          3dlength_spheroid
        })

        ONE_GEOMETRY_ARGUMENT_MEASUREMENTS.concat(%w{
          3ddistance
          3dmaxdistance
        })

        ONE_GEOMETRY_ARGUMENT_AND_ONE_ARGUMENT_RELATIONSHIPS.concat(%w{
          3ddwithin
          3ddfullywithin
        })
      else
        ZERO_ARGUMENT_MEASUREMENTS.concat(%w{
          length3d
          perimeter3d
        })

        ONE_ARGUMENT_MEASUREMENTS.concat(%w{
          length3d_spheroid
        })
      end

      FUNCTION_ALIASES = {
        'order_by_max_distance' => 'order_by_maxdistance',
        'st_geometrytype' => 'st_geometry_type'
      }

      COMPATIBILITY_FUNCTION_ALIASES = if Geos::ActiveRecord.POSTGIS[:lib] >= '2.0'
        {
          'order_by_length3d' => 'order_by_3dlength',
          'order_by_perimeter3d' => 'order_by_3dperimeter',
          'order_by_length3d_spheroid' => 'order_by_3dlength_spheroid'
        }
      else
        {
          'order_by_3dlength' => 'order_by_length3d',
          'order_by_3dperimeter' => 'order_by_perimeter3d',
          'order_by_3dlength_spheroid' => 'order_by_length3d_spheroid'
        }
      end

      if Geos::ActiveRecord.POSTGIS[:lib] >= '2.0'
        FUNCTION_ALIASES.merge!({
          'st_3d_dwithin' => 'st_3ddwithin',
          'st_3d_dfully_within' => 'st_3ddfullywithin',
          'order_by_3d_distance' => 'order_by_3ddistance',
          'order_by_3d_max_distance' => 'order_by_3dmaxdistance'
        })
      end

      def self.included(base)
        base.class_eval do
          class << self
            protected
              def set_srid_or_transform(column_srid, geom_srid, geos, type)
                sql = if type != :geography && column_srid != geom_srid
                  if column_srid == Geos::ActiveRecord.UNKNOWN_SRIDS[type] || geom_srid == Geos::ActiveRecord.UNKNOWN_SRIDS[type]
                    %{ST_SetSRID(?::#{type}, #{column_srid})}
                  else
                    %{ST_Transform(?::#{type}, #{column_srid})}
                  end
                else
                  %{?::#{type}}
                end

                sanitize_sql([ sql, geos.to_ewkb ])
              end

              def read_geos(geom, column_srid)
                if geom.is_a?(String) && geom =~ /^SRID=default;/
                  geom = geom.sub(/default/, column_srid.to_s)
                end
                Geos.read(geom)
              end

              def read_geom_srid(geos, column_type = :geometry)
                if geos.srid == 0 || geos.srid == -1
                  Geos::ActiveRecord.UNKNOWN_SRIDS[column_type]
                else
                  geos.srid
                end
              end

              def default_options(*args)
                options = args.extract_options!

                desc = if args.first == :desc
                  true
                else
                  options[:desc]
                end

                {
                  :column => 'the_geom',
                  :use_index => true,
                  :desc => desc
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
                    column_type = self.spatial_column_by_name(options[:column]).spatial_type
                    column_srid = self.srid_for(options[:column])

                    geos = read_geos(geom, column_srid)
                    geom_srid = read_geom_srid(geos, column_type)

                    ret << %{, #{self.set_srid_or_transform(column_srid, geom_srid, geos, column_type)}}
                  end

                  ret << ', ?' * function_options[:additional_args]
                  ret << ')'

                  if options[:allow_null]
                    ret << " OR #{self.quoted_table_name}.#{column_name} IS NULL"
                  end
                end
              end

              def additional_ordering(*args)
                options = args.extract_options!

                desc = if args.first == :desc
                  true
                else
                  options[:desc]
                end

                ''.tap do |ret|
                    if desc
                      ret << ' DESC'
                    end

                    if options[:nulls]
                      ret << " NULLS #{options[:nulls].to_s.upcase}"
                    end
                end
              end

              def assert_arguments_length(args, min, max = (1.0 / 0.0))
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

        ONE_GEOMETRY_ARGUMENT_AND_ONE_ARGUMENT_RELATIONSHIPS.each do |relationship|
          src, line = <<-EOF, __LINE__ + 1
            #{SCOPE_METHOD} :st_#{relationship}, lambda { |*args|
              assert_arguments_length(args, 2, 3)
              geom, distance, options = args

              {
                :conditions => [
                  build_function_call('#{relationship}', geom, options, :additional_args => 1),
                  distance
                ]
              }
            }
          EOF
          base.class_eval(src, __FILE__, line)
        end

        base.class_eval do
          send(SCOPE_METHOD, :st_geometry_type, lambda { |*args|
            assert_arguments_length(args, 1)
            options = args.extract_options!
            types = args

            {
              :conditions => [
                "#{build_function_call('GeometryType', nil, options)} IN (?)",
                types
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

          class << base
            aliases = COMPATIBILITY_FUNCTION_ALIASES.merge(FUNCTION_ALIASES)

            aliases.each do |k, v|
              alias_method(k, v)
            end
          end
        end
      end
    end

    GeospatialScopes = SpatialScopes
  end
end
