require 'heroku/command'

class Heroku::Command::Health < Heroku::Command::Base
  def index
    puts "Hiya"
  end
end
