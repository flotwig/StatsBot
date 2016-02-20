require 'cinch'
require 'JSON'
class Stats
  require 'cinch/plugin'
  @channels = readlines('channels.txt')
  @settings = JSON.load('settings.json')
  # logged events
  listen_to :nick,    :method => :nick
  listen_to :topic,   :method => :topic
  listen_to :channel, :method => :channel
  listen_to :action,  :method => :action
  listen_to :leaving, :method => :leaving
  listen_to :join,    :method => :join
  def initialize(*args)
    super
    unless @settings.oper.nil?
      bot.oper(@settings.oper.user,@settings.oper.pass)
    end
    # channels are joined within the plugin because it is important to oper
    # up before joining hundreds of channels
    @channels.each do |channel|
      bot.join(channel)
    end
    save_channels
  end
  def log(msg,str,channel=nil)
    if channel.nil?
      channel = msg.channel
    end
    line = msg.time.strftime('[%H:%M:%S] ')
    line += str
    line += "\n"
    filename = sprintf('logs/%s/%s.log',channel.to_s,msg.time.strftime('%Y-%m-%d)'))
    open(filename,'a').puts line
  end
  def save_channels
    txt = open('channels.txt','w')
    bot.channels.each do |channel|
      txt.puts channel.to_s
      logdir = sprintf('logs/%s/',channel.to_s)
      Dir.mkdir(logdir) unless File.directory?(logdir)
    end
    txt.close
    @channels = readlines('channels.txt')
  end
  # various interpreters for logged events below
  def nick(msg)
    str = sprintf('*** %s is now known as %s',msg.user.last_nick,msg.user.nick)
    # gotta log to every channel this user is in
    (msg.user.channels & msg.bot.channels).each do |channel|
      log(msg,str,channel)
    end
  end
  def topic(msg)
    str = sprintf('*** %s changes topic to %s',msg.user.nick,msg.channel.topic)
    log(msg,str)
  end
  def channel(msg)
    str = sprintf('<%s> %s',msg.user.nick,msg.message)
    log(msg,str)
  end
  def action(msg)
    str = sprintf('*** %s %s',msg.user.nick,msg.action_message)
    log(msg,str)
  end
  def leaving(msg,leaver)
    case msg.command
      when 'KICK'
        str = sprintf('*** %s was kicked by %s (%s)',leaver.nick,msg.user.nick)
      when 'PART'
        str = sprintf('*** Parts: %s (%s)',leaver.nick,msg.message)
      when 'QUIT'
        str = sprintf('*** Quits: %s (%s)',leaver.nick,msg.message)
      else
        return
    end
    log(msg,str)
  end
  def join(msg)
    str = sprintf('*** Joins: %s (%s@%s)',msg.user.nick,msg.user.user,msg.user.host)
    log(msg,str)
  end
end