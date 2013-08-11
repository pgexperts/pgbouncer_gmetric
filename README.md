pgbouncer_gmetric
=================

Queries a PgBouncer admin database and publishes statistics to Ganglia using gmetric

#Requirements:
ruby, gmetric, postgresql client binaries

#Example crontab usage:

    */5 * * * * /usr/local/bin/pgbouncer_gmetric.rb --port 6432 --user admin mydatabasename

This project is licensed under the PostgreSQL License. See the LICENSE file for
details.
