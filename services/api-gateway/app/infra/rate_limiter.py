import redis

from app.core.config import get_settings


class RateLimiter:
    def __init__(self) -> None:
        self.client = redis.Redis.from_url(get_settings().redis_url, decode_responses=True)

    def allow(self, key: str, limit: int = 60, window_seconds: int = 60) -> bool:
        try:
            pipe = self.client.pipeline()
            now = int(__import__("time").time())
            window_key = f"rate_limit:{key}:{now // window_seconds}"
            pipe.incr(window_key)
            pipe.expire(window_key, window_seconds)
            result = pipe.execute()
            return result[0] <= limit
        except redis.exceptions.RedisError:
            return True
