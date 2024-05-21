# Heroku buildpack: Redis Stunnel

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows an application to use an [stunnel](http://stunnel.org) to connect securely to
Heroku Redis.  It is meant to be used in conjunction with other buildpacks.

> [!WARNING]
> This buildpack isn’t compatible with the `heroku-24` [stack](https://devcenter.heroku.com/articles/stack) and later. You don’t need this buildpack for Redis 6+, which supports native TLS.
>
> For more information, see [Securing Heroku Redis](https://devcenter.heroku.com/articles/heroku-redis#security-and-compliance).

## Usage

First, ensure your Heroku Redis addon is using a production tier plan. SSL is not
available when using the hobby tier.

Then set this buildpack as your initial buildpack with:

```console
$ heroku buildpacks:add -i 1 heroku/redis
```

Then confirm you are using this buildpack as well as your language buildpack like so:

```console
$ heroku buildpacks
=== frozen-potato-95352 Buildpack URLs
1. heroku/redis
2. heroku/python
```

For more information on using multiple buildpacks check out [this devcenter article](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app).

Next, for each process that should connect to Redis securely, you will need to preface the command in
your `Procfile` with `bin/start-stunnel`. In this example, we want the `web` process to use
a secure connection to Heroku Redis.  The `worker` process doesn't interact with Redis, so
`bin/start-stunnel` was not included:

    $ cat Procfile
    web:    bin/start-stunnel bundle exec unicorn -p $PORT -c ./config/unicorn.rb -E $RACK_ENV
    worker: bundle exec rake worker

We're then ready to deploy to Heroku with an encrypted connection between the dynos and Heroku
Redis:

    $ git push heroku main
    ...
    -----> Fetching custom git buildpack... done
    -----> Multipack app detected
    =====> Downloading Buildpack: https://github.com/heroku/heroku-buildpack-redis.git
    =====> Detected Framework: Redis-stunnel
           Using stunnel version: 5.02
           Using stack version: cedar
    -----> Fetching and vendoring stunnel into slug
    -----> Moving the configuration generation script into app/bin
    -----> Moving the start-stunnel script into app/bin
    -----> Redis-stunnel done
    =====> Downloading Buildpack: https://github.com/heroku/heroku-buildpack-ruby.git
    =====> Detected Framework: Ruby/Rack
    -----> Using Ruby version: ruby-2.2.2
    -----> Installing dependencies using Bundler version 1.7.12
    ...

## Configuration

The buildpack will install and configure stunnel to connect to `REDIS_URL` over a SSL connection. Prepend `bin/start-stunnel`
to any process in the Procfile to run stunnel alongside that process.

### Stunnel settings

Some settings are configurable through app config vars at runtime:

- ``STUNNEL_ENABLED``: Default to true, enable or disable stunnel.
- ``STUNNEL_LOGLEVEL``: Default is `notice`, set to `info` or `debug` for more verbose log output.

### Multiple Redis Instances

If your application needs to connect to multiple Heroku Redis instances securely, this buildpack
will automatically create an Stunnel for each color Heroku Redis config var (`HEROKU_REDIS_COLOR`)
and the `REDIS_URL` config var. If you have Redis urls that aren't in one of these config vars you
will need to explicitly tell the buildpack that you need an Stunnel by setting the `REDIS_STUNNEL_URLS`
config var to a list of the appropriate config vars:

    $ heroku config:add REDIS_STUNNEL_URLS="CACHE_URL SESSION_STORE_URL"

## Using the edge version of the buildpack

The `heroku/redis` buildpack points to the latest stable version of the buildpack published in the [Buildpack Registry](https://devcenter.heroku.com/articles/buildpack-registry). To use the latest version of the buildpack (the code in this repository), run the following command:

    $ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-redis
