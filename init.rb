require 'heroku/command'
Dir[File.join(File.expand_path("../vendor", __FILE__), "*")].each do |vendor|
  $:.unshift File.join(vendor, "lib")
end

class Heroku::Command::Health < Heroku::Command::Base
  def index
    puts "=== Checking health for Memcache/Redis"
    puts ""
    memcache_server = api.get_config_vars(app).body['MEMCACHE_SERVERS']
    if memcache_server
      check_memcache(memcache_server)
    end

    redis_uri = api.get_config_vars(app).body['REDISTOGO_URL']
    if redis_uri
      check_redis(redis_uri)
    end
  end
  private
  def check_memcache(server)
    require 'dalli'
    username = api.get_config_vars(app).body['MEMCACHE_USERNAME']
    password = api.get_config_vars(app).body['MEMCACHE_PASSWORD']
    memcache_client = Dalli::Client.new server, username: username, password: password
    begin
      val = memcache_client.fetch 'heroku-health-check' do
        'Pass'
      end
    rescue
      val = 'Fail'
    ensure
      puts "Checking memcache... #{val} (checked #{server})"
    end
  end

  def check_redis(uri)
    uri_values = URI.parse(uri)
    require 'redis'

    redis_client = Redis.new(host: uri_values.host, port: uri_values.port, password: uri_values.password) 
    begin
      val = redis_client.set "hello", "world" 
    rescue
      val = 'Fail'
    ensure
      puts "Checking Redis... #{val} (checked #{uri_values.host})"
    end
  end
end
