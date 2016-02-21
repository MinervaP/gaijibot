require 'twitter'
require 'net/http'

class GaijiBot
  def initialize(conf)
    @conf = conf
    @client = Twitter::Streaming::Client.new do |config|
      config.consumer_key = conf["twitter_c_key"]
      config.consumer_secret = conf["twitter_c_sec"]
      config.access_token = conf["twitter_a_key"]
      config.access_token_secret = conf["twitter_a_sec"]
    end
  end

  def asperger(targets)
    @client.user(with: "user") do |tweet|
      next unless tweet.kind_of?(Twitter::Tweet)
      next if tweet.retweet?
      if targets.include?(tweet.user.screen_name)
        if tweet.user.protected?
          post_protected_tweet(tweet)
        else
          post_public_tweet(tweet)
        end
      end
    end
  end

  def post_slack(text, options={})
    Net::HTTP.post_form(URI.parse("https://slack.com/api/chat.postMessage"), {
      token: @conf["slack_token"],
      channel: @conf["slack_channel"],
      text: text,
      username: @conf["bot_name"],
      icon_url: @conf["bot_icon"]
    }.merge(options))
  end

  def post_public_tweet(tweet)
    post_slack(tweet.uri)
  end

  def post_protected_tweet(tweet)
    attachments = [{
      text: tweet.full_text,
      author_name: tweet.user.name,
      author_subname:  "@#{tweet.user.screen_name}",
      author_icon: tweet.user.profile_image_uri,
      author_link: tweet.uri,
    }]
    tweet.media.each_with_index do |m, i|
      attachments[i] ||= {}
      attachments[i].merge!({ fallback: tweet.uri, image_url: m.media_uri})
    end
    post_slack(tweet.uri, { attachments: attachments.to_json })
  end
end
