require 'vagrant-notify-forwarder/utils'

module VagrantPlugins
  module VagrantNotifyForwarder
    module Action
      class StartHostForwarder
        def initialize(app, env)
          @app = app
        end

        def ensure_binary_downloaded(env)
          os = Utils.parse_os_name `uname -s`
          hardware = Utils.parse_hardware_name `uname -m`

          env[:ui].error "Notify-forwarder: Unsupported host operating system (detected: #{os})" if os == :unsupported
          env[:ui].error "Notify-forwarder: Unsupported host hardware (detected: #{hardware})" if hardware == :unsupported

          if os != :unsupported and hardware != :unsupported
            Utils.ensure_binary_downloaded env, os, hardware
          end
        end

        def start_watcher(env, command)
          pid = Process.spawn command
          Process.detach(pid)

          pidfile = Utils.host_pidfile env
          pidfile.open('a+') do |f|
            f.write("#{pid}\n")
          end
        end

        def call(env)
          if env[:machine].config.notify_forwarder.enable
            port = env[:machine].config.notify_forwarder.port
            env[:machine].config.vm.network :forwarded_port, host: port, guest: port, protocol: 'udp'
          end

          @app.call env

          if env[:machine].config.notify_forwarder.enable
            path = ensure_binary_downloaded env
            return unless path

            env[:machine].config.vm.synced_folders.each do |id, options|
              unless options[:disabled]
                hostpath = File.expand_path(options[:hostpath], env[:root_path])
                guestpath = options[:guestpath]

                args = "watch -c 127.0.0.1:#{port} #{hostpath} #{guestpath}"
                start_watcher env, "#{path} #{args}"
                env[:ui].detail("Notify-forwarder: host sending file change notifications to 127.0.0.1:#{port}")
                env[:ui].detail("Notify-forwarder: host forwarding notifications on #{hostpath} to #{guestpath}")
              end
            end
          end
        end
      end
    end
  end
end
