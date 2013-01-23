set :deploy_to, "/services/people/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'development'
end
server 'dev.people.extension.org', :app, :web, :db, :primary => true

if(ENV['REBUILD'] == 'true')
  after "deploy:update_code", "db:rebuild"
end