config = YAML.load_file("#{RAILS_ROOT}/config/config.yml")

::AppConfig = config
# Commented out so Heroku Sendgrid plugin takes controll of mail config
#ActionMailer::Base.smtp_settings = config[:smtp_settings]
ActionMailer::Base.default_url_options[:host] = config[:host]
