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
#
# based heavily off of:
# http://github.com/elecnix/postgres_gmetric
#
# Released under the BSD License
require 'optparse'

(puts "FATAL: gmetric not found" ; exit 1) if !File.exists? "/usr/bin/gmetric"

$options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: pgbouncer_gmetric.rb [-U <user>] <database>"

  # Define the options, and what they do
  $options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output collected data' ) do
    $options[:verbose] = true
  end

  $options[:user] = ENV['LOGNAME']
  opts.on( '-U', '--user USER', 'Connect as USER' ) do |user|
    $options[:user] = user
  end

  $options[:port] = 6432
  opts.on( '-p', '--port PORT', 'Connect to PORT' ) do |port|
    $options[:port] = port
  end


  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end
optparse.parse!

$options[:database]=ARGV[0]

(puts "Missing database"; exit 1) if $options[:database].empty?
(puts "Missing user"; exit 1) if $options[:user].nil?

def query(sql)
  puts "psql -U #{$options[:user]} -p #{$options[:port]} -A -c \"#{sql}\" pgbouncer | grep  \"database\|#{$options[:database]}\" " if $options[:verbose]
  `psql -U #{$options[:user]} -p #{$options[:port]} -A -c "#{sql}" pgbouncer | grep  "database\\\|#{$options[:database]}" `
end

def publish(sql)
  data=query(sql)
  lines=data.split("\n")
  values=lines[1].split('|')
  col=0
  lines[0].split('|').each do |colname|
    unless ( colname == "database" or colname == "user" )
      v=values[col]
      puts "#{colname}=#{v}" if $options[:verbose]
     `gmetric --group pgbouncer --name "pgb_#{colname}" --value #{v} --type float --dmax=240`
    end
    col=col+1
  end
end

publish "show pools;"

