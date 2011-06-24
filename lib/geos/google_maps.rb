
module Geos
  module GoogleMaps
    class << self
      def use_api(version)
        version_const = Geos::GoogleMaps.const_get("Api#{version}")
        version_const.constants.each do |c|
          mod = version_const.const_get(c)
          klass = Geos.const_get(c)
          regex = %r{_api#{version}$}

          if !klass.include?(mod)
            klass.send(:include, mod)
          end

          mod.instance_methods.each do |method|
            klass.send(:alias_method, method.to_s.sub(regex, ''), method)
          end
        end
      end
    end

    autoload :PolylineEncoder, File.join(GEOS_EXTENSIONS_BASE, *%w{ geos google_maps polyline_encoder })
    autoload :ApiIncluder, File.join(GEOS_EXTENSIONS_BASE, *%w{ geos google_maps api_includer })
    autoload :Api2, File.join(GEOS_EXTENSIONS_BASE, *%w{ geos google_maps api_2 })
    autoload :Api3, File.join(GEOS_EXTENSIONS_BASE, *%w{ geos google_maps api_3 })
  end
end
