# encoding: UTF-8

module Geos
  class Geometry
    def init_with(coder)
      # Convert wkt to a geos pointer
      reader = Geos::WktReader.new
      geom_ptr = FFIGeos.GEOSWKTReader_read_r(Geos.current_handle, reader.ptr, coder['wkt'])

      # Now setup this objects pointer to be the pointer we just created
      @ptr = FFI::AutoPointer.new(geom_ptr, self.class.method(:release))
      self.srid = coder['srid']
    end

    def encode_with(coder)
      writer = Geos::WktWriter.new
      # Note we enforce ascii encoding so the wkt in the yaml file is readable - otherwise
      # psych converts it to a binary string
      coder['wkt'] = writer.write(self).force_encoding('ASCII')
      coder['srid'] = self.srid
    end  end
end