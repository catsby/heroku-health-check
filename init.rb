require 'heroku/command'
Dir[File.join(File.expand_path("../vendor", __FILE__), "*")].each do |vendor|
  $:.unshift File.join(vendor, "lib")
end

class Heroku::Command::Health < Heroku::Command::Base
  def index
    puts "=== Checking health for Memcache/Redis"
    memcaches = %w[MEMCACHIER MEMCACHE]
    puts "\n== Checking memcache services" unless memcaches.empty?
    memcaches.each do |provider|
      memcache_server = api.get_config_vars(app).body[provider+"_SERVERS"]
      if memcache_server
        check_memcache(memcache_server, provider)
      end
    end

    redis_uri = api.get_config_vars(app).body['REDISTOGO_URL']
    puts "\n== Checking redis services" unless redis_uri.nil?
    if redis_uri
      check_redis(redis_uri)
    end
  end

  private
  def check_memcache(server, provider)
    require 'dalli'
    puts "\nProvider: #{provider}"
    username = api.get_config_vars(app).body[provider+'_USERNAME']
    password = api.get_config_vars(app).body[provider+'_PASSWORD']
    memcache_client = Dalli::Client.new server, username: username, password: password, failover: false
    begin
      memcache_client.set 'heroku-health-check', 'OK'
      val = memcache_client.get 'heroku-health-check'
      memcache_client.delete 'heroku-heroku-check'
    rescue
      val = 'Fail'
    ensure
      puts "Checking #{provider.capitalize}... #{val} (checked #{server})"
    end
  end

  def check_redis(uri)
    uri_values = URI.parse(uri)
    require 'redis'
    redis_client = Redis.new(host: uri_values.host, port: uri_values.port, password: uri_values.password) 
    begin
      val = redis_client.set "heroku-health-check", "OK" 
      redis_client.del "heroku-health-check"
    rescue
      val = 'Fail'
    ensure
      puts "Checking Redis... #{val} (checked #{uri_values.host})"
    end
  end
end
