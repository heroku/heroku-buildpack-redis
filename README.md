# Heroku buildpack: Redis

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows an application to use an [stunnel](http://stunnel.org) to connect securely to
Heroku Redis and other stunnel'ed services.  It is meant to be used in conjunction with other buildpacks.

## Usage

First you need to set this buildpack as your initial buildpack with:

```console
$ heroku buildpacks:set https://github.com/PeriscopeData/heroku-buildpack-redis.git
```

Then you can add other buildpack(s) to compile your code like so:

```console
$ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-ruby.git
```

Choose the correct buildpack(s) for the language(s) used in your application.

For more information on using multiple buildpacks check out [this devcenter article](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app).

Next, for each process that should connect to Redis securely, you will need to preface the command in
your `Procfile` with `bin/start-stunnel`. In this example, we want the `web` process to use
a secure connection to Heroku Redis.  The `worker` process doesn't interact with Redis, so
`bin/start-stunnel` was not included:

    $ cat Procfile
    web:    bin/start-stunnel bundle exec unicorn -p $PORT -c ./config/unicorn.rb -E $RACK_ENV
    worker: bundle exec rake worker

To wrap your console in stunnel, you should use bin/start-stunnel-interactive, which won't run your command in the background, so stdin/stout still work.
    $ cat Procfile
    console:    bin/start-stunnel-interactive bundle exec rails console


We're then ready to deploy to Heroku with an encrypted connection between the dynos and Heroku
Redis:

    $ git push heroku master
    ...
    -----> Fetching custom git buildpack... done
    -----> Multipack app detected
    =====> Downloading Buildpack: https://github.com/PeriscopeData/heroku-buildpack-redis.git
    =====> Detected Framework: stunnel
           Using stunnel version: 5.02
           Using stack version: cedar
    -----> Fetching and vendoring stunnel into slug
    -----> Moving the configuration generation script into app/bin
    -----> Moving the start-stunnel script into app/bin
    -----> stunnel done
    =====> Downloading Buildpack: https://github.com/heroku/heroku-buildpack-ruby.git
    =====> Detected Framework: Ruby/Rack
    -----> Using Ruby version: ruby-2.2.2
    -----> Installing dependencies using Bundler version 1.7.12
    ...

## Configuration

Add any URLs you want to be tunneled to the STUNNEL_URLS env var. To tunnel just redis, set STUNNEL_URLS=REDIS_URL
Prepend `bin/start-stunnel` to any process in the Procfile to run stunnel alongside that process.

### Stunnel settings

Some settings are configurable through app config vars at runtime:

- ``STUNNEL_ENABLED``: Default to true, enable or disable stunnel.
