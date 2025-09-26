require 'rubygems'
require 'bundler/gem_tasks'

$stdout.sync = true
$stderr.sync = true

# Change to the directory of this file.
Dir.chdir(File.expand_path("../", __FILE__))

GEMSPEC = Gem::Specification.load('vagrant-notify-forwarder.gemspec')
raise 'Unable to load vagrant-notify-forwarder.gemspec' unless GEMSPEC
GEM_PACKAGE = File.join('pkg', "#{GEMSPEC.name}-#{GEMSPEC.version}.gem")

namespace :dev do
  desc 'Install gems locally under vendor/bundle'
  task :bundle do
    sh "bundle config set --local path 'vendor/bundle'"
    sh "bundle install --path 'vendor/bundle'"
  end

  desc 'Build the plugin gem into pkg/'
  task :build => :bundle do
    Rake::Task['build'].reenable
    Rake::Task['build'].invoke
  end

  desc 'Install the freshly built gem into your Vagrant plugins'
  task :install => :build do
    sh "vagrant plugin install ./#{GEM_PACKAGE}"
  end

  desc 'Run vagrant up using the bundled environment and local plugin path'
  task :up => :bundle do
    sh 'bundle exec vagrant up'
  end

  desc 'Reload the running Vagrant environment via Bundler'
  task :reload => :bundle do
    sh 'bundle exec vagrant reload'
  end
end
