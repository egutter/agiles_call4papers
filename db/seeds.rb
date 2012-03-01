# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)
if (User.find_by_username('admin').nil?)
	admin = User.create!(:first_name => 'admin', :last_name => 'admin', :username => 'admin', :email => 'admin@agiles.com', :password => 'qFr2x*P0', :password_confirmation => 'qFr2x*P0', :phone =>'012345567', :country => 'AR', :state => '', :city =>'Buenos Aires', :organization => 'agiles', :website_url => 'www.agiles.org', :bio => '', :wants_to_submit => '0')
	admin.add_role('admin')
	admin.save!
end
Conference.destroy_all
Conference.create!(:name => 'Agiles 2012', :year => 2012, 
									 :url => 'http://agiles2012.agiles.org', 
									 :description_pt => "<p>A Conferência Latino Americana sobre Métodos Ágeis de Desenvolvimento de Software – <a href='http://agiles2012.agiles.org' target='_blank'>Agiles 2012</a> – é uma conferência internacional sem fins lucrativos organizada por representantes das principais comunidades ágeis latinoamericanas. O evento tem como propósito promover a comunicação e a colaboração entre seus integrantes visando à disseminação coordenada da cultura Ágil por tuda a região.</p><p> O Agiles 2012 acontecerá em Córdoba, no mês de Outubro, contando com cursos, apresentação de trabalhos e relatos de experiência provenientes de várias regiões, alem da participação de convidados reconhecidos internacionalmente.</p>",
									 :description_en => "<p>The Latin American Conference about Agile Methods – <a href='http://agiles2012.agiles.org' target='_blank'>Agiles 2012</a> – is a non-profitable conference organized by representatives of the main latin american agile communities. The event's goal is to promote communication and collaboration among its attendees aiming to disseminate the Agile culture in the whole region.</p><p> Agiles 2012 will be held in Córdoba, in the month of October, and will feature courses, work presentations and experience reports, as well as the presence of international guests.</p>",
									 :description_es => "<p>La conferencia Latino Americana sobre metodologías ágiles – <a href='http://agiles2012.agiles.org' target='_blank'>Agiles 2012</a> – es una conferencia sin fines de lucro organizada por representantes de toda las comunidades ágiles latinoamericanas. El objetivo del evento es promover la comunicación y la colaboración entre los participantes y difundir la cultura Ágil en toda la región.</p><p> Agiles 2012 será llevada a cabo en Córdoba, durante el mes de Octubre, contando con workshops, tutoriales, y reportes de experiencia, así como de la presencia de invitados internacionales.</p>",
									 :location => 'Córdoba')