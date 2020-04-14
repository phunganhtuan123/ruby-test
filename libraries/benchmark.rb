class BenchmarkHelper
  class << self
    def memory_spent
      memory_before = `ps -o rss= -p #{Process.pid}`.to_i
      yield
      memory_after = `ps -o rss= -p #{Process.pid}`.to_i

      puts " - Memory: #{((memory_after - memory_before) / 1024.0).round(2)} MB"
    end

    def time_spent
      time = Benchmark.realtime do
        yield
      end

      print "Time: #{time.round(2)} seconds"
    end

    def time_memory_spent
      memory_spent do
        time_spent do
          yield
        end
      end
    end
  end
end
