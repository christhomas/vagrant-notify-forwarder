module VagrantPlugins
  module VagrantNotifyForwarder
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :port
      attr_accessor :enable
      attr_accessor :run_as_root
      attr_accessor :binaries

      DEFAULT_BINARIES = {
        [:linux, :x86_64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.0.0/notify-forwarder-linux-x86_64.tar.gz',
          'cb595d193dea7608feabc9a8a87123076b96762ef1f956e06d3ae3ecef7a2424'
        ],
        [:linux, :arm64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.0.0/notify-forwarder-linux-arm64.tar.gz',
          '7561bc849fda68e2d55e43bd49e5b36fe652ae00695e29a540d2cf621269c49c'
        ],
        [:darwin, :x86_64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.0.0/notify-forwarder-darwin-x86_64.tar.gz',
          'f9ff18eee78c6f2eef4bd249335ca76ef02a54481e011ae5b79066b34f99aa70'
        ],
        [:darwin, :arm64] => [
          'https://github.com/christhomas/notify-forwarder/releases/download/v1.0.0/notify-forwarder-darwin-arm64.tar.gz',
          '0b12e048b7d37fa4ac0e990df9c0aeca0171468c82b6f2181ebf531b018a01e6'
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
