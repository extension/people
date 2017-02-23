set :deploy_to, "/services/people/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-people.extension.org'
set :deploy_server, 'dev-people.aws.extension.org'
server deploy_server, :app, :web, :db, :primary => true
