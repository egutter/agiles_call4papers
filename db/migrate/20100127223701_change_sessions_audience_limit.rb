class ChangeSessionsAudienceLimit < ActiveRecord::Migration
  def self.up
    # Doesn't work in PostgreSQL change_column :sessions, :audience_limit, :integer
    #Session.update_all('audience_limit = NULL')
    remove_column :sessions, :audience_limit
    add_column :sessions, :audience_limit, :integer
  end

  def self.down
    # Doesn't work in PostgreSQL 'change_column :sessions, :audience_limit, :string
    remove_column :sessions, :audience_limit
    add_column :sessions, :audience_limit, :string
  end
end
