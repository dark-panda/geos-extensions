
module Geos
  unless defined?(Geos::Error)
    class Error < ::RuntimeError
    end
  end

  unless defined?(Geos::ParseError)
    class ParseError < Error
    end
  end

  module Extensions
    class InvalidGLatLngFormatError < Geos::ParseError
      def initialize
        super("Invalid GLatLng format")
      end
    end

    class InvalidBox2DError < Geos::ParseError
      def initialize
        super("Invalid BOX2D")
      end
    end
  end
end

