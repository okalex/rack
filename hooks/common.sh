install_root=`config-get install_root`
app_name=`config-get app_name`
repo_url=`config-get repo_url`
repo_branch=`config-get repo_branch`
repo_type=`config-get repo_type`
extra_packages=`config-get extra_packages`
port=`config-get port`
migrate_database=`config-get migrate_database`
seed_database=`config-get seed_database`
compile_assets=`config-get compile_assets`

root="$install_root/$app_name"

export RAILS_ENV=production
export RAILS_ROOT=$root

has_gem() {
  grep -q $1 $root/Gemfile
}
add_gem() {
  echo -e "\ngem '$1'\n" >> $root/Gemfile
  bundle_install
}
ensure_gem() {
  has_gem $1 || add_gem $1
}
bundle_install() {
  cd $root && bundle install
}

#db methods

database_version() {
  `cd $root && bundle exec rake db:version | awk '/Current version:/ { print $3 }'`
}

configure_database() {
  juju-log "Configure database"

  cat > "$root/config/database.yml" <<EOS
  $RAILS_ENV:
    adapter: $1
    database: $2
    host: $3
    pool: 5
    timeout: 5000
    username: $4
    password: $5
EOS
}

migrate_database() {
  if [[ $migrate_database == 'True' ]]; then
    juju-log "Migrate database"
    wrap_rake db:migrate
  fi
}

seed_database() {
  if [[ $seed_database == 'True' ]]; then
    juju-log "Seed database"
    wrap_rake db:seed
  fi
}

compile_assets() {
  if [[ $compile_assets == 'True' ]]; then
    juju-log 'Compile assets'
    wrap_rake assets:precompile
  fi
}

create_mongoid_indexes() {
  juju-log 'Create mongoid indexes'
  wrap_rake db:mongoid:create_indexes
}

run_rake() {
  cd $root && bundle exec rake $1
}

wrap_rake() {
  run_rake $1 || juju-log "Your either do not have Rake installed or trying to run task that doesn't exist."
}

# global methods

requires_restart() {
  for relation_id in $(relation-ids website); do
    relation-set -r $relation_id updated_at=`date +%s`
  done
}

exit_if_blank() {
  if [ -z "$1" ] ; then
      juju-log "$2 not set yet."
      exit 0
  fi
}

# rescue methods

configure_resque() {
  juju-log "Configuring Resque..."

  cat > "$root/config/resque.yml" <<EOS
$RAILS_ENV: $1:$2
EOS
}