require 'erb'

default_run_options[:pty] = true
stage_branches = { :production => "master",
                   :staging    => "edge" }

set :stages, %w(staging production)
set :default_stage, "production"
require 'capistrano/ext/multistage'

# Specify the name of your application
set :application, "openbrewcomp"

# Specify the location of the git repository
set :repository, "git://SCM_SERVER/#{application}.git"
set :branch, lambda { stage_branches[rails_env] }

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, lambda { "/var/www/rails/#{rails_env}/#{application}" }

# Update a cached copy of the repo instead of doing a full checkout.
# Be sure to amend the copy_exclude array to include any additional
# files or directories that should not be copied to the deploy tree.
set :deploy_via, :remote_cache
set :repository_cache, "repo"
set :copy_exclude, [ '.git', '.gitignore' ]

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git

role :app, "APP_SERVER"
role :web, "WEB_SERVER"
role :db,  "DB_SERVER", :primary => true

# Specify the owner of the deploy tree.
set :user, "www"

namespace :deploy do
  desc "Default to deploy:migrations"
  task :default, :roles => :app do
    deploy.migrations
  end

  # The after_setup and after_update_code tasks are adapted from
  # http://www.jvoorhis.com/articles/2006/07/07/managing-database-yml-with-capistrano
  # with mods for Capistrano 2.

  desc "Create database.yml in shared/config"
  task :after_setup, :roles => :app do
    database_config = ERB.new(<<-EOF).result(binding)
defaults: &defaults
  adapter: postgresql
  host: localhost
  username: <%= user %>
  encoding: unicode

#{rails_env}:
  database: <%= "#{application}_#{rails_env}" %>
  <<: *defaults

test:
  database: <%= "#{application}_test" %>
  <<: *defaults
EOF

    run "mkdir -p #{deploy_to}/#{shared_dir}/config"
    put database_config, "#{deploy_to}/#{shared_dir}/config/database.yml"
  end

  desc "Link in the production database.yml"
  task :after_update_code, :roles => :app do
    run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
  end

  # For initial load

  desc "Bootstrap the application. This should only be run on initial deployment."
  task :bootstrap do
    update
    migrate
    populate
    start
  end

  desc "Populate the database with the initial set of data"
  task :populate, :roles => :db, :only => { :primary => true } do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "production")

    run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} db:bootstrap"
  end

  # For passenger deployment

  desc "Not used with passenger"
  task :start, :roles => :app do
    # nothing
  end

  desc "Not used with passenger"
  task :stop, :roles => :app do
    # nothing
  end

  desc "Restart application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

end

namespace :passenger do
  desc "Passenger memory stats"
  task :memory, :roles => :app do
    sudo "passenger-memory-stats" do |channel, stream, data|
      puts data
    end
  end

  desc "Passenger status"
  task :status, :roles => :app do
    sudo "passenger-status" do |channel, stream, data|
      puts data
    end
  end
end

before("deploy:setup") { set :use_sudo, false }
before("deploy:cleanup") { set :use_sudo, false }

