class AddLanguageToSession < ActiveRecord::Migration
  def self.up
    add_column :sessions, :language, :string
  end

  def self.down
    remove_column :sessions, :language
  end
end
