require 'cinch'
require 'cinch/plugins/identify'
require 'json'
require_relative 'stats.rb'

cinch = Cinch::Bot.new do
  settings = JSON.load(open('settings.json','r'))
  configure do |config|
    config.server     = settings['server']
    config.port       = settings['port']
    config.password   = settings['pass']
    config.ssl.use    = settings['ssl']
    config.ssl.verify = false
    config.channels   = []
    config.nick       = settings['identity']['nick']
    config.user       = settings['identity']['ident']
    config.messages_per_second = 1000
    config.server_queue_size = 1000
    config.plugins.prefix = '!'
    config.plugins.plugins = [Stats,Cinch::Plugins::Identify]
    config.plugins.options[Cinch::Plugins::Identify] = {
        :username => settings['nickserv']['nick'],
        :password => settings['nickserv']['pass'],
        :type     => :nickserv,
    }
  end
end

cinch.start