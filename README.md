# Nextcloud on Dokku
> This is a complete overhaul of the initial fork from @dionysio that has been tested, confirmed working and used in production for Nextcloud 18.

With recent versions of Nextcloud, it became super easy to run `nextcloud` under dokku:

```sh
dokku postgres:create nextcloud
dokku apps:create nextcloud
dokku postgres:link nextcloud nextcloud
```

Then, from your machine, after cloning this repo and adding `dokku` as a remote:

```sh
git push dokku
```

Now back to your dokku server!

```sh
dokku domains:add <your domain>
dokku letsencrypt nextcloud
# Replace this path with where you want to store user files (can be a network disk).
mkdir -p /var/lib/dokku/data/storage/nextcloud/data
chown www-data:www-data /var/lib/dokku/data/storage/nextcloud/data

# Replace this path with where you want to store Nextcloud config (can be a network disk, but this'll make serving webpages much slower)
mkdir -p /var/lib/dokku/data/storage/nextcloud/config
chown www-data:www-data /var/lib/dokku/data/storage/nextcloud/config

dokku storage:mount nextcloud /var/lib/dokku/data/storage/nextcloud/data:/var/www/html/data
dokku storage:mount nextcloud /var/lib/dokku/data/storage/nextcloud/config:/var/www/html/config
# required to create the mount files for some reason
dokku ps:restart nextcloud

# You're nearly done! Visit <your domain> to finish configuration.
# For the database, select postgres; you'll find the database credentials by running `dokku config nextcloud` and looking for DATABASE_URL: postgres://USER:PASSWORD@HOST:PORT/nextcloud
```

## Tweaks
Because you're running with Dokku as a reverse proxy, you'll need to change your config.php file under /var/www/html/data to add this:

```
'overwriteprotocol' => 'https'
```

Make sure the value for `'overwrite.cli.url'` starts with https.

You'll also need to allow large uploads to your server if you're planning to use client synchronisation.

```sh
mkdir /home/dokku/nextcloud/nginx.conf.d/
echo 'client_max_body_size 50000m;' > /home/dokku/nextcloud/nginx.conf.d/upload.conf
echo 'proxy_read_timeout 600s;' >> /home/dokku/nextcloud/nginx.conf.d/upload.conf
chown dokku:dokku /home/dokku/nextcloud/nginx.conf.d/upload.conf
service nginx reload
```

## Removing
If you're unhappy with your setup, this'll remove everything forever:
```
dokku apps:destroy nextcloud
dokku postgres:destroy nextcloud
rm -rf  /var/lib/dokku/data/storage/nextcloud
```
