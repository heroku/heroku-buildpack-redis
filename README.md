# Heroku buildpack: Redis

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows an application to use an [stunnel](http://stunnel.org) to connect securely to
Heroku Redis.  It is meant to be used in conjunction with other buildpacks
as part of [multi-buildpack](https://github.com/ddollar/heroku-buildpack-multi).

## Usage

In your application, you will need to make sure that you set your main buildpack as multi-buildpack:

    $ heroku config:add BUILDPACK_URL=https://github.com/heroku/heroku-buildpack-multi.git

You'll then need to create a `.buildpacks` file at the root of your application directory.  The
[redis-buildpack](#) should be added along with the buildpack associated with the language that
was used to build your application.  In this example, the app was written in Ruby:

    $ cat .buildpacks
    https://github.com/heroku/heroku-buildpack-redis.git
    https://github.com/heroku/heroku-buildpack-ruby.git

For each process that should connect to Redis securely, you will need to preface the command in
your `Procfile` with `bin/start-stunnel`. In this example, we want the `web` process to use
a secure connection to Heroku Redis.  The `worker` process doesn't interact with Redis, so
`bin/start-stunnel` was not included:

    $ cat Procfile
    web:    bin/start-stunnel bundle exec unicorn -p $PORT -c ./config/unicorn.rb -E $RACK_ENV
    worker: bundle exec rake worker

We're then ready to deploy to Heroku with an encrypted connection between the dynos and Heroku
Redis:

    $ git push heroku master
    ...
    -----> Fetching custom git buildpack... done
    -----> Multipack app detected
    =====> Downloading Buildpack: https://github.com/heroku/heroku-buildpack-redis.git
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

The buildpack will install and configure stunnel to connect to `REDIS_URL` over a SSL connection. Prepend `bin/start-stunnel`
to any process in the Procfile to run stunnel alongside that process.


### Multiple Redis Instances

If your application needs to connect to multiple Heroku Redis instances securely, you can set the
`STUNNEL_URLS` config var to a list of config vars associated with the application:

    $ heroku config:add STUNNEL_URLS="REDIS_URL HEROKU_REDIS_ROSE_URL"
