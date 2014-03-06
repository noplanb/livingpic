require 'resque/tasks'

namespace :resque do
  desc 'Just make sure the environment is loaded when workers are started.'
  task :setup => :environment do
  end
end

