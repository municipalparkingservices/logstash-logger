module LogStashLogger
  module Device
    class Base
      MAX_BYTE_SIZE = 8192

      attr_reader :io
      attr_accessor :sync

      def initialize(opts={})
        @sync = opts[:sync]
      end

      def to_io
        @io
      end

      def write(message)
        unless message.bytesize > MAX_BYTE_SIZE
          @io.write(message)
        else
          write_to_file(message)
        end
      end

      def flush
        @io && @io.flush
      end

      def close
        @io && @io.close
      rescue => e
        warn "LOGSTASHFAIL #{self.class} - #{e.class} - #{e.message}"
      ensure
        @io = nil
      end

      def limit_large_logs(dirname)
        # Sort these so that the oldest file is always on top
        large_logs = Dir["/tmp/#{dirname}/*"].sort
        ::File.delete(large_logs.first) if large_logs.count >= 50
      rescue => e
        warn "LOGSTASHFAIL #{self.class} - #{e.class} - #{e.message}"
      end

      def write_to_file(message)
        dirname = "error"
        Dir.mkdir("/tmp/#{dirname}") unless ::File.exists?("/tmp/#{dirname}")

        limit_large_logs(dirname)

        current_time_string = DateTime.now.strftime("%Y%m%dT%H%M%S%L")
        output_file_name = "large-log-#{current_time_string}.log"
        Dir.mkdir("/tmp/#{dirname}") unless ::File.exists?("/tmp/#{dirname}")
        ::File.open("/tmp/#{dirname}/#{output_file_name}", 'w') { |log_file| log_file.puts message }
      rescue => e
        warn "LOGSTASHFAIL #{self.class} - #{e.class} - #{e.message}"
      end
    end
  end
end
