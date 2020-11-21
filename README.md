### Requirements
* docker
* docker-compose

#### Containers
* `server` - laravel or another framework
* `client` - vue app
* `analytics` - additional app like server
* `clickhouse`
* `redis`
* `mariadb`
* `nginx`

#### Settings
1. Prepare .env file:
* ```make env```
* Set env variables in .env

2. Clone git repositories to folders: server, client and analytics

3. Start build: `make build && make up`

#### Install XDebug
Manual for XDebug settings in PhpStorm with Docker https://blog.denisbondar.com/post/phpstorm_docker_xdebug
