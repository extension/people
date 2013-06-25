set :deploy_to, "/services/people/"
set :branch, 'master'
server 'people.extension.org', :app, :web, :db, :primary => true
