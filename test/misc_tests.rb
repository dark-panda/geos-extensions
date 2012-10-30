
$: << File.dirname(__FILE__)
require 'test_helper'

class GeosMiscTests < MiniTest::Unit::TestCase
  include TestHelper

  def initialize(*args)
    @polygon = Geos.read(POLYGON_WKB)
    @point = Geos.read(POINT_WKB)
    super(*args)
  end

  def write(g)
    g.to_wkt(:rounding_precision => 0)
  end

  def test_upper_left
    assert_equal('POINT (0 5)', write(@polygon.upper_left))
    assert_equal('POINT (10 10)', write(@point.upper_left))

    assert_equal('POINT (0 5)', write(@polygon.northwest))
    assert_equal('POINT (10 10)', write(@point.northwest))

    assert_equal('POINT (0 5)', write(@polygon.nw))
    assert_equal('POINT (10 10)', write(@point.nw))
  end

  def test_upper_right
    assert_equal('POINT (5 5)', write(@polygon.upper_right))
    assert_equal('POINT (10 10)', write(@point.upper_right))

    assert_equal('POINT (5 5)', write(@polygon.northeast))
    assert_equal('POINT (10 10)', write(@point.northeast))

    assert_equal('POINT (5 5)', write(@polygon.ne))
    assert_equal('POINT (10 10)', write(@point.ne))
  end

  def test_lower_left
    assert_equal('POINT (0 0)', write(@polygon.lower_left))
    assert_equal('POINT (10 10)', write(@point.lower_left))

    assert_equal('POINT (0 0)', write(@polygon.southwest))
    assert_equal('POINT (10 10)', write(@point.southwest))

    assert_equal('POINT (0 0)', write(@polygon.sw))
    assert_equal('POINT (10 10)', write(@point.sw))
  end

  def test_lower_right
    assert_equal('POINT (5 0)', write(@polygon.lower_right))
    assert_equal('POINT (10 10)', write(@point.lower_right))

    assert_equal('POINT (5 0)', write(@polygon.southeast))
    assert_equal('POINT (10 10)', write(@point.southeast))

    assert_equal('POINT (5 0)', write(@polygon.se))
    assert_equal('POINT (10 10)', write(@point.se))
  end

  def test_top
    assert_equal(5.0, @polygon.top)
    assert_equal(10.01, @point.top)

    assert_equal(5.0, @polygon.north)
    assert_equal(10.01, @point.north)

    assert_equal(5.0, @polygon.n)
    assert_equal(10.01, @point.n)
  end

  def test_bottom
    assert_equal(0.0, @polygon.bottom)
    assert_equal(10.01, @point.bottom)

    assert_equal(0.0, @polygon.south)
    assert_equal(10.01, @point.south)

    assert_equal(0.0, @polygon.s)
    assert_equal(10.01, @point.s)
  end

  def test_left
    assert_equal(0.0, @polygon.left)
    assert_equal(10.0, @point.left)

    assert_equal(0.0, @polygon.west)
    assert_equal(10.0, @point.west)

    assert_equal(0.0, @polygon.w)
    assert_equal(10.0, @point.w)
  end

  def test_right
    assert_equal(5.0, @polygon.right)
    assert_equal(10.0, @point.right)

    assert_equal(5.0, @polygon.east)
    assert_equal(10.0, @point.east)

    assert_equal(5.0, @polygon.e)
    assert_equal(10.0, @point.e)
  end
end
