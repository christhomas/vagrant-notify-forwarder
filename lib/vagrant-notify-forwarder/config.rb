module VagrantPlugins
  module VagrantNotifyForwarder
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :port
      attr_accessor :enable
      attr_accessor :run_as_root
      attr_accessor :binaries

      DEFAULT_BINARIES = {
        [:linux, :x86_64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.0.0/notify-forwarder-linux_x86_64',
          'c50ba2102bec60f449dffd2039b2432b53f5f89a8ffe1f218383552b600b8004'
        ],
        [:linux, :arm64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.0.0/notify-forwarder-linux_arm64',
          '86c05c55d71e73785416630625c5f38150f54a933ba9d8bf9b6504a40472dd85'
        ],
        [:darwin, :x86_64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.0.0/notify-forwarder-darwin_x86_64',
          'f65ab0e87d688d38f2beb7f7030461f05a39e5937fd14cfb0a3a57d2008e751a'
        ],
        [:darwin, :arm64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.0.0/notify-forwarder-darwin_arm64',
          '212ab39aa4d534fc6f93fa5b0c04eaa066c8c79394eb6b80423fcb88db5ae236'
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
        @enable = true if @enable == UNSET_VALUE
        @run_as_root = true if @run_as_root == UNSET_VALUE
        @binaries = prepare_binaries(@binaries)
      end

      private

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
