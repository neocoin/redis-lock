require "helper"
require "logger"

require 'redis_lock/helpers/redis'

describe RedisLock::Lock, redis: true do

  let(:non) { nil }
  let(:her) { "Alice" }
  let(:him) { "Bob" }
  let(:hers)       { RedisLock::Lock.new( redis, "alpha", owner: her ) }
  let(:her_same)   { RedisLock::Lock.new( redis, "alpha", owner: her ) }
  let(:his)        { RedisLock::Lock.new( redis, "alpha", owner: him ) }
  let(:his_other)  { RedisLock::Lock.new( redis, "beta",  owner: him ) }
  let(:past   ) { 1 }
  let(:present) { 2 }
  let(:future ) { 3 }

  it "can acquire and release a lock" do
    hers.lock do
      hers.should be_locked
    end
    hers.should_not be_locked
  end

  context "when using blocks" do

    it 'returns the return value of the block' do
      hers.lock do
        1
      end.should eql(1)
    end

    it "returns the return value of the lambda" do
      action = ->() { 1 }
      hers.lock( &action ).should eq(1)
    end

    it "passes the lock into a supplied block" do
      hers.lock do |lock|
        lock.should be_an_instance_of(RedisLock::Lock)
      end
    end

    it "passes the lock into a supplied lambda" do
      action = ->(lock) do
        lock.should be_an_instance_of(RedisLock::Lock)
      end
      hers.lock( &action )
    end

  end

  it "can prevent other use of a lock" do
    hers.lock do
      expect { his.lock; his.unlock }.to raise_exception
    end
    expect { his.lock; his.unlock }.to_not raise_exception
  end

  it "can lock two different items at the same time" do
    his.lock do
      expect { his_other.lock; his_other.unlock }.to_not raise_exception
      his.should be_locked
    end
  end

  it "does not support nesting" do
    hers.lock do
      expect { her_same.lock }.to raise_exception
    end
  end

  it "can acquire a lock" do
    hers.do_lock.should be_truthy
  end

  it "can release a lock" do
    hers.lock; hers.release_lock
  end

  it "can use a timeout" do
    hers.with_timeout(1) { true }.should be_truthy
    hers.with_timeout(1) { false }.should be_falsy
    # a few attempts are OK
    results = [ false, false, true ]
    hers.with_timeout(1) { results.shift }.should be_truthy
    # this is too many attemps
    results = [ false, false, false, false, false, false, false, false, false, false, true ]
    hers.with_timeout(1) { results.shift }.should be_falsy
  end

  it "does not take too long to time out" do
    start = Time.now.to_f
    hers.with_timeout(1) { false }
    time = Time.now.to_f - start
    time.should be_within(0.2).of(1.0)
  end

  it "can time out an expired lock" do
    hers.life = 1
    hers.lock
    # don't unlock it, let hers time out
    expect { his.lock(10); his.unlock }.to_not raise_exception
  end

  it "can extend the life of a lock" do
    hers.life = 1
    hers.lock
    hers.extend_life(100)
    expect { his.lock(10); his.unlock }.to raise_exception
    hers.unlock
  end

  it "can determine if it is locked" do
    hers.is_locked?( non, nil,    present ).should be_falsy
    hers.is_locked?( non, future, present ).should be_falsy
    hers.is_locked?( non, past,   present ).should be_falsy
    hers.is_locked?( her, nil,    present ).should be_falsy
    hers.is_locked?( her, future, present ).should be_truthy  # the only valid case
    hers.is_locked?( her, past,   present ).should be_falsy
    hers.is_locked?( him, nil,    present ).should be_falsy
    hers.is_locked?( him, future, present ).should be_falsy
    hers.is_locked?( him, past,   present ).should be_falsy
    # We leave [ present, present ] to be unspecified.
  end

  it "can detect broken or expired locks" do
    hers.is_deleteable?( non, nil,    present ).should be_falsy # no lock => not expired

    hers.is_deleteable?( non, future, present ).should be_truthy  # broken => expired
    hers.is_deleteable?( non, past,   present ).should be_truthy  # broken => expired
    hers.is_deleteable?( her, nil,    present ).should be_truthy  # broken => expired

    hers.is_deleteable?( her, future, present ).should be_falsy # current; not expired

    hers.is_deleteable?( her, past,   present ).should be_truthy  # expired

    # We leave [ present, present ] to be unspecified.
  end

  example "How to get a lock using the helper when passing a block" do
    redis.lock his do |lock|
      lock.should be_an_instance_of(RedisLock::Lock)
      :return_value_of_block
    end.should eql(:return_value_of_block)
  end

  example "How to get a lock using the helper when not passing a block" do
    lock = redis.lock his
    lock.should be_an_instance_of(RedisLock::Lock)

    begin
      lock.lock
    rescue RedisLock::Lock::LockNotAcquired => e
      e
    end.should be_an_instance_of(RedisLock::Lock::LockNotAcquired)

    lock.unlock
  end

end
