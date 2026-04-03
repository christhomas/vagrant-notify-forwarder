module VagrantPlugins
  module VagrantNotifyForwarder
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :port
      attr_accessor :enable
      attr_accessor :run_as_root
      attr_accessor :binaries

      DEFAULT_BINARIES = {
        [:linux, :x86_64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.1.0/notify-forwarder-linux_x86_64',
          'baee3d06acccd126b37c8e9abd73cfd3ab3a83886eeb7572d36d9e0e38177a24'
        ],
        [:linux, :arm64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.1.0/notify-forwarder-linux_arm64',
          'a9bace65cbefc99db78e2e6fb47e55ed9df2ddf460c173dee7400d70de25c9c0'
        ],
        [:linux, :armv7l] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.1.0/notify-forwarder-linux_armv7l',
          '35e05a9af6cb50417919b0cc579b0ecdc87160be811bdac651488e3bbeb19bbe'
        ],
        [:darwin, :x86_64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.1.0/notify-forwarder-darwin_x86_64',
          '195fde3f90425c8e73b59d832f9cf5ecf98857fa3b992ba1bd6cfbdd749ca96a'
        ],
        [:darwin, :arm64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.1.0/notify-forwarder-darwin_arm64',
          'ac78532672553174bfc20e3c3d5d5c9fdccfe51d5fee5521bf34a3168d4acb34'
        ],
      }.freeze

      def initialize
        @port = UNSET_VALUE
        @enable = UNSET_VALUE
        @run_as_root = UNSET_VALUE
        @binaries = UNSET_VALUE
      end

      def finalize!
        @port = 29324 if @port == UNSET_VALUE
        @port = auto_correct_port(@port)
        @enable = true if @enable == UNSET_VALUE
        @run_as_root = true if @run_as_root == UNSET_VALUE
        @binaries = prepare_binaries(@binaries)
      end

      private

      def auto_correct_port(port)
        require 'socket'
        10.times do
          begin
            socket = UDPSocket.new
            socket.bind('127.0.0.1', port)
            socket.close
            return port
          rescue Errno::EADDRINUSE
            port += 1
          end
        end
        port
      end

      def prepare_binaries(value)
        defaults = DEFAULT_BINARIES.transform_values(&:dup)

        return defaults if value == UNSET_VALUE || value.nil?

        overrides = normalize_binary_map(value)
        defaults.merge(overrides) do |_key, _old, new_value|
          Array(new_value)
        end
      end

      def normalize_binary_map(map)
        map.each_with_object({}) do |(key, raw_value), acc|
          normalized_key = normalize_binary_key(key)
          acc[normalized_key] = normalize_binary_value(raw_value)
        end
      end

      def normalize_binary_key(key)
        tuple = Array(key).map do |segment|
          segment.respond_to?(:to_sym) ? segment.to_sym : segment
        end

        unless tuple.length == 2
          raise ArgumentError, "Binary definitions must use two-part keys like [:linux, :x86_64]"
        end

        [tuple[0], tuple[1]]
      end

      def normalize_binary_value(value)
        case value
        when Array
          value
        when Hash
          url = value[:url] || value['url']
          checksum = value[:sha256] || value['sha256']
          if url.nil? || checksum.nil?
            raise ArgumentError, "Binary definition hash must include :url and :sha256 keys"
          end
          [url, checksum]
        else
          raise ArgumentError, "Binary definition must be an Array [url, sha256] or Hash with :url/:sha256"
        end
      end
    end
  end
end
