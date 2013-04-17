set :deploy_to, "/services/people/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'development'
end
server 'dev.people.extension.org', :app, :web, :db, :primary => true

if(TRUE_VALUES.include?(ENV['REBUILD']))
  before "deploy", "deploy:web:disable"
  after "deploy:update_code", "deploy:db:rebuild"
  after "deploy", "deploy:web:enable"
end