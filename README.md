# Nextcloud on Dokku
> This is a complete overhaul of the initial fork from @dionysio that has been tested, confirmed working and used in production for Nextcloud 18.

With recent versions of Nextcloud, it became super easy to run `nextcloud` under dokku:

```sh
dokku postgres:create nextcloud
dokku apps:create nextcloud
dokku postgres:link nextcloud nextcloud
```

# Redis

```sh
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
dokku redis:create nextcloud
dokku redis:link nextcloud nextcloud
```

Choose which version of Nextcloud you want to deploy from [Docker Hub](https://hub.docker.com/_/nextcloud).

```sh
dokku docker-options:add nextcloud build "--build-arg NEXTCLOUD_VERSION={{put your version here}}"
```

Then, from your machine, after cloning this repo and adding `dokku` as a remote:

```sh
git push dokku
```

Now back to your dokku server!

```sh
dokku domains:add nextcloud <your domain>
dokku letsencrypt:set nextcloud email EMAIL
dokku letsencrypt:enable nextcloud
# Replace this path with where you want to store user files (can be a network disk).
mkdir -p /var/lib/dokku/data/storage/nextcloud/data
chown www-data:www-data /var/lib/dokku/data/storage/nextcloud/data

# Replace this path with where you want to store Nextcloud config (can be a network disk, but this'll make serving webpages much slower)
mkdir -p /var/lib/dokku/data/storage/nextcloud/config
chown www-data:www-data /var/lib/dokku/data/storage/nextcloud/config

dokku storage:mount nextcloud /var/lib/dokku/data/storage/nextcloud/data:/var/www/html/data
dokku storage:mount nextcloud /var/lib/dokku/data/storage/nextcloud/config:/var/www/html/config
# required to create the mount files (we pushed earlier)
dokku ps:restart nextcloud

```
You're nearly done! Visit `<your domain>` to finish configuration.

Set up an admin account.
Click on "Storage & database".
Leave the data folder unchanged (`/var/www/html/data`)
For the database, **select Postgres**; you'll find the database credentials by running `dokku config nextcloud` and looking for DATABASE_URL: it'll look like postgres://USER:PASSWORD@HOST:PORT/DBNAME, just fill-in the fields on the webpage.

For instance, with `postgres://postgres:ae9e02101f9977e1fabb19f09605e486@dokku-postgres-nextcloud:5432/nextcloud`:

* Database user: postgres
* Database password: ae9e02101f9977e1fabb19f09605e486
* Database name: nextcloud
* Database host: dokku-postgres-nextcloud:5432

Click on finish setup.


## Tweaks
If you're planning to use desktop client,  because you're running with Dokku as a reverse proxy, you'll need to change your config.php file under `/var/lib/dokku/data/storage/nextcloud/config` to add this:

```
'overwriteprotocol' => 'https'
```

Make sure the value for `'overwrite.cli.url'` starts with https.

You'll also need to allow large uploads to your server:

```sh
mkdir /home/dokku/nextcloud/nginx.conf.d/
echo 'client_max_body_size 50000m;' > /home/dokku/nextcloud/nginx.conf.d/upload.conf
echo 'proxy_read_timeout 600s;' >> /home/dokku/nextcloud/nginx.conf.d/upload.conf
chown dokku:dokku /home/dokku/nextcloud/nginx.conf.d/upload.conf
service nginx reload
```

## Upgrading

To upgrade your Nextcloud version, you just need to choose which version
to upgrade to and deploy it.

Note: Before upgrading, it is wise to do a backup of your data, database
and config.

Nextcloud needs to be upgraded from major version to major version, so, if
you want to upgrade to version 22.0.0 and you're on 18.0.4,
you'll need to install some version of 19.x, 20.x and 21.x before installing
your desired version.

### Set The Version

Choose which version of Nextcloud you want to deploy from [Docker Hub](https://hub.docker.com/_/nextcloud).

### Script

You can update the version configured on Dokku with the script
`upgrade-dokku-nextcloud`.

Before running the script, you'll need to set DOKKU_HOST to
point to your Dokku host.

```sh
bin/upgrade-dokku-nextcloud {{NEW VERSION NUMBER}}
git push dokku
```

The following environment variables can be used to override defaults:

* DOKKU_USER - the remote Dokku user, defaults to 'dokku'
* DOKKU_NEXTCLOUD_APP - the name of the Dokku app, defaults to 'nextcloud'
* LOG_LEVEL - the verbosity of the script, the default, 1, gives minimal output, 2 is debug

### Manual Method

You need to **remove** old version setting and add the new one.

Here's an example where we **unset** 18.0.4-apache and set 22.0.0-apache

```sh
$ dokku docker-options:report nextcloud
=====> nextcloud docker options information
       Docker options build:          --build-arg NEXTCLOUD_VERSION=18.0.4 --link dokku.postgres.nextcloud:dokku-postgres-nextcloud
       Docker options deploy:         --link dokku.postgres.nextcloud:dokku-postgres-nextcloud --restart=on-failure:10 -v /var/lib/dokku/data/storage/nextcloud/config:/var/www/html/config -v /var/lib/dokku/data/storage/nextcloud/data:/var/www/html/data
       Docker options run:            --link dokku.postgres.nextcloud:dokku-postgres-nextcloud -v /var/lib/dokku/data/storage/nextcloud/config:/var/www/html/config -v /var/lib/dokku/data/storage/nextcloud/data:/var/www/html/data
$ dokku docker-options:remove nextcloud build "--build-arg NEXTCLOUD_VERSION=18.0.4"
$ dokku docker-options:add nextcloud build "--build-arg NEXTCLOUD_VERSION=22.0.0"
$ git push dokku
```

### Deploy

Now you can just deploy as usual

```sh
git push dokku
```

## Uninstalling
If you're unhappy with your setup, this'll remove everything *forever*:
```
dokku apps:destroy nextcloud
dokku postgres:destroy nextcloud
rm -rf  /var/lib/dokku/data/storage/nextcloud
```
