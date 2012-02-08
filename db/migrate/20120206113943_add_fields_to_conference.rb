class AddFieldsToConference < ActiveRecord::Migration
  def change
  	add_column :conferences, :url, :string
  	add_column :conferences, :description_pt, :text
  	add_column :conferences, :description_es, :text
  	add_column :conferences, :description_en, :text
  	add_column :conferences, :location, :string
  end
end
