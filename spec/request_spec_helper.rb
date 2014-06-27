def json_response
  JSON.parse(response.body)
end

def clean_redis
  REDIS.flushall
end