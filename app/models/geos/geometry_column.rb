
module Geos
  class GeometryColumn < ::ActiveRecord::Base
    set_table_name 'geometry_columns'
    set_inheritance_column 'nonexistent_column_name_type'

    belongs_to :spatial_ref_sys,
      :foreign_key => :srid,
      :inverse_of => :geometry_columns

    after_initialize proc { |row|
      row.f_table_catalog ||= ''
    }

    validates :f_table_catalog,
      :length => {
        :minimum => 0
      }

    validates :f_table_schema,
      :presence => true

    validates :f_table_name,
      :presence => true

    validates :f_geometry_column,
      :presence => true

    validates :coord_dimension,
      :presence => true

    validates :srid,
      :presence => true

    validates :type,
      :presence => true
  end
end

