require 'yaml'
require './gaijibot'

conf = YAML.load_file("config.yml")
bot = GaijiBot.new(conf)
bot.asperger(ARGV)
