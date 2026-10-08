class FakeJsonHttp
  attr_reader :requests

  def initialize(replies_by_url = {}, &reply_for)
    @replies_by_url = replies_by_url
    @reply_for = reply_for
    @requests = []
  end

  def get(url, self_signed: false)
    reply(:get, url, nil)
  end

  def post(url, payload, self_signed: false)
    reply(:post, url, payload)
  end

  private

  def reply(method, url, payload)
    @requests << [ method, url, payload ]
    @reply_for ? @reply_for.call(url) : @replies_by_url.fetch(url)
  end
end
