
$: << File.dirname(__FILE__)
require 'test_helper'

if ENV['TEST_ACTIVERECORD']
  class GeospatialScopesTests < ActiveRecord::TestCase
    include TestHelper
    include ActiveRecord::TestFixtures

    self.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')
    fixtures :foos

    def tester(method, args, ids = [])
      geoms = Foo.send(method, *Array(args)).all
      assert_equal(ids.sort, geoms.collect(&:id).sort)
    end

    def test_contains
      tester(:st_contains, 'POINT(3 3)', [ 3 ])
    end

    def test_containsproperly
      tester(:st_containsproperly, 'LINESTRING(-4 -4, 4 4)', [ 3 ])
    end

    def test_covers
      tester(:st_covers, 'LINESTRING(-4 -4, 4 4)', [ 3 ])
    end

    def test_coveredby
      tester(:st_coveredby, 'POLYGON((-6 -6, -6 6, 6 6, 6 -6, -6 -6))', [ 1, 3 ])
    end

    def test_crosses
      tester(:st_crosses, 'LINESTRING(-6 -6, 4 4)', [ 3 ])
    end

    def test_disjoint
      tester(:st_disjoint, 'POINT(100 100)', [ 1, 2, 3 ])
    end

    def test_equal
      tester(:st_equals, 'POLYGON((-5 -5, -5 5, 5 5, 5 -5, -5 -5))', [ 3 ])
    end

    def test_intersects
      tester(:st_intersects, 'LINESTRING(-5 -5, 10 10)', [ 1, 2, 3 ])
    end

    def test_orderingequals
      tester(:st_orderingequals, 'POLYGON((-5 -5, -5 5, 5 5, 5 -5, -5 -5))', [ 3 ])
    end

    def test_overlaps
      tester(:st_overlaps, 'POLYGON((-6 -6, -5 0, 0 0, 0 -5, -6 -6))', [ 3 ])
    end

    def test_touches
      tester(:st_touches, 'POLYGON((-5 -5, -5 -10, -10 -10, -10 -5, -5 -5))', [ 3 ])
    end

    def test_within
      tester(:st_within, 'POLYGON((-5 -5, 5 10, 20 20, 10 5, -5 -5))', [ 1, 2 ])
    end

    def test_dwithin
      tester(:st_dwithin, [ 'POINT(5 5)', 10 ], [ 1, 2, 3 ])
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
  end
end
