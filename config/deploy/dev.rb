set :deploy_to, "/services/people/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
server 'dev.people.extension.org', :app, :web, :db, :primary => true
