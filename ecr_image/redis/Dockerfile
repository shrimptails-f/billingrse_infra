FROM redis:8.4-alpine

COPY redis.conf /usr/local/etc/redis/redis.conf

# Ensure owned by redis user and run non-root
RUN chown -R redis:redis /usr/local/etc/redis
USER redis

# Requirepass is injected at container start via environment variable (not baked into the image).
CMD ["sh", "-c", "exec redis-server /usr/local/etc/redis/redis.conf --requirepass \"${REDIS_PASSWORD:?REDIS_PASSWORD not set}\""]
