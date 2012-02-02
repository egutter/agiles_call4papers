require 'open-uri'

APP_DIR = ARGV[0]
BACKUP_DIR = ARGV[1]

# run a command from your app's root directory
def cmd(str)
  return `cd #{APP_DIR}; #{str}`
end

puts('* Capturing backup...')
status = cmd('heroku pgbackups:capture --expire')

unless status.index("Storing... done").nil?
  # Backup captured
  backup_number = status.slice(/----backup--->\s+b\d{3}/).slice(16,4)
  puts("*** Backup captured: #{backup_number}.\nCapturing URL...")
  
  filename = "#{APP_DIR}/#{Time.now.strftime('%Y-%m-%d_%H%M%S')}-#{backup_number}.dump"
    
  backup_url = cmd("heroku pgbackups:url #{backup_number}")
  puts("*** URL captured: #{backup_url}\nDownloading backup to #{filename}...")
  
  open(filename, 'wb') do |file|
    file << open(backup_url).read
  end

  puts("*** Backup downloaded moving file #{APP_DIR}/#{filename} to #{BACKUP_DIR}")  
  
  move = `mv #{filename} "#{BACKUP_DIR}"`
  
  puts('* Done')
else
  puts "Error. Could not backup database.\nResponse:\n#{status}"
end
