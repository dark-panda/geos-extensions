
require "rails/railtie"

module Geos
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), %w{ tasks test.rake })
    end
  end
end

