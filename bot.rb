require 'bundler/setup'
require 'cinch'
require 'cinch/plugins/identify'
require 'cinch/plugins/basic_ctcp'
require 'json'
require_relative 'stats.rb'
require_relative 'reg_check.rb'

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
    config.plugins.plugins = [
        Stats,
        RegCheck,
        Cinch::Plugins::Identify,
        Cinch::Plugins::BasicCTCP
    ]
    config.plugins.options[Cinch::Plugins::Identify] = {
        :username => settings['nickserv']['nick'],
        :password => settings['nickserv']['pass'],
        :type     => :nickserv,
    }
    config.plugins.options[Cinch::Plugins::BasicCTCP][:reply] = {
        :version  => 'StatsBot, an IRC statistics bot by /u/flotwig.',
        :source   => 'https://github.com/flotwig/StatsBot'
    }
    config.plugins.options[RegCheck] = {
        :check => settings['check_registered'],
        :mode => settings['registered_mode']
    }
  end
end

cinch.start