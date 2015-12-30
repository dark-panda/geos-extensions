# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class CoordinateSequenceTests < Minitest::Test
  include TestHelper

  def test_x_max
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert_equal(10, cs.x_max)
  end

  def test_x_min
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert_equal(-10, cs.x_min)
  end

  def test_y_max
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert_equal(20, cs.y_max)
  end

  def test_y_min
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert_equal(-15, cs.y_min)
  end

  def test_z_max
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert(cs.z_max.nan?, " Expected NaN")

    cs = Geos::CoordinateSequence.new([ -10, -15, -20 ], [ 0, 5, 10 ], [ 10, 20, 30 ])
    assert_equal(30, cs.z_max)
  end

  def test_z_min
    cs = Geos::CoordinateSequence.new([ -10, -15 ], [ 0, 5 ], [ 10, 20 ])
    assert(cs.z_min.nan?, " Expected NaN")

    cs = Geos::CoordinateSequence.new([ -10, -15, -20 ], [ 0, 5, 10 ], [ 10, 20, 30 ])
    assert_equal(-20, cs.z_min)
  end

  def test_snap_to_grid_with_size
    expected = [
      [[-10.0, -15.0], [0.0, 5.0], [10.0, 20.0]],
      [[-10.1, -15.1], [0.1, 5.1], [10.1, 20.1]],
      [[-10.12, -15.12], [0.12, 5.12], [10.12, 20.12]],
      [[-10.123, -15.123], [0.123, 5.123], [10.123, 20.123]],
      [[-10.1235, -15.1235], [0.1235, 5.1235], [10.1235, 20.1235]],
      [[-10.12346, -15.12346], [0.12346, 5.12346], [10.12346, 20.12346]],
      [[-10.123457, -15.123457], [0.123457, 5.123457], [10.123457, 20.123457]],
      [[-10.1234568, -15.1234568], [0.1234568, 5.1234568], [10.1234568, 20.1234568]],
      [[-10.12345679, -15.12345679], [0.12345679, 5.12345679], [10.12345679, 20.12345679]]
    ]

    coordinates = [
      [ -10.123456789, -15.123456789 ],
      [ 0.123456789, 5.123456789 ],
      [ 10.123456789, 20.123456789 ]
    ]

    9.times do |i|
      cs = Geos::CoordinateSequence.new(*coordinates)
      cs.snap_to_grid!(10 ** -i)

      # XXX - Ruby 1.8.7 sometimes sees the the float values as differing
      # slightly, but not enough that it would matter for these tests.
      # Test equality on the inspect Strings instead of the float values.
      assert_equal(expected[i].inspect, cs.to_a.inspect)

      cs = Geos::CoordinateSequence.new(*coordinates)
      snapped = cs.snap_to_grid(10 ** -i)
      assert_equal(coordinates, cs.to_a)
      assert_equal(expected[i].inspect, snapped.to_a.inspect)
    end
  end

  def test_snap_to_grid_with_hash
    cs = Geos::CoordinateSequence.new(
      [ 10, 10 ],
      [ 20, 20 ],
      [ 30, 30 ]
    )
    cs.snap_to_grid!(:size_x => 1, :size_y => 1, :offset_x => 12.5, :offset_y => 12.5)

    assert_equal([
      [ 9.5, 9.5 ],
      [ 20.5, 20.5 ],
      [ 30.5, 30.5 ]
    ], cs.to_a)
  end

  def test_snap_to_grid_with_geometry_origin
    cs = Geos::CoordinateSequence.new(
      [ 10, 10 ],
      [ 20, 20 ],
      [ 30, 30 ]
    )
    cs.snap_to_grid!(:size => 1, :offset => read('LINESTRING (0 0, 25 25)'))

    assert_equal([
      [ 9.5, 9.5 ],
      [ 20.5, 20.5 ],
      [ 30.5, 30.5 ]
    ], cs.to_a)
  end

  def test_snap_to_grid_with_z
    cs = Geos::CoordinateSequence.new(
      [ 10, 10, 10 ],
      [ 20, 20, 20 ],
      [ 30, 30, 30 ]
    )
    cs.snap_to_grid!(
      :size_x => 1,
      :size_y => 1,
      :size_z => 1,

      :offset_x => 12.5,
      :offset_y => 12.5,
      :offset_z => 12.5
    )

    assert_equal([
      [ 9.5, 9.5, 9.5 ],
      [ 20.5, 20.5, 20.5 ],
      [ 30.5, 30.5, 30.5 ]
    ], cs.to_a)
  end

  def test_snap_to_grid_remove_duplicate_points
    coords = [
      [-10.0, 0.0],
      [-10.0, 5.0], [-10.0, 5.0],
      [-10.0, 6.0], [-10.0, 6.0], [-10.0, 6.0],
      [-10.0, 7.0], [-10.0, 7.0], [-10.0, 7.0],
      [-10.0, 8.0], [-10.0, 8.0],
      [-9.0, 8.0], [-9.0, 9.0],
      [-10.0, 0.0]
    ]

    expected = [
      [-10.0, 0.0],
      [-10.0, 5.0],
      [-10.0, 6.0],
      [-10.0, 7.0],
      [-10.0, 8.0],
      [-9.0, 8.0],
      [-9.0, 9.0],
      [-10.0, 0.0]
    ]

    cs = Geos::CoordinateSequence.new(coords)
    cs.snap_to_grid!

    assert_equal(expected, cs.to_a)

    cs = Geos::CoordinateSequence.new(coords)
    cs2 = cs.snap_to_grid

    assert_equal(coords, cs.to_a)
    assert_equal(expected, cs2.to_a)
  end
end
