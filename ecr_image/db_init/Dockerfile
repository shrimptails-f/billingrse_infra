FROM mysql:8.4

RUN microdnf install -y gettext && microdnf clean all

# Place init SQL at /sql/init.sql
COPY ./init.sql /sql/init.sql

# Task definition runs: envsubst < /sql/init.sql | mysql -h$${DB_HOST} ...
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "--"]
