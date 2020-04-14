# frozen_string_literal: true

require 'sinatra/activerecord/rake'

require 'rake/testtask'
require 'open-uri'

require './app'

Rake.add_rakelib('tasks/**/*')

task default: :spec

# The command which runs the app.
RUN_COMMAND = 'bin/rackup'

desc 'Load the application environment for tasks that require it.'
task :environment do
end

desc 'Override Sinatra ActiveRecord Rake environment'
Rake::Task.define_task('db:environment') do
  Rake::Task[:environment].invoke
end

##
# logging
#
# @var task         string     [required] name of the task which wants to log stuff
# @var message      string     [required] the message which should get logged
# @var environment  string     [required] the environment to run the rake task
def logging(task: nil, message: nil, environment: nil)
  File.open($_CONFIG['system']['files']['rake_log'], 'ab') do |file|
    if environment.nil?
      file.write("#{Time.now} - #{task} -> #{message}\n")
    else
      file.write("#{Time.now} - #{environment} - #{task} -> #{message}\n")
    end
  end
end

def rake_presenter
  puts '#----------------------------------------------------'
  puts "# Begin task #{Rake.application.top_level_tasks.first} for environment: #{ENV['RACK_ENV']} at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  puts

  yield if block_given?

  puts
  puts '#----------------------------------------------------'
  puts "# End task #{Rake.application.top_level_tasks.first} for environment: #{ENV['RACK_ENV']} at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
end
