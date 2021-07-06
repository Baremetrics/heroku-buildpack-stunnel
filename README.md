# Heroku buildpack Stunnel

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows an application to use an [stunnel](http://stunnel.org) to connect securely to
any service that has its own stunnel server configured.

## Usage

First, ensure that the service to which you'd like to connect has stunnel configured and running.

Then set this buildpack as your initial buildpack with:

```console
$ heroku buildpacks:add https://github.com/Baremetrics/heroku-buildpack-stunnel.git -a <your-app-name>
```

Then confirm you are using this buildpack as well as your language buildpack like so:

```console
heroku buildpacks -a baremetrics-stage                             
=== baremetrics-stage Buildpack URLs
1. https://github.com/Baremetrics/heroku-buildpack-stunnel.git
2. https://github.com/DataDog/heroku-buildpack-datadog.git
3. heroku/nodejs
4. heroku/ruby
```

For more information on using multiple buildpacks check out [this devcenter article](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app).

Next, for each process that should connect to a server securely, you will need to preface the command in
your `Procfile` with `bin/start-stunnel`. In this example, we want the `web` process to use
a secure connection to a server.  The `worker` process doesn't interact with our DB server, so
`bin/start-stunnel` was not included:

    $ cat Procfile
    web:    bin/start-stunnel bundle exec unicorn -p $PORT -c ./config/unicorn.rb -E $RACK_ENV
    worker: bundle exec rake worker

We're then ready to deploy to Heroku with an encrypted connection between the dynos and our
DB server.

## Configuration

The buildpack will install and configure stunnel to connect to one or more servers configured as a list in the `STUNNEL_URLS` variable over a SSL connection. Prepend `bin/start-stunnel`
to any process in the Procfile to run stunnel alongside that process.
e.g.
    $ heroku config:add STUNNEL_URLS="MYSQL_DATABASE_URL PG_DATABASE_URL"

Note that stunnel will use whatever port you have condigured in your MYSQL_DATABASE_URL as a refernce for the stunnel connection. The formula to decide ont he stunnel server port is `[port in connection string] - 1` 
The following parameters are required in the db connection string:
`schema://:password@host:port/dbname`
It is also possible (and advised) to pass the username, e.g.
`schema://username:password@host:port/dbname`
Note that all query params that would appeat after the dbname would pass as is
Example of connection string and how will it translated in the stunnel configuration:
 
 `MYSQL_DATABASE_URL=mysql2://username:password@host:3306/dbname`
 
 Will set the following configuration on the stunnel client:
 
 ```bash
 [MYSQL_DATABASE_URL]
    client = yes
    accept = 127.0.0.1:43421
    connect = host:3305
    retry = no
 ```
 Make sure the port 3305 is open on your server.

### Stunnel settings

Some settings are configurable through app config vars at runtime:

- ``STUNNEL_ENABLED``: Default to true, enable or disable stunnel.
- ``STUNNEL_LOGLEVEL``: Default is `notice`, set to `info` or `debug` for more verbose log output.
