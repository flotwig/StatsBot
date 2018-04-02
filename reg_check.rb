require 'cinch'
class RegCheck
  include Cinch::Plugin
  listen_to :join, :method => :join
  listen_to :mode_change, :method => :mode_change

  def join(msg)
    if config[:check] && (msg.user.nick == bot.nick) && !msg.channel.modes[config[:mode]]
      msg.channel.part('I do not stay in unregistered channels.')
    end
  end

  def mode_change(msg, modes)
    modes.each do |direction, mode, _param|
      if config[:check] && (direction != :add) && (mode == config[:mode])
        msg.channel.part('I do not stay in unregistered channels.')
      end
    end
  end
end