#!/bin/sh

DB_HOST=${DB_HOST:-$POSTGRESQL_PORT_5432_TCP_ADDR}
DB_PORT=${DB_PORT:-$POSTGRESQL_PORT_5432_TCP_PORT}
REDIS_HOST=${REDIS_HOST:-$REDIS_PORT_6379_TCP_ADDR}
REDIS_PORT_NUM=${REDIS_PORT_NUM:-$REDIS_PORT_6379_TCP_PORT}

create_database_config() {
cat <<EOF > /home/git/gitlab/config/database.yml
#
# PRODUCTION
#
production:
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_production
  pool: 10
  username: git
  password: "${DB_PASS}"
  host: ${DB_HOST}
  port: ${DB_PORT}
EOF
}


create_redis_config() {
cat <<EOF > /home/git/gitlab/config/resque.yml
production:
  url: redis://${REDIS_HOST}:${REDIS_PORT_NUM}
EOF
}



update_nginx_conf() {
cp /home/git/gitlab/lib/support/nginx/gitlab /etc/nginx/conf.d/default.conf
sed -ie 's/server unix:.*\.socket/server localhost:8181/' /etc/nginx/conf.d/default.conf
sed -ie 's/events {/pid \/var\/run\/nginx.pid;\n\nevents {/' /etc/nginx/nginx.conf
}


setup_database() {

cd /home/git/gitlab

RS=$(PG_PASSWORD=${DB_PASS} psql -h ${DB_HOST} -p ${DB_PORT} -U git -d gitlabhq_production -Atwc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")

if [[ -z $RS ]]; then 
	sudo -u git -H force=yes bundle exec rake gitlab:setup RAILS_ENV=production
fi

}

start_gitlab() {
app_user="git"
workhorse_dir="/home/${app_user}/gitlab-workhorse"

cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=redis://${REDIS_HOST}:${REDIS_PORT_NUM} RAILS_ENV=production SKIP_STORAGE_VALIDATION=true

WORKHORSE_OPTIONS="-authBackend http://127.0.0.1:8080"
PATH=$workhorse_dir:$PATH /home/git/gitlab-workhorse/gitlab-workhorse $WORKHORSE_OPTIONS &

sudo -u git -H RAILS_ENV=production bin/background_jobs start &
sudo -u git -H RAILS_ENV=production bin/web start &

nginx -g "daemon off;" &
}

create_database_config
create_redis_config
setup_database
update_nginx_conf
start_gitlab

exec "$@"
