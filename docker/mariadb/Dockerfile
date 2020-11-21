FROM mariadb:latest

RUN apt update && apt install pv

ARG CURRENT_USER

RUN usermod -u ${CURRENT_USER? invalid argument} mysql
RUN groupmod -g ${CURRENT_USER? invalid argument} mysql

COPY ./docker/mariadb/init/ /docker-entrypoint-initdb.d/