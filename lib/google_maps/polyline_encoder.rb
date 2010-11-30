
module Geos
	module GoogleMaps
		module PolylineEncoder

			class << self
				# Encodes a series of points into Google's encoded polyline format. See
				# http://code.google.com/apis/maps/documentation/reference.html for
				# details, specifically GPolyline#fromEncoded and
				# GPolygon#fromEncoded.
				#
				# The level parameter is the zoom level you're encoding at. See the
				# Google Maps API reference for details on that.
				def encode(points, level = 3)
					encoded_points = String.new
					encoded_levels = String.new

					prev_lat = 0
					prev_lng = 0

					points.each do |p|
						lat_e5 = (p[1] * 1e5).floor
						lng_e5 = (p[0] * 1e5).floor

						cur_lat = lat_e5 - prev_lat
						cur_lng = lng_e5 - prev_lng

						prev_lat = lat_e5
						prev_lng = lng_e5

						encoded_points += encode_signed_number(cur_lat) + encode_signed_number(cur_lng)
						encoded_levels += encode_number(level)
					end

					{ :points => encoded_points, :levels => encoded_levels }
				end

				protected

				# Encodes a signed number into the Google Maps encoded polyline format.
				def encode_signed_number(n) #:nodoc:
					signed = n << 1
					signed = ~(signed) if n < 0
					encode_number signed
				end

				# Encodes a number into the Google Maps encoded polyline format.
				def encode_number(n) #:nodoc:
					str = String.new
					while (n >= 0x20) do
						str += ((0x20 | (n & 0x1f)) + 63).chr
						n >>= 5
					end
					str + (n + 63).chr
				end
			end
		end
	end
end

