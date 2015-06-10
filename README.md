# Heroku buildpack: Redis

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows one to stunnel in a dyno alongside application code.
It is meant to be used in conjunction with other buildpacks as part of a
[multi-buildpack](https://github.com/ddollar/heroku-buildpack-multi).

The primary use of this buildpack is to allow secure connection
to Redis database from a dyno, via stunnel.

It uses [stunnel](http://stunnel.org/).

## Usage

Example usage:

    $ ls -a
    .buildpacks  Gemfile  Gemfile.lock  Procfile  config/  config.ru

    $ heroku config:add BUILDPACK_URL=https://github.com/heroku/heroku-buildpack-multi.git

    $ cat .buildpacks
    https://github.com/heroku/heroku-buildpack-redis.git#0.1
    https://github.com/heroku/heroku-buildpack-ruby.git

    $ cat Procfile
    web:    bin/start-stunnel bundle exec unicorn -p $PORT -c ./config/unicorn.rb -E $RACK_ENV
    worker: bundle exec rake worker

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

The buildpack will install and configure stunnel to connect to
`REDIS_URL` over a SSL connection. Prepend `bin/start-stunnel`
to any process in the Procfile to run stunnel alongside that process.


## Multiple Databases

It is possible to connect to multiple databases through stunnel by setting
`STUNNEL_URLS` to a list of config vars. Example:

    $ heroku config:add STUNNEL_URLS="REDIS_URL HEROKU_REDIS_ROSE_URL"
