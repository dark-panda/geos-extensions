
require "rails/railtie"
require File.join(File.dirname(__FILE__), *%w{ models geometry_column })
require File.join(File.dirname(__FILE__), *%w{ models spatial_ref_sys })

module Geos
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), %w{ tasks test.rake })
    end
  end
end

