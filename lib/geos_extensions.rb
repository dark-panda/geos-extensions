
# Some custom extensions to the SWIG-based Geos Ruby extension.
module Geos
	# Returns some kind of Geometry object from the given WKB in
	# binary.
	def self.from_wkb_bin wkb
                raise RuntimeError, "Trying to convert a nil wkb bin to a geometry" if wkb.nil?
		WkbReader.new.read(wkb)
	end

	# Returns some kind of Geometry object from the given WKB in hex.
	def self.from_wkb wkb
                raise RuntimeError, "Trying to convert a nil wkb to a geometry" if wkb.nil?
		WkbReader.new.read_hex(wkb)
	end

	# Returns some kind of Geometry object from the given WKT.
	def self.from_wkt wkt
                raise RuntimeError, "Trying to convert a nil wkt to a geometry" if wkt.nil?
		WktReader.new.read(wkt)
	end

	# This is our base module that we use for some generic methods used all
	# over the place.
	class Geometry
		# Spits the geometry out into WKB in binary.
		def to_wkb_bin
			WkbWriter.new.write(self)
		end

		# Spits the geometry out into WKB in hex.
		def to_wkb
			WkbWriter.new.write_hex(self)
		end

		# Spits the geometry out into WKT.
		def to_wkt
			WktWriter.new.write(self)
		end

		# Returns a Point for the envelope's upper left coordinate.
		def upper_left
			cs = self.envelope.exterior_ring.coord_seq
			WktReader.new.read("POINT(#{cs.get_x(0)} #{cs.get_y(0)})")
		end

		# Returns a Point for the envelope's upper right coordinate.
		def upper_right
			cs = self.envelope.exterior_ring.coord_seq
			WktReader.new.read("POINT(#{cs.get_x(1)} #{cs.get_y(1)})")
		end

		# Returns a Point for the envelope's lower right coordinate.
		def lower_right
			cs = self.envelope.exterior_ring.coord_seq
			WktReader.new.read("POINT(#{cs.get_x(2)} #{cs.get_y(2)})")
		end

		# Returns a Point for the envelope's lower left coordinate.
		def lower_left
			cs = self.envelope.exterior_ring.coord_seq
			WktReader.new.read("POINT(#{cs.get_x(3)} #{cs.get_y(3)})")
		end

		# Returns a new GLatLngBounds object with the proper GLatLngs in place
		# for determining the geometry bounds.
		def to_g_lat_lng_bounds
			"new GLatLngBounds(#{self.lower_left.to_g_lat_lng}, #{self.upper_right.to_g_lat_lng})"
		end

		# Returns a new GPolyline.
		def to_g_polyline options = {}
			self.coord_seq.to_g_polyline options
		end

		# Returns a new GPolygon.
		def to_g_polygon options = {}
			self.coord_seq.to_g_polygon options
		end

		# Returns a new GMarker at the centroid of the geometry. The options
		# Hash works the same as the Google Maps API GMarkerOptions class does,
		# but allows for underscored Ruby-like options which are then converted
		# to the appropriate camel-cased Javascript options.
		def to_g_marker options = {}
			opts = Hash.new
			options.each do |k, v|
				opts[k.to_s.camelize(:lower)] = v
			end
			"new GMarker(#{self.centroid.to_g_lat_lng}, #{opts.to_json})"
		end
	end


	class CoordinateSequence
		# Returns a Ruby Array of GLatLngs.
		def to_g_lat_lng
			self.to_a.collect do |p|
				"new GLatLng(#{p[1]}, #{p[0]})"
			end
		end

		# Returns a new GPolyline. Note that this GPolyline just uses whatever
		# coordinates are found in the sequence in order, so it might not
		# make much sense at all.
		#
		# The options Hash follows the Google Maps API arguments to the
		# GPolyline constructor and include :color, :weight, :opacity and
		# :options. 'null' is used in place of any unset options.
		def to_g_polyline options = {}
			args = [
				(options[:color] ? "'#{options[:color].escape_javascript}'" : 'null'),
				(options[:weight] || 'null'),
				(options[:opacity] || 'null'),
				(options[:options] ? options[:options].to_json : 'null')
			].join(', ')
			"new GPolyline([#{self.to_g_lat_lng.join(',')}], #{args})"
		end

		# Returns a new GPolygon. Note that this GPolygon just uses whatever
		# coordinates are found in the sequence in order, so it might not
		# make much sense at all.
		#
		# The options Hash follows the Google Maps API arguments to the
		# GPolygon constructor and include :stroke_color, :stroke_weight,
		# :stroke_opacity, :fill_color, :fill_opacity and :options. 'null' is
		# used in place of any unset options.
		def to_g_polygon options = {}
			args = [
				(options[:stroke_color] ? "'#{options[:stroke_color].escape_javascript}'" : 'null'),
				(options[:stroke_weight] || 'null'),
				(options[:stroke_opacity] || 'null'),
				(options[:fill_color] ? "'#{options[:fill_color].escape_javascript}'" : 'null'),
				(options[:fille_opacity] || 'null'),
				(options[:options] ? options[:options].to_json : 'null')
			].join(', ')
			"new GPolygon([#{self.to_g_lat_lng.join(',')}], #{args})"
		end

		# Returns a Ruby Array of Arrays of coordinates within the
		# CoordinateSequence in the form [ x, y, z ].
		def to_a
			(0..(self.length - 1)).to_a.collect do |p|
				[
					self.get_x(p),
					(self.dimensions >= 2 ? self.get_y(p) : nil),
					(self.dimensions >= 3 ? self.get_z(p) : nil)
				].compact
			end
		end
		
		# Build some XmlMarkup for KML. You can set various KML options like
		# tessellate, altitudeMode, etc. Use Rails/Ruby-style code and it
		# will be converted automatically, i.e. :altitudeMode, not
		# :altitude_mode.
		def to_kml *args
			xml, options = xml_options(*args)

			xml.LineString(:id => options[:id]) do
				xml.extrude(options[:extrude]) if options[:extrude]
				xml.tessellate(options[:tessellate]) if options[:tessellate]
				xml.altitudeMode(options[:altitude_mode].camelize(:lower)) if options[:altitudeMode]
				xml.coordinates do
					self.to_a.each do
						xml << (self.to_a.join(','))
					end
				end
			end
		end

		# Build some XmlMarkup for GeoRSS GML. You should include the
		# appropriate georss and gml XML namespaces in your document.
		def to_georss *args
			xml, options = xml_options(*args)

			xml.georss(:where) do
				xml.gml(:LineString) do
					xml.gml(:posList) do
						xml << self.to_a.collect do |p|
							"#{p[1]} #{p[0]}"
						end.join(' ')
					end
				end
			end
		end

		# Returns a Hash suitable for converting to JSON.
		#
		# Options:
		#
		# * :encoded - enable or disable Google Maps encoding. The default is
		#   true.
		# * :level - set the level of the Google Maps encoding algorithm.
		def to_jsonable options = {}
			options = {
				:encoded => true,
				:level => 3
			}.merge options

			if options[:encoded]
				{
					:type => 'lineString',
					:encoded => true
				}.merge(GMapsLineEncoder.encode(self.to_a, options[:level]))
			else
				{
					:type => 'lineString',
					:encoded => false,
					:points => self.to_a
				}
			end
		end
		
	end


	class Point
		# Returns a new GLatLng.
		def to_g_lat_lng
			"new GLatLng(#{self.coord_seq.get_y(0)}, #{self.coord_seq.get_x(0)})"
		end

		# Returns the Y coordinate of the Point, which is actually the
		# latitude.
		def lat
			self.coord_seq.get_y(0)
		end

		# Returns the X coordinate of the Point, which is actually the
		# longitude.
		def lng
			self.coord_seq.get_x(0)
		end

		# Returns the Point's coordinates as an Array in the following format:
		#
		#	[ x, y, z ]
		#
		# The Z coordinate will only be present for Points which have a Z
		# dimension.
		def to_a
			cs = self.coord_seq
			if self.has_z?
				[ cs.get_x(0), cs.get_y(0), cs.get_z(0) ]
			else
				[ cs.get_x(0), cs.get_y(0) ]
			end
		end

		# Returns self.
		def upper_left
			self
		end

		# Returns self.
		def upper_right
			self
		end

		# Returns self.
		def lower_right
			self
		end

		# Returns self.
		def lower_left
			self
		end
		
		# Build some XmlMarkup for KML. You can set KML options for extrude and
		# altitudeMode. Use Rails/Ruby-style code and it will be converted
		# appropriately, i.e. :altitude_mode, not :altitudeMode.
		def to_kml *args
			xml, options = xml_options(*args)
        
			xml.Point(:id => options[:id]) do
				xml.extrude(options[:extrude]) if options[:extrude]
				xml.altitudeMode(options[:altitude_mode].camelize(:lower)) if options[:altitudeMode]
				xml.coordinates(self.to_a.join(','))
			end
		end
        
		# Build some XmlMarkup for GeoRSS. You should include the
		# appropriate georss and gml XML namespaces in your document.
		def to_georss *args
			xml, options = xml_options(*args)
        
			xml.georss(:where) do
				xml.gml(:Point) do
					xml.gml(:pos, "#{self.lat} #{self.lng}")
				end
			end
		end
        
		# Returns a Hash suitable for converting to JSON.
		def to_jsonable options = {}
			cs = self.coord_seq
			if self.has_z?
				{ :type => 'point', :lat => cs.get_y(0), :lng => cs.get_x(0), :z => cs.get_z(0) }
			else
				{ :type => 'point', :lat => cs.get_y(0), :lng => cs.get_x(0) }
			end
		end
	end


	class Polygon
		# Returns a GPolyline of the exterior ring of the Polygon. This does
		# not take into consideration any interior rings the Polygon may
		# have.
		def to_g_polyline options = {}
			self.exterior_ring.to_g_polyline options
		end

		# Returns a GPolygon of the exterior ring of the Polygon. This does
		# not take into consideration any interior rings the Polygon may
		# have.
		def to_g_polygon options = {}
			self.exterior_ring.to_g_polygon options
		end
	end


	class GeometryCollection
		# Returns a Ruby Array of GPolylines for each geometry in the
		# collection.
		def to_g_polyline options = {}
			self.collect do |p|
				p.to_g_polyline options = {}
			end
		end

		# Returns a Ruby Array of GPolygons for each geometry in the
		# collection.
		def to_g_polygon options = {}
			self.collect do |p|
				p.to_g_polygon options = {}
			end
		end

		# Returns an Array of geometries from the collection.
		def to_a
			(0..(self.num_geometries - 1)).to_a.collect do |p|
				self.get_geometry_n(p)
			end
		end

		# Iterates the collection through the given block.
		def each
			(0..(self.num_geometries - 1)).to_a.each do |p|
				yield self.get_geometry_n(p)
			end
			nil
		end

		# Same as each but also provides an index for the block's second
		# argument.
		def each_with_index
			(0..(self.num_geometries - 1)).to_a.each do |p|
				yield self.get_geometry_n(p), p
			end
			nil
		end

		# Returns a new array with the results of running block once for every
		# element in the collection.
		def collect &block
			retval = Array.new
			self.each do |r|
				if block
					retval << yield(r)
				else
					retval << r
				end
			end
			retval
		end
		alias :map :collect

		# Returns the first geometry from the collection.
		def first
			self.get_geometry_n(0) if self.num_geometries > 0
		end

		# Returns the last geometry from the collection.
		def last
			self.get_geometry_n(self.num_geometries - 1) if self.num_geometries > 0
		end

		# Returns the nth geometry from the collection.
		def [] n
			self.get_geometry_n(n) if n < self.num_geometries
		end
		alias :at :[]
	end
end
