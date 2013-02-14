## Overview

Rack applications subordinate [Juju Charm](http://jujucharms.com/). Works only when related to appropriate web-server.
Now it's only for Rails 3 but support for other Rack applications is in progress.

## Usage

You can use any of available web servers, which provides rack container. Currently available:

- [apache2-passenger](https://code.launchpad.net/~pavel-pachkovskij/charms/precise/apache2-passenger/trunk)
- [nginx-passenger](https://code.launchpad.net/~pavel-pachkovskij/charms/precise/nginx-passenger/trunk)

All examples will use **apache2-passenger**, but you can choose any.

1. Deploy web-server

        juju deploy apache2-passenger

2. Deploy Rack Charm itself (see configuration section below)

        juju deploy rack --config myapp.yml

3. Relate them

        juju add-relation rack apache2-passenger

4. Deploy and relate database

        juju deploy mysql
        juju add-relation mysql rack

5. Open the stack up to the outside world.

        juju expose apache2-passenger

6. Find the apache2-passenger instance's public URL from

        juju status

### PostgreSQL setup

On a step 4 run

    juju deploy postgresql
    juju add-relation postgresql:db rack

### Mongodb setup

If you use Mongodb with Mongoid then on a step 4 you should run

    juju deploy mongodb
    juju add-relation mongodb rack

### Resque setup

Coming soon...

## Configuration

Here is example configuration for Rails 3 installation from svn trunk. Additionally it will install imagemagick package.

    rack:
      repo_type: svn
      repo_url: https://github.com/pavelpachkovskij/sample-rails
      repo_branch: trunk
      app_name: sample-rails
      install_root: /var/www
      extra_packages: imagemagick

## Under the hood

- installs all dependencies and extra packages
- install node.js from ppa:chris-lea/node.js
- fetch an application from configured repository
- runs bundler
