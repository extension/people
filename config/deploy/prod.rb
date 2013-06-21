set :deploy_to, "/services/people/"
set :branch, 'master'
server 'sawgrass.vm.extension.org', :app, :web, :db, :primary => true

if(ENV['SEED'] == 'true')
  after "deploy:migrations", "db:seed"
end