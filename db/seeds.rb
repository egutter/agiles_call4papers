# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)
admin = User.create!(:first_name => 'admin', :last_name => 'admin', :username => 'admin', :email => 'admin@agiles.com', :password => 'qFr2x*P0', :password_confirmation => 'qFr2x*P0', :phone =>'012345567', :country => 'AR', :state => '', :city =>'Buenos Aires', :organization => 'agiles', :website_url => 'www.agiles.org', :bio => 'nada', :wants_to_submit => '0')
admin.add_role('admin')
admin.save!
