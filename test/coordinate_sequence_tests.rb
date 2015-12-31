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

  def cs_affine_tester(method, expected, coords, *args)
    cs = Geos::CoordinateSequence.new(coords)
    cs.send("#{method}!", *args)

    expected.length.times do |i|
      assert_in_delta(expected[i], cs.get_ordinate(0, i), DELTA_TOLERANCE)
    end

    cs = Geos::CoordinateSequence.new(coords)
    cs2 = cs.send(method, *args)

    expected.length.times do |i|
      assert_in_delta(coords[i], cs.get_ordinate(0, i), DELTA_TOLERANCE)
      assert_in_delta(expected[i], cs2.get_ordinate(0, i), DELTA_TOLERANCE)
    end
  end

  def test_rotate
    cs_affine_tester(:rotate, [ 29.0, 11.0 ], [ 1, 1 ], Math::PI / 2, [ 10.0, 20.0 ])
    cs_affine_tester(:rotate, [ -2.0, 0.0 ], [ 1, 1 ], -Math::PI / 2, [ -1.0, 2.0 ])
    cs_affine_tester(:rotate, [ 19.0, 1.0 ], [ 1, 1 ], Math::PI / 2, read('POINT(10 10)'))
    cs_affine_tester(:rotate, [ -0.5, 0.5 ], [ 1, 1 ], Math::PI / 2, read('LINESTRING(0 0, 1 0)'))
  end

  def test_rotate_x
    cs_affine_tester(:rotate_x, [ 1, -1, -1 ], [ 1, 1, 1 ], Math::PI)
    cs_affine_tester(:rotate_x, [ 1, -1, 1 ], [ 1, 1, 1 ], Math::PI / 2)
    cs_affine_tester(:rotate_x, [ 1, 1, -1 ], [ 1, 1, 1 ], Math::PI + Math::PI / 2)
    cs_affine_tester(:rotate_x, [ 1, 1, 1 ], [ 1, 1, 1 ], Math::PI * 2)
  end

  def test_rotate_y
    cs_affine_tester(:rotate_y, [ -1, 1, -1 ], [ 1, 1, 1 ], Math::PI)
    cs_affine_tester(:rotate_y, [ 1, 1, -1 ], [ 1, 1, 1 ], Math::PI / 2)
    cs_affine_tester(:rotate_y, [ -1, 1, 1 ], [ 1, 1, 1 ], Math::PI + Math::PI / 2)
    cs_affine_tester(:rotate_y, [ 1, 1, 1 ], [ 1, 1, 1 ], Math::PI * 2)
  end

  def test_rotate_z
    cs_affine_tester(:rotate_z, [ -1, -1 ], [ 1, 1 ], Math::PI)
    cs_affine_tester(:rotate_z, [ -1, 1 ], [ 1, 1 ], Math::PI / 2)
    cs_affine_tester(:rotate_z, [ 1, -1 ], [ 1, 1 ], Math::PI + Math::PI / 2)
    cs_affine_tester(:rotate_z, [ 1, 1 ], [ 1, 1 ], Math::PI * 2)
  end

  def test_scale
    cs_affine_tester(:scale, [ 5, 5 ], [ 1, 1 ], 5, 5)
    cs_affine_tester(:scale, [ 3, 2 ], [ 1, 1 ], 3, 2)
    cs_affine_tester(:scale, [ 40, 40, 40 ], [ 10, 20, -5 ], 4, 2, -8)
  end

  def test_scale_hash
    cs_affine_tester(:scale, [ 5, 5 ], [ 1, 1 ], :x => 5, :y => 5)
    cs_affine_tester(:scale, [ 3, 2 ], [ 1, 1 ], :x => 3, :y => 2)
    cs_affine_tester(:scale, [ 40, 40, 40 ], [ 10, 20, -5 ], :x => 4, :y => 2, :z => -8)
  end

  def test_trans_scale
    cs_affine_tester(:trans_scale, [ 2, 2 ], [ 1, 1 ], 1, 1, 1, 1)
    cs_affine_tester(:trans_scale, [ 3, 3 ], [ 2, 2 ], 1, 1, 1, 1)
    cs_affine_tester(:trans_scale, [ 0, 0 ], [ 1, 1 ], -1, -1, -1, -1)
    cs_affine_tester(:trans_scale, [ 1, 2 ], [ 1, 1 ], 0, 1, 1, 1)
    cs_affine_tester(:trans_scale, [ 2, 1 ], [ 1, 1 ], 1, 0, 1, 1)
    cs_affine_tester(:trans_scale, [ 0, 2 ], [ 1, 1 ], 1, 1, 0, 1)
    cs_affine_tester(:trans_scale, [ 2, 0 ], [ 1, 1 ], 1, 1, 1, 0)
    cs_affine_tester(:trans_scale, [ 3, 2 ], [ 1, 1 ], 2, 1, 1, 1)
    cs_affine_tester(:trans_scale, [ 2, 3 ], [ 1, 1 ], 1, 2, 1, 1)
    cs_affine_tester(:trans_scale, [ 4, 2 ], [ 1, 1 ], 1, 1, 2, 1)
    cs_affine_tester(:trans_scale, [ 2, 4 ], [ 1, 1 ], 1, 1, 1, 2)
    cs_affine_tester(:trans_scale, [ 15, 28 ], [ 1, 1 ], 2, 3, 5, 7)
    cs_affine_tester(:trans_scale, [ 15, 28, 1 ], [ 1, 1, 1 ], 2, 3, 5, 7)
  end

  def test_trans_scale_hash
    cs_affine_tester(:trans_scale, [ 2, 2 ], [ 1, 1 ], :delta_x => 1, :delta_y => 1, :x_factor => 1, :y_factor => 1)
    cs_affine_tester(:trans_scale, [ 15, 28, 1 ], [ 1, 1, 1 ], :delta_x => 2, :delta_y => 3, :x_factor => 5, :y_factor => 7)
    cs_affine_tester(:trans_scale, [ 3, 1, 1 ], [ 1, 1, 1 ], :delta_x => 2, :z_factor => 2)
  end

  def test_translate
    cs_affine_tester(:translate, [ 5, 12 ], [ 0, 0 ], 5, 12)
    cs_affine_tester(:translate, [ -3, -7, 3 ], [ 0, 0, 0 ], -3, -7, 3)
  end

  def test_translate_hash
    cs_affine_tester(:translate, [ 5, 12 ], [ 0, 0 ], :x => 5, :y => 12)
    cs_affine_tester(:translate, [ -3, -7, 3 ], [ 0, 0, 0 ], :x => -3, :y => -7, :z => 3)
  end
end
