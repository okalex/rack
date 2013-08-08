# Overview

Rack provides a minimal, modular and adaptable interface for developing web applications in Ruby. This Charm will deploy Ruby on Rails, Sinatra or any other Rack application and connect it to supported services.

# Usage

To deploy this charm you will need at a minimum: a cloud environment, working Juju installation and a successful bootstrap. Once bootstrapped, deploy Rack charm and all required services.

## Ruby on Rails example

Configure your application, for example:

**sample-rails.yml**

```yml
sample-rails:
  repo: https://github.com/pavelpachkovskij/sample-rails
```

Deploy Rack application:

```shell
juju deploy rack sample-rails --config sample-rails.yml
```

Deploy and relate database

```shell
juju deploy postgresql
juju add-relation postgresql:db sample-rails
```

Now you can run migrations:

```shell
juju ssh sample-rails/0 run rake db:migrate
```

Seed database

```shell
juju ssh sample-rails/0 run rake db:seed
```

And finally expose the Rack service:

```shell
juju expose rack
```

Find the Rack instance's public URL from

```shell
juju status
```

### MySQL setup

```shell
juju deploy mysql
juju add-relation mysql rack
```

## Sinatra example

Configure your application, for example html2haml

**html2haml.yml**

```yml
html2haml:
  repo: https://github.com/twilson63/html2haml.git
```

Deploy your Rack service

```shell
juju deploy rack html2haml --config html2haml.yml
```

Expose Rack service:

```shell
juju expose html2haml
```

## Source code updates

```shell
juju set <service_name> revision=<revision>
```

## Executing commands

```shell
juju ssh <unit_name> run <command>
```

## Restart application

```bash
juju ssh <unit_name> sudo restart rack
```

## Foreman integration

You can add Procfile to your application and Rack to start additional processes or replace default application server:

Example Procfile:

    web: bundle exec unicorn -p $PORT
    watcher: bundle exec rake watch

## Specifying a Ruby Version

You can use the ruby keyword of your app's Gemfile to specify a particular version of Ruby.

```ruby
source "https://rubygems.org"
ruby "1.9.3"
```

# Horizontal scaling

Juju makes it easy to scale your Rack application. You can simply deploy any supported load balancer, add relation and launch any number of application instances.

## HAProxy

```shell
juju deploy rack rack --config rack.yml
juju deploy haproxy
juju add-relation haproxy rack
juju expose haproxy
juju add-unit rack -n 2
```

## Apache2

Apache2 is harder to start with, but it provides more flexibility with configuration options.
Here is a quick example of using Apache2 as a load balancer with your rack application:

Deploy Rack application

```shell
juju deploy rack --config rack.yml
```

You have to enable mod_proxy_balancer and mod_proxy_http modules in your Apache2 config:

**apache2.yml** example

```yaml
apache2:
  enable_modules: proxy_balancer proxy_http
```

Deploy Apache2

```shell
juju deploy apache2 --config apache2.yml
```

Create balancer relation between Apache2 and Rack application

```shell
juju add-relation apache2:balancer rack
```

Apache2 charm expects a template to be passed in. Example of vhost that will balance all traffic over your application instances:

**vhost.tmpl**

```xml
<VirtualHost *:80>
  ServerName rack
  ProxyPass / balancer://rack/ lbmethod=byrequests stickysession=BALANCEID
  ProxyPassReverse / balancer://rack/
</VirtualHost>
```

Update Apache2 service config with this template

```shell
juju set apache2 "vhost_http_template=$(base64 < vhost.tmpl)"
```

Expose Apache2 service

```shell
juju expose apache2
```

# Logging with Logstash

You can add logstash service to collect information from application's logs and Kibana application to visualize this data.

```shell
juju deploy kibana
juju deploy logstash-indexer
juju add-relation kibana logstash-indexer:rest

juju deploy logstash-agent
juju add-relation logstash-agent logstash-indexer
juju add-relation logstash-agent rack
juju set logstash-agent CustomLogFile="['/var/www/rack/current/log/*.log']" CustomLogType="rack"
juju expose kibana
```

# Monitoring with Nagios and NRPE

You can can perform HTTP checks with Nagios. To do this deploy Nagios and relate it to your Rack application:

```shell
juju deploy nagios
juju add-relation rack nagios
```

Additionally you can perform disk, mem, and swap checks with NRPE extension:

```shell
juju deploy nrpe
juju add-relation rack nrpe
juju add-relation nrpe nagios
```

# MongoDB relation

Deploy MonogDB service and relate it to Rack application:

    juju deploy mongodb
    juju add-relation mongodb rack

Rack charm will set environment variables which you can use to configure your Mongodb adapter.

```ruby
MONGODB_URL   => mongodb://host:port/database
```

## Mongoid 2.x

Your mongoid.yml should look like:

```yml
production:
  uri: <%= ENV['MONGODB_URL'] %>
```

## Mongoid 3.x

Your mongoid.yml should look like:

```yml
production:
  sessions:
    default:
      uri: <%= ENV['MONGODB_URL'] %>
```

In both cases you can set additional options specified by Mongoid.

# Memcached relation

Deploy Memcached service and relate it to Rack application:

```shell
juju deploy memcached
juju add-relation memcached rack
```

Rack charm will set environment variables which you can use to configure your Memcache adapter. [Dalli](https://github.com/mperham/dalli) use those variables by default.

```ruby
MEMCACHE_PASSWORD    => xxxxxxxxxxxx
MEMCACHE_SERVERS     => instance.hostname.net
MEMCACHE_USERNAME    => xxxxxxxxxxxx
```

# Redis relation

Deploy Redis service and relate it to Rack application:

```bash
juju deploy redis-master
juju add-relation redis-master:redis-master rack
```

Rack charm will set environment variables which you can use to configure your Redis adapter.

```ruby
REDIS_URL   => redis://username:password@my.host:6389
```

For example you can configure Redis adapter in config/initializers/redis.rb

```ruby
uri = URI.parse(ENV["REDIS_URL"])
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
```

# Known issues

## Rack application didn't start because assets were not compiled

To be able to compile assets before you've joined database relation you have to disable initialize_on_precompile option in application.rb:

```ruby
config.assets.initialize_on_precompile = false
```

If you can't do this you still can join database and compile assets manually:

```bash
juju ssh rack/0 run rake assets:precompile
```

Then restart Rack service (while you have to replace 'rack/0' with your application name, e.g. 'sample-rails/0', 'sudo restart rack' is a valid command to restart any deployed application):

```bash
juju ssh rack/0 sudo restart rack
```

# Configuration

## Deploy from Git

Sample Git config:

```yml
rack:
  repo: <repository_url>
  revision: <revision_number>
```

To deploy from private repo via SSH add 'deploy_key' option:

```yml
  deploy_key: <private_key>
```

## Deploy from SVN

Sample SVN config:

```yml
rack:
  scm_provider: svn
  repo: <repository_url>
  revision: <revision_number>
  svn_username: <username>
  svn_password: <password>
```

## Install extra packages

Specify list of packages separated by spaces:

```yml
  extra_packages: 'libsqlite3++-dev libmagick++-dev'
```

## Set ENV variables

You can set ENV variables, which will be available within all processes defined in a Procfile:

```yml
  env: 'AWS_ACCESS_KEY_ID=aws_access_key_id AWS_SECRET_ACCESS_KEY=aws_secret_access_key'
```