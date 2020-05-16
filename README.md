With recent versions of Nextcloud, it became super easy to run `nextcloud`:

```
dokku postgres:create nextcloud
dokku apps:create nextcloud
dokku postgres:link nextcloud nextcloud

# From your machine, with this repo:
git push dokku

# Back to the server!
dokku domains:add <your domain>
dokku letsencrypt nextcloud
# Replace the first path with where you want to store config and user files.
dokku storage:mount nextcloud /var/lib/dokku/data/storage/nextcloud:/var/www/html
# required to create the mount files for some reason
dokku ps:restart nextcloud

# You're nearly done! Visit <your domain> to finish configuration.
# For the database, select postgres; you'll find the database credentials by running dokku config nextcloud and looking for DATABASE_URL: postgres://USER:PASSWORD@HOST:PORT/nextcloud
```
