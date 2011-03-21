
$: << File.dirname(__FILE__)
require 'test_helper'

if ENV['TEST_ACTIVERECORD']
  class GeospatialScopesTests < ActiveRecord::TestCase
    include TestHelper
    include ActiveRecord::TestFixtures

    self.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')
    fixtures :foos

    def ids_tester(method, args, ids = [])
      geoms = Foo.send(method, *Array(args)).all
      assert_equal(ids.sort, geoms.collect(&:id).sort)
    end

    def test_contains
      ids_tester(:st_contains, 'POINT(3 3)', [ 3 ])
    end

    def test_containsproperly
      ids_tester(:st_containsproperly, 'LINESTRING(-4 -4, 4 4)', [ 3 ])
    end

    def test_covers
      ids_tester(:st_covers, 'LINESTRING(-4 -4, 4 4)', [ 3 ])
    end

    def test_coveredby
      ids_tester(:st_coveredby, 'POLYGON((-6 -6, -6 6, 6 6, 6 -6, -6 -6))', [ 1, 3 ])
    end

    def test_crosses
      ids_tester(:st_crosses, 'LINESTRING(-6 -6, 4 4)', [ 3 ])
    end

    def test_disjoint
      ids_tester(:st_disjoint, 'POINT(100 100)', [ 1, 2, 3 ])
    end

    def test_equal
      ids_tester(:st_equals, 'POLYGON((-5 -5, -5 5, 5 5, 5 -5, -5 -5))', [ 3 ])
    end

    def test_intersects
      ids_tester(:st_intersects, 'LINESTRING(-5 -5, 10 10)', [ 1, 2, 3 ])
    end

    def test_orderingequals
      ids_tester(:st_orderingequals, 'POLYGON((-5 -5, -5 5, 5 5, 5 -5, -5 -5))', [ 3 ])
    end

    def test_overlaps
      ids_tester(:st_overlaps, 'POLYGON((-6 -6, -5 0, 0 0, 0 -5, -6 -6))', [ 3 ])
    end

    def test_touches
      ids_tester(:st_touches, 'POLYGON((-5 -5, -5 -10, -10 -10, -10 -5, -5 -5))', [ 3 ])
    end

    def test_within
      ids_tester(:st_within, 'POLYGON((-5 -5, 5 10, 20 20, 10 5, -5 -5))', [ 1, 2 ])
    end

    def test_dwithin
      ids_tester(:st_dwithin, [ 'POINT(5 5)', 10 ], [ 1, 2, 3 ])
    end

    def test_with_column
      assert_equal([1, 2, 3], Foo.st_disjoint('POINT(100 100)', :column => :the_other_geom).all.collect(&:id).sort)
    end

    def test_with_srid_switching
      assert_equal([1, 2, 3], Foo.st_disjoint('SRID=4326; POINT(100 100)').all.collect(&:id).sort)
    end

    def test_with_srid_default
      assert_equal([1, 2, 3], Foo.st_disjoint('SRID=default; POINT(100 100)').all.collect(&:id).sort)
      assert_equal([3], Foo.st_contains('SRID=default; POINT(-3 -3)').all.collect(&:id).sort)
    end

    def test_with_srid_transform
      assert_equal([1, 2, 3], Foo.st_disjoint('SRID=4269; POINT(100 100)', :column => :the_other_geom).all.collect(&:id).sort)
      assert_equal([3], Foo.st_contains('SRID=4269; POINT(7 7)', :column => :the_other_geom).all.collect(&:id).sort)
    end

    def test_order_by_distance
      assert_equal([3, 1, 2], Foo.order_by_distance('POINT(1 1)').all.collect(&:id))
    end

    def test_order_by_distance_desc
      assert_equal([2, 1, 3], Foo.order_by_distance('POINT(1 1)', :desc => true).all.collect(&:id))
    end

    def test_order_by_distance_sphere
      assert_equal([3, 1, 2], Foo.order_by_distance_sphere('POINT(1 1)').all.collect(&:id))
    end

    def test_order_by_distance_sphere_desc
      assert_equal([2, 1, 3], Foo.order_by_distance_sphere('POINT(1 1)', :desc => true).all.collect(&:id))
    end

    def test_order_by_maxdistance
      assert_equal([1, 3, 2], Foo.order_by_maxdistance('POINT(1 1)').all.collect(&:id))
    end

    def test_order_by_maxdistance_desc
      assert_equal([2, 3, 1], Foo.order_by_maxdistance('POINT(1 1)', :desc => true).all.collect(&:id))
    end

    def test_order_by_ndims
      assert_equal([1, 2, 3], Foo.order_by_ndims.order('id').all.collect(&:id))
    end

    def test_order_by_ndims_desc
      assert_equal([1, 2, 3], Foo.order_by_ndims(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_npoints
      assert_equal([1, 2, 3], Foo.order_by_npoints.order('id').all.collect(&:id))
    end

    def test_order_by_npoints_desc
      assert_equal([3, 1, 2], Foo.order_by_npoints(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_nrings
      assert_equal([1, 2, 3], Foo.order_by_nrings.order('id').all.collect(&:id))
    end

    def test_order_by_nrings_desc
      assert_equal([3, 1, 2], Foo.order_by_nrings(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_numgeometries
      assert_equal([1, 2, 3], Foo.order_by_numgeometries.order('id').all.collect(&:id))
    end

    def test_order_by_numgeometries_desc
      assert_equal([1, 2, 3], Foo.order_by_numgeometries(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_numinteriorring
      assert_equal([3, 1, 2], Foo.order_by_numinteriorring.order('id').all.collect(&:id))
    end

    def test_order_by_numinteriorring_desc
      assert_equal([1, 2, 3], Foo.order_by_numinteriorring(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_numinteriorrings
      assert_equal([3, 1, 2], Foo.order_by_numinteriorrings.order('id').all.collect(&:id))
    end

    def test_order_by_numinteriorrings_desc
      assert_equal([1, 2, 3], Foo.order_by_numinteriorrings(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_numpoints
      assert_equal([1, 2, 3], Foo.order_by_numpoints.order('id').all.collect(&:id))
    end

    def test_order_by_numpoints_desc
      assert_equal([1, 2, 3], Foo.order_by_numpoints(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_length3d
      assert_equal([1, 2, 3], Foo.order_by_length3d.order('id').all.collect(&:id))
    end

    def test_order_by_length3d_desc
      assert_equal([1, 2, 3], Foo.order_by_length3d(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_length
      assert_equal([1, 2, 3], Foo.order_by_length.order('id').all.collect(&:id))
    end

    def test_order_by_length_desc
      assert_equal([1, 2, 3], Foo.order_by_length(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_length2d
      assert_equal([1, 2, 3], Foo.order_by_length2d.order('id').all.collect(&:id))
    end

    def test_order_by_length2d_desc
      assert_equal([1, 2, 3], Foo.order_by_length2d(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_length3d_spheroid
      assert_equal([1, 2, 3], Foo.order_by_length3d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]').order('id').all.collect(&:id))
    end

    def test_order_by_length3d_spheroid_desc
      assert_equal([1, 2, 3], Foo.order_by_length3d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]', :desc => true).order('id').all.collect(&:id))
    end


    def test_order_by_length2d_spheroid
      assert_equal([1, 2, 3], Foo.order_by_length3d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]').order('id').all.collect(&:id))
    end

    def test_order_by_length2d_spheroid_desc
      assert_equal([1, 2, 3], Foo.order_by_length3d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]', :desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_length_spheroid
      assert_equal([1, 2, 3], Foo.order_by_length3d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]').order('id').all.collect(&:id))
    end

    def test_order_by_length_spheroid_desc
      assert_equal([1, 2, 3], Foo.order_by_length3d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]', :desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_perimeter
      assert_equal([1, 2, 3], Foo.order_by_perimeter.order('id').all.collect(&:id))
    end

    def test_order_by_perimeter_desc
      assert_equal([3, 1, 2], Foo.order_by_perimeter(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_perimeter2d
      assert_equal([1, 2, 3], Foo.order_by_perimeter2d.order('id').all.collect(&:id))
    end

    def test_order_by_perimeter2d_desc
      assert_equal([3, 1, 2], Foo.order_by_perimeter2d(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_perimeter3d
      assert_equal([1, 2, 3], Foo.order_by_perimeter3d.order('id').all.collect(&:id))
    end

    def test_order_by_perimeter3d_desc
      assert_equal([3, 1, 2], Foo.order_by_perimeter3d(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_hausdorffdistance
      assert_equal([1, 3, 2], Foo.order_by_hausdorffdistance('POINT(1 1)').all.collect(&:id))
    end

    def test_order_by_hausdorffdistance_desc
      assert_equal([2, 3, 1], Foo.order_by_hausdorffdistance('POINT(1 1)', :desc => true).all.collect(&:id))
    end

    def test_order_by_hausdorffdistance_with_densify_frac
      assert_equal([1, 3, 2], Foo.order_by_hausdorffdistance('POINT(1 1)', 0.314).all.collect(&:id))
    end


    def test_order_by_distance_spheroid
      assert_equal([2, 3, 1], Foo.order_by_distance_spheroid('POINT(10 10)', 'SPHEROID["WGS 84", 6378137, 298.257223563]').order('id').all.collect(&:id))
    end

    def test_order_by_distance_spheroid_desc
      assert_equal([1, 3, 2], Foo.order_by_distance_spheroid('POINT(10 10)', 'SPHEROID["WGS 84", 6378137, 298.257223563]', :desc => true).order('id').all.collect(&:id))
    end
  end
end
