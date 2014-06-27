module Publish
  extend self

  def pubnub
    @pubnub ||= Pubnub.new(
     :publish_key   => 'pub-c-dd92ddd0-2263-4fbc-839d-8fa215f5a96c',
     :subscribe_key => 'sub-c-e34dadde-ecd9-11e3-b601-02ee2ddab7fe'
    )
  end

  def publish(channel, message)
    pubnub.publish(
     :channel  => channel,
     :message => message,
    ) { |data| puts data.response }
  end
end