set :deploy_to, "/services/people/"
set :branch, 'master'
server 'sawgrass.vm.extension.org', :app, :web, :db, :primary => true
