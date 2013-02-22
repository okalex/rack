## Overview

Rack applications subordinate [Juju Charm](http://jujucharms.com/). Works only when related to appropriate web-server.

## Usage

You can use any of available web servers, which provides rack container. Currently available:

- [apache2-passenger](http://jujucharms.com/~pavel-pachkovskij/precise/apache2-passenger)
- [nginx-passenger](http://jujucharms.com/charms/precise/nginx-passenger)

All examples will use **apache2-passenger**, but you can choose any.

### Rails 3 example

1. Deploy web-server

        juju deploy apache2-passenger

2. Deploy Rack application (see configuration section below)

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

#### PostgreSQL setup

On a step 4 run

    juju deploy postgresql
    juju add-relation postgresql:db rack

#### Mongodb setup

If you use Mongodb with Mongoid then on a step 4 you should run

    juju deploy mongodb
    juju add-relation mongodb rack

#### Resque setup

Coming soon...

### Sinatra example

1. Deploy web-server

        juju deploy apache2-passenger

2. Configure your application, for example html2haml

    **html2haml.yml**

        html2haml:
          repo_url: https://github.com/twilson63/html2haml.git
          app_name: html2haml

3. Deploy your application with Rack Charm

        juju deploy rack html2haml --config html2haml.yml

4. Relate it to web-server

        juju add-relation html2haml apache2-passenger

5. Open the stack up to the outside world.

        juju expose apache2-passenger

## Configuration

Here is an example configuration for Rails 3 installation from svn trunk. Additionally it will install imagemagick package.

    rails:
      repo_type: svn
      repo_url: https://github.com/pavelpachkovskij/sample-rails
      repo_branch: trunk
      app_name: sample-rails
      install_root: /var/www
      extra_packages: imagemagick
      port: 80
      migrate_database: true
      seed_database: true
      compile_assets: true

If you don't have or don't need to migrate database, seed database or compile assets, disable them in your config. They are enabled by default.

## Under the hood

- installs all dependencies and extra packages
- install node.js from ppa:chris-lea/node.js
- fetch an application from configured repository
- runs bundler