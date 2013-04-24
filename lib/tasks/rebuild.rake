namespace :db do
  desc "(local dev) Drop:all, create, migrate, seed the database"
  task :rebuild => ['db:drop', 'db:create', 'db:migrate', 'db:seed']

  desc "(demo) drop, create, migrate, seed"
  task :demo_rebuild => ['db:drop', 'db:create', 'db:migrate', 'db:seed']
  
end