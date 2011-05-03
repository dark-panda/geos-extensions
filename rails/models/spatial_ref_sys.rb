
module Geos
  class SpatialRefSys < ::ActiveRecord::Base
    set_table_name 'spatial_ref_sys'
    set_primary_key 'srid'

    has_many :geometry_columns,
      :foreign_key => :srid,
      :inverse_of => :spatial_ref_sys
  end
end

