require 'rubygems'
require 'mechanize'
require 'hpricot'
require 'openssl'
require "zabbixapi"

$wd_host = ''
$wd_api_login = ''
$wd_api_pass = ''
$wd_admin_login = ''
$wd_admin_pass = ''

$type = ARGV[0]
$host = ARGV[1]
$name = ARGV[2]
$email = ARGV[3]
$activeif = ARGV[4]
$ip = ARGV[5]
$wd_hh = 'https://'+ $wd_host + '/wd/index.html'

class WatchDog
	def wddel(hostname)
		@hostname = hostname
		agent = Mechanize.new
		agent.add_auth($wd_hh , $wd_api_login, $wd_api_pass)
		page = agent.get $wd_hh
		form = page.forms.last
		form.field_with(:name => 'host' ).value = @hostname
		page = agent.submit form
		puts page.body
	end

	def wdadd(hostname , name , email , activeif , ip)
		@hostname = hostname
		@name = name
		@email = email
		@activeif = activeif
		@ip = ip
		agent = Mechanize.new
		agent.add_auth($wd_hh, $wd_api_login, $wd_api_pass)
		page = agent.get $wd_hh
		form = page.forms.first
		form.field_with(:name => 'user' ).value = @name
		form.field_with(:name => 'host' ).value = @hostname
		form.field_with(:name => 'email' ).value = @email
		form.field_with(:name => 'activeif' ).value = @activeif
		form.field_with(:name => 'ip' ).value = @ip
		page = agent.submit form
		puts page.body
	end
end

class UpdateHostTemplates
	def update(hostname)
		@hostname = hostname
		zbx = ZabbixApi.connect(
		  :url => 'https://' + $wd_host + '/api_jsonrpc.php',
		  :user => $wd_admin_login ,
		  :password => $wd_admin_pass
		)
		zbx.templates.mass_add(
		  :hosts_id => [zbx.hosts.get_id(:host => @hostname)],
		  :templates_id => [100100000010962 , 100100000010003 , 100100000010099]
		)
		zbx.screens.get_or_create_for_host(
		  :hosts_id => [zbx.hosts.get_id(:host => @hostname)],
  		  :screen_name => @hostname,
  		  :graphids => zbx.graphs.get_ids_by_host(:host => @hostname )
		)
	end
end

if $type == "del"
	task = WatchDog.new
	task.wddel($host)
elsif $type == "add"
	task = WatchDog.new
	task.wdadd($host, $name , $email , $activeif , $ip)
elsif $type == "update"
	task = UpdateHostTemplates.new
	task.update($host)
else
	puts "error input. please use:"
	puts " for add:"
	puts "ruby wda.rb add <hostname> <name> <email> <activeif> <ip>"
	puts " for del:"
	puts "ruby wda.rb del <hostname>"
	puts " for update:"
	puts "ruby wda.rb update <hostname>"
end


