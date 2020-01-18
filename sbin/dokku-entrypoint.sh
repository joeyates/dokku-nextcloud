#!/bin/sh


# parse db url, credit to pjz @ https://stackoverflow.com/a/17287984
# extract the protocol
proto="`echo $DATABASE_URL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
# remove the protocol
url=`echo $DATABASE_URL | sed -e s,$proto,,g`

# extract the user and password (if any)
userpass="`echo $url | grep @ | cut -d@ -f1`"
DB_PASS=`echo $userpass | grep : | cut -d: -f2`
if [ -n "$DB_PASS" ]; then
    DB_USER=`echo $userpass | grep : | cut -d: -f1`
else
    DB_USER=$userpass
fi

# extract the host
hostport=`echo $url | sed -e s,$userpass@,,g | cut -d/ -f1`
DB_PORT=`echo $hostport | grep : | cut -d: -f2`
if [ -n "$DB_PORT" ]; then
    DB_HOST=`echo $hostport | grep : | cut -d: -f1`
else
    DB_HOST=$hostport
fi

# extract the path (if any)
DB_NAME="`echo $url | grep / | cut -d/ -f2-`"

export POSTGRES_DB="${DB_NAME}"
export POSTGRES_USER="${DB_USER}"
export POSTGRES_PASSWORD="${DB_PASS}"
export POSTGRES_HOST="${DB_HOST}"

# hacky and dumb as hell, but we have to override the parent entrypoint,
# because they are doing some weird rsync fuckery there which deletes stuff like nginx.conf.sigil

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su - www-data -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

installed_version="0.0.0.0"
if [ -f /var/www/html/version.php ]; then
    # shellcheck disable=SC2016
    installed_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"
fi
# shellcheck disable=SC2016
image_version="$(php -r 'require "/usr/src/nextcloud/version.php"; echo implode(".", $OC_Version);')"

if version_greater "$installed_version" "$image_version"; then
    echo "Can't start Nextcloud because the version of the data ($installed_version) is higher than the docker image version ($image_version) and downgrading is not supported. Are you sure you have pulled the newest image version?"
    exit 1
fi

if version_greater "$image_version" "$installed_version"; then
    if [ "$installed_version" != "0.0.0.0" ]; then
        run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
    fi
    if [ "$(id -u)" = 0 ]; then
        rsync_options="-rlDog --chown www-data:root"
    else
        rsync_options="-rlD"
    fi
    rsync $rsync_options --delete --exclude /nginx.conf.sigil --exclude /nginx.conf.d/ --exclude /config/ --exclude /data/ --exclude /custom_apps/ --exclude /themes/ /usr/src/nextcloud/ /var/www/html/

    for dir in nginx.conf.sigil nginx.conf.d config data custom_apps themes; do
        if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
            rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
        fi
    done

    if [ "$installed_version" != "0.0.0.0" ]; then
        run_as 'php /var/www/html/occ upgrade'

        run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after
        echo "The following apps have been disabled:"
        diff /tmp/list_before /tmp/list_after | grep '<' | cut -d- -f2 | cut -d: -f1
        rm -f /tmp/list_before /tmp/list_after
    fi
fi

exec "$@"
