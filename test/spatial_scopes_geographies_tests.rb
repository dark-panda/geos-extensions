
$: << File.dirname(__FILE__)
require 'test_helper'

if ENV['TEST_ACTIVERECORD']
  class SpatialScopesGeographiesTests < ActiveRecord::TestCase
    include TestHelper
    include ActiveRecord::TestFixtures

    self.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')
    fixtures :foo_geographies

    def ids_tester(method, args, ids = [], options = {})
      geoms = FooGeography.send(method, *Array(args)).all(options)
      assert_equal(ids.sort, geoms.collect(&:id).sort)
    end

    def test_covers
      ids_tester(:st_covers, 'POINT(0 0)', [ 3 ], :conditions => {
        :id => [ 3 ]
      })
    end

    def test_coveredby
      ids_tester(:st_coveredby, 'POLYGON((-6 -6, -6 6, 6 6, 6 -6, -6 -6))', [ 1 ], :conditions => {
        :id => [ 1, 2 ]
      })
    end

    def test_intersects
      ids_tester(:st_intersects, 'LINESTRING(-5 -5, 10 10)', [ 2, 3 ])
    end

    def test_dwithin
      ids_tester(:st_dwithin, [ 'POINT(5 5)', 10 ], [ 3 ])
    end

    def test_allow_null
      begin
        foo = FooGeography.create(:name => 'four')
        ids_tester(:st_covers, [ 'POINT(3 3)', { :allow_null => true } ], [ 3, foo.id ])
      ensure
        FooGeography.find_by_name('four').destroy
      end
    end

    def test_with_column
      assert_equal([3], FooGeography.st_covers('POINT(7 7)', :column => :the_other_geom).all.collect(&:id).sort)
    end

    def test_with_srid_switching
      assert_equal([3], FooGeography.st_covers('SRID=4326; POINT(3 3)').all.collect(&:id).sort)
    end

    def test_with_srid_default
      assert_equal([3], FooGeography.st_covers('SRID=default; POINT(3 3)').all.collect(&:id).sort)
    end

    def test_with_srid_transform
      assert_equal([3], FooGeography.st_covers('SRID=4269; POINT(7 7)', :column => :the_other_geom).all.collect(&:id).sort)
    end

    def test_order_by_distance
      assert_equal([3, 1, 2], FooGeography.order_by_distance('POINT(1 1)').all.collect(&:id))
    end

    def test_order_by_distance_desc
      assert_equal([2, 1, 3], FooGeography.order_by_distance('POINT(1 1)', :desc => true).all.collect(&:id))
    end

    def test_order_by_area
      assert_equal([1, 2, 3], FooGeography.order_by_area.order('id').all.collect(&:id))
    end

    def test_order_by_area_desc
      assert_equal([3, 1, 2], FooGeography.order_by_area(:desc => true).order('id').all.collect(&:id))
    end

    def test_order_by_length
      assert_equal([1, 2, 3], FooGeography.order_by_length.order('id').all.collect(&:id))
    end

    def test_order_by_length_desc
      expected = if Geos::ActiveRecord::POSTGIS[:lib] >= '2.0'
        [1, 2, 3]
      else
        [3, 1, 2]
      end

      assert_equal(expected, FooGeography.order_by_length(:desc => true).order('id').where('true = true').all.collect(&:id))
    end

    def test_order_by_area_with_desc_symbol
      assert_equal([3, 1, 2], FooGeography.order_by_area(:desc).order('id').all.collect(&:id))
    end
  end
end
