require "redis_lock/lock"

class Redis

  # Convenience methods

  # @param key is a unique string identifying the object to lock, e.g. "user-1"
  # @options are as specified for RedisLock::Lock#lock (including :life)
  # @param options[:life] should be set, but defaults to 1 minute
  # @param options[:owner] may be set, but defaults to HOSTNAME:PID
  # @param options[:sleep] is used when trying to acquire the lock; milliseconds; defaults to 125.
  # @param options[:acquire] defaults to 10 seconds and can be used to determine how long to wait for a lock.
  def lock( key, options = {}, &block )
    acquire = options.delete(:acquire) || 10

    lock = RedisLock::Lock.new self, key, options

    if block_given?
      lock.lock(acquire, &block)
    else
      lock.lock(acquire)
      lock
    end
  end

  # Checks if lock is already acquired
  #
  # @param key is a unique string identifying the object to lock, e.g. "user-1"
  def locked?( key )
    RedisLock::Lock.new( self, key ).locked?
  end

  def unlock( key )
    RedisLock::Lock.new( self, key ).unlock
  end

end # Redis
