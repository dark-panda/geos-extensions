# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class GeometryTests < Minitest::Test
  include TestHelper

  def test_dump_points
    geom = Geos.read('GEOMETRYCOLLECTION(
      MULTILINESTRING((0 0, 10 10, 20 20), (100 100, 200 200, 300 300)),

      POINT(10 10),

      POLYGON((0 0, 5 0, 5 5, 0 5, 0 0), (1 1, 4 1, 4 4, 1 4, 1 1))
    )')

    assert_equal([
      [
        [
          Geos.create_point(0, 0),
          Geos.create_point(10, 10),
          Geos.create_point(20, 20)
        ],

        [
          Geos.create_point(100, 100),
          Geos.create_point(200, 200),
          Geos.create_point(300, 300)
        ]
      ],

      [
        Geos.create_point(10, 10)
      ],

      [
        [
          Geos.create_point(0, 0),
          Geos.create_point(5, 0),
          Geos.create_point(5, 5),
          Geos.create_point(0, 5),
          Geos.create_point(0, 0)
        ],

        [
          Geos.create_point(1, 1),
          Geos.create_point(4, 1),
          Geos.create_point(4, 4),
          Geos.create_point(1, 4),
          Geos.create_point(1, 1)
        ]
      ]
    ], geom.dump_points)
  end
end
