#!/usr/bin/ruby
# Queries a PgBouncer admin database and publishes statistics to Ganglia using gmetric.
#
# == Install Dependencies ==
#
# sudo apt-get install ruby ganglia-monitor
#
# == Usage ==
#
# pgbouncer_gmetric.rb <databasename>
#
# based heavily off of:
# http://github.com/elecnix/postgres_gmetric
#
# Released under the BSD License
require 'optparse'

unless File.exists? '/usr/bin/gmetric'
  abort "FATAL: gmetric not found"
end

@port = 6432
@user = ENV['LOGNAME']
@verbose = false
parser = OptionParser.new do |opts|
  opts.banner = "Usage: pgbouncer_gmetric.rb [-U <user>] <database>"

  opts.on( '-v', '--verbose', 'Output collected data' ) do
    @verbose = true
  end

  opts.on( '-U', '--user USER', 'Connect as USER' ) do |user|
    @user = user
  end

  opts.on( '-p', '--port PORT', 'Connect to PORT' ) do |port|
    @port = port
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end
parser.parse!

# optparse pops off args as it processes them, leaving us with the database
# as the first arg.
@database = ARGV[0]

if @database.nil?
  abort 'Missing database, please supply it as the last argument.'
elsif @user.nil?
  abort 'Missing user, please supply it with the -U flag.'
end

def query(sql)
  if @verbose
    puts "psql -U #{@user} -p #{@port} -A -c \"#{sql}\" pgbouncer | grep  \"database\|#{@database}\" "
  end
  `psql -U #{@user} -p #{@port} -A -c "#{sql}" pgbouncer | grep  "database\\\|#{@database}" `
end

def publish(sql)
  lines = query(sql).split("\n")
  values = lines[1].split('|')
  lines[0].split('|').each_with_index do |colname, i|
    unless colname == "database" || colname == "user"
      v = values[i]
      if @verbose
        puts "#{colname}=#{v}"
      end
      `gmetric --group pgbouncer --name "pgb_#{colname}" --value #{v} --type float --dmax=240`
    end
  end
end

publish "show pools;"
