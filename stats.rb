require 'cinch'
require 'json'
require 'addressable/uri'
class Stats
  include Cinch::Plugin
  match 'stats',      :method => :stats
  match 'stats-help', :method => :help
  listen_to :connect, :method => :connect
  listen_to :invite,  :method => :invite
  listen_to :nick,    :method => :nick
  listen_to :topic,   :method => :topic
  listen_to :channel, :method => :channel
  listen_to :action,  :method => :action
  listen_to :leaving, :method => :leaving
  listen_to :join,    :method => :join
  def initialize(*args)
    super
    @start = Time::now
    @beans = {
        :nick => 0,
        :topic => 0,
        :channel => 0,
        :action => 0,
        :leaving => 0,
        :join => 0
    }
    begin
        @channels = File.readlines('channels.txt')
        @settings = JSON.load(open('settings.json','r'))
    rescue => det
        raise "settings.json and channels.txt must be properly created before running the bot."
	end
  end
  def connect(msg)
    if @settings.has_key?('oper')
      bot.oper(@settings['oper']['pass'],@settings['oper']['user'])
    end
    bot.set_mode('B')
    bot.set_mode('I')
    # channels are joined within the plugin because it is important to oper
    # up before joining hundreds of channels
    @channels.each do |channel|
      bot.join(channel)
    end
    save_channels
  end
  def invite(msg)
    if validate_channel_name(msg.channel.to_s)
      msg.channel.join
    else
      msg.user.notice('I cannot join that channel.')
    end
  end
  def stats(msg)
    msg.reply(sprintf('Stats for this channel can be found at %s%s.html',@settings['locations']['url'],Addressable::URI.encode(msg.channel.to_s).sub('#','%23')))
  end
  def help(msg)
    msg.reply('Help is online at https://github.com/flotwig/StatsBot/blob/master/USERGUIDE.md')
    diff = (Time::now - @start).to_i
    msg.reply(sprintf('This instance has logged %d events (%d nick changes, %d topic changes, %d channel messages, %d actions, %d parts and quits, and %d joins) over %d days, %d hours, and %d minutes of uptime for an event rate of %.2f events/minute.',
        @beans.values.inject(:+),@beans[:nick],@beans[:topic],@beans[:channel],@beans[:action],@beans[:leaving],@beans[:join],(diff/(24*3600)).to_i,((diff%(24*3600))/3600).to_i,((diff%(3600))/60).to_i,Float(@beans.values.inject(:+))/(Float(diff)/Float(60))))
  end
  def log(msg,str,channel=nil)
    if channel.nil?
      channel = msg.channel
    end
    line = msg.time.strftime('[%H:%M:%S] ')
    line += str
    line += "\n"
    filename = sprintf('%s/%s/%s.log',@settings['locations']['logs'],channel.to_s,msg.time.strftime('%Y-%m-%d'))
    fd = File.open(filename,'a')
    fd.puts(line)
    fd.close
  end
  def save_channels
    txt = File.open('channels.txt','w')
    cfg = File.open('pisg.cfg','w')
    cfg.puts(IO.read('pisgPrefix.cfg')) if File.exists?('pisgPrefix.cfg')
    bot.channels.each do |channel|
      txt.puts channel.to_s
      cfg.puts sprintf('<channel="%s">
                            OutputFile="%s/%s.html"
                            LogDir="%s/%s/"
                        </channel>
                       ',channel.to_s,@settings['locations']['stats'],channel.to_s,@settings['locations']['logs'],channel.to_s)
    end
    txt.close
    cfg.close
    if File.exists?('./indexTemplate.html')
      File.open(@settings['locations']['stats']+'index.html','w').puts(IO.read('indexTemplate.html').sub('%lis%',
          bot.channels.map { |channel| sprintf '<li><a href="%s.html">%s</a></li>', Addressable::URI.encode(channel.to_s).sub('#','%23'), channel.to_s
      }.join))
    end
    @channels = File.readlines('channels.txt')
  end
  def validate_channel_name(channel_name)
    # check that it doesn't do any path traversal
    # check that it doesn't contain illegal filename characters
    # check that it doesn't have any html tags in it

    channel_name.scan(/[\.\/\\<>]/).count == 0
  end
  # various interpreters for logged events below
  def nick(msg)
    str = sprintf('*** %s is now known as %s',msg.user.last_nick,msg.user.nick)
    # gotta log to every channel this user is in
    (msg.user.channels & msg.bot.channels).each do |channel|
      log(msg,str,channel)
    end
    @beans[:nick]+=1
  end
  def topic(msg)
    str = sprintf('*** %s changes topic to %s',msg.user.nick,msg.channel.topic)
    log(msg,str)
    @beans[:topic]+=1
  end
  def channel(msg)
    str = sprintf('<%s> %s',msg.user.nick,msg.message)
    log(msg,str)
    @beans[:channel]+=1
  end
  def action(msg)
    str = sprintf('*** %s %s',msg.user.nick,msg.action_message)
    log(msg,str)
    @beans[:action]+=1
  end
  def leaving(msg,leaver)
    if leaver.nick == bot.nick
      save_channels
    end
    case msg.command
      when 'KICK'
        str = sprintf('*** %s was kicked by %s (%s)',leaver.nick,msg.user.nick,msg.message)
      when 'PART'
        str = sprintf('*** Parts: %s (%s)',leaver.nick,msg.message)
      when 'QUIT'
        str = sprintf('*** Quits: %s (%s)',leaver.nick,msg.message)
      else
        return
    end
    log(msg,str)
    @beans[:leaving]+=1
  end
  def join(msg)
    if msg.user.nick == bot.nick and validate_channel_name(msg.channel.to_s)
      logdir = sprintf('%s/%s/',@settings['locations']['logs'],msg.channel.to_s)
      Dir.mkdir(logdir) unless File.directory?(logdir)
      save_channels
    end
    str = sprintf('*** Joins: %s (%s@%s)',msg.user.nick,msg.user.user,msg.user.host)
    log(msg,str)
    @beans[:join]+=1
  end
end