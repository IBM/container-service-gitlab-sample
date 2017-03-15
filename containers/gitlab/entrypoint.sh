#!/bin/sh
set -x

DB_HOST=${DB_HOST:-postgresql}
DB_PORT=${DB_PORT:-5432}
REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PORT_NUM=${REDIS_PORT_NUM:-6379}

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


update_gitlab_conf() {
cd /home/git/gitlab/config
sed -ie 's!default: /home/git/repositories!default: /home/git/data/repositories!g' gitlab.yml

chmod 775 /home/git/data
adduser git root
sudo -u git mkdir /home/git/data/repositories
sudo -u git chmod 755 /home/git/data/repositories
delgroup git root
chmod 755 /home/git/data
}


setup_database() {
cd /home/git/gitlab

RS=$(PG_PASSWORD=${DB_PASS} psql -h ${DB_HOST} -p ${DB_PORT} -U git -d gitlabhq_production -Atwc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
if [[ $RS -eq 0  ]]; then
	sudo -u git -H force=yes bundle exec rake gitlab:setup RAILS_ENV=production
fi

}

start_gitlab() {
app_user="git"
workhorse_dir="/home/${app_user}/gitlab-workhorse"

cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=redis://${REDIS_HOST}:${REDIS_PORT_NUM} RAILS_ENV=production # SKIP_STORAGE_VALIDATION=true

WORKHORSE_OPTIONS="-authBackend http://127.0.0.1:8080"
PATH=$workhorse_dir:$PATH /home/git/gitlab-workhorse/gitlab-workhorse $WORKHORSE_OPTIONS &

sudo -u git -H RAILS_ENV=production bin/background_jobs start &
sudo -u git -H RAILS_ENV=production bin/web start &

nginx -g "daemon off;"
}

create_database_config
create_redis_config
setup_database
update_nginx_conf
update_gitlab_conf
start_gitlab
