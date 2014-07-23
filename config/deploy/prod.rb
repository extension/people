set :deploy_to, "/services/people/"
set :branch, 'master'
set :vhost, 'people.extension.org'
server vhost, :app, :web, :db, :primary => true
