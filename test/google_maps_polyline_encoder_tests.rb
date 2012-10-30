
$: << File.dirname(__FILE__)
require 'test_helper'

class GoogleMapsPolylineEncoderTests < MiniTest::Unit::TestCase
  include TestHelper

  ENCODED = '_p~iF~ps|U_ulLnnqC_mqNvxq`@'
  DECODED = [
    [ -120.2, 38.5 ],
    [ -120.95, 40.7 ],
    [ -126.453, 43.252 ]
  ]

  def test_encode
    linestring = Geos.read("LINESTRING(#{DECODED.collect { |d| d.join(' ') }.join(', ')})")

    assert_equal(ENCODED, Geos::GoogleMaps::PolylineEncoder.encode(linestring)[:points])
    assert_equal(ENCODED,
      Geos::GoogleMaps::PolylineEncoder.encode(DECODED)[:points]
    )
  end

  def test_decode
    decoded = Geos::GoogleMaps::PolylineEncoder.decode(ENCODED)

    decoded.each_with_index do |(lng, lat), i|
      assert_in_delta(DECODED[i][0], lng, 0.0000001)
      assert_in_delta(DECODED[i][1], lat, 0.0000001)
    end
  end
end
