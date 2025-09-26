# Vagrant file system notification forwarder plugin

A vagrant plugin that uses [notify-forwarder](https://github.com/mhallin/notify-forwarder) to
forward file system events from the host to the guest automatically on all shared folders.

This is useful for auto reloading file systems that rebuild when files change. Normally, they have
to use CPU intensive polling when watching shared folders. This plugin makes them able to use
inotify or similar for improved performance and reduced CPU usage.

## Installation and usage

```terminal
$ vagrant plugin install vagrant-notify-forwarder
$ vagrant reload
```

By default, this sets up UDP port 29324 for port forwarding. If you're already using this port, or
if you want to change it, add the following line to your `Vagrantfile`:

```ruby
config.notify_forwarder.port = 22020 # Or your port number
```

The server and guest binaries will be automatically downloaded from the notify-forwarder repo's
releases and verified with SHA256.

### Overriding binary sources

The plugin ships with a default map of download URLs and SHA256 checksums for each supported
`[os, hardware]` combination. You can override or extend the map via
`config.notify_forwarder.binaries`:

```ruby
config.notify_forwarder.binaries = {
  [:darwin, :arm64] => {
    url: "https://example.com/notify-forwarder-osx-arm64",
    sha256: "deadbeef..."
  },
  [:linux, :riscv64] => [
    "https://example.com/notify-forwarder-linux-riscv64",
    "cafebabe..."
  ]
}
```

You may supply each entry either as an array `[url, sha256]` or a hash with `:url`/`:sha256` keys.
Entries you omit continue using the built-in defaults.

Environment variables are expanded in URLs, so you can point to local binaries using values like
`$HOME`. For example:

```ruby
config.notify_forwarder.binaries = {
  [:darwin, :arm64] => [
    "file://$HOME/dev/notify-forwarder/osx-arm64",
    "deadbeef..."
  ]
}
```

Relative and `file://` URLs are also expanded to absolute paths on the host before download.

## Development

Use Bundler and the project `Rakefile` to keep all tooling local to the repository.

1. Install dependencies into `vendor/bundle/`:

   ```terminal
   rake dev:bundle
   ```

   The task sets `bundle config set --local path 'vendor/bundle'` and installs the gems. If you prefer to run it manually the first time, execute `bundle install --path vendor/bundle`.

2. Iterate on the plugin and rebuild when you want a packaged gem:

   ```terminal
   bundle exec rake dev:build
   ```

3. (Optional) Install the packaged gem into your user Vagrant plugin directory for testing the exact artifact:

   ```terminal
   bundle exec rake dev:install
   ```

4. Launch or reload your Vagrant environment using the local plugin path declared in `Gemfile`:

   ```terminal
   bundle exec rake dev:up
   bundle exec rake dev:reload
   ```

All commands run entirely within the repository—no global gems or system Vagrant plugins are modified. Remove `vendor/bundle/` if you need a clean slate before reinstalling.

### Permissions

The client in the guest OS will run as root by default, assuming passwordless `sudo` works. If this
does *not* work, you can disable privilege escalation in your `Vagrantfile`:

```ruby
config.notify_forwarder.run_as_root = false
```

## Supported operating systems

To conserve size and dependencies, the plugin downloads binaries for supported platforms. This
plugin supports the same host/guest platforms as `notify-forwarder` itself:

* FreeBSD 64 bit as guest,
* Linux 64 bit as host and guest, and
* Mac OS X 64 bit as host and guest.

If you're running an unsupported host or guest and want to disable this plugin for a specific
machine, add the following line to your `Vagrantfile`:

```ruby
config.notify_forwarder.enable = false
```

## Contributors

* [CharlieC3](https://github.com/CharlieC3)
* [hedinfaok](https://github.com/hedinfaok)
* [seff](https://github.com/seff)
