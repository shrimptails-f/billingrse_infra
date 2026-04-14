# https://jay.gooby.org/2022/07/19/building-just-mysqlclient-on-alpine-from-scratch
FROM alpine:3.19

RUN apk add --no-cache bash build-base autoconf openssl openssl-dev ncurses ncurses-dev wget cmake gettext && \
    wget -O /tmp/mysql-8.4.0.tar.gz https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-8.4.0.tar.gz && \
    cd /tmp && tar -zxf /tmp/mysql-8.4.0.tar.gz && \
    cd /tmp/mysql-8.4.0 && cmake -DFORCE_INSOURCE_BUILD=1 -DWITHOUT_SERVER:BOOL=ON -DCMAKE_INSTALL_PREFIX=/ && \
    make && make install && \
    rm -rf /tmp/mysql* && rm -rf /var/cache/apk/*

# Place init SQL at /sql/init.sql
COPY ./init.sql /sql/init.sql

# Task definition runs: envsubst < /sql/init.sql | mysql -h$${DB_HOST} ...
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "--"]
