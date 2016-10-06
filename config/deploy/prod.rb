set :deploy_to, "/services/people/"
set :branch, 'master'
set :vhost, 'people.extension.org'
set :deploy_server, 'people.aws.extension.org'
server deploy_server, :app, :web, :db, :primary => true
