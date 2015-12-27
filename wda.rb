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

type = ARGV[0]
$host = ARGV[1]
$name = ARGV[2]
$email = ARGV[3]
$activeif = ARGV[4]
$ip = ARGV[5]
$wd_hh = 'https://'+ $wd_host + '/wd/index.html'

class WatchDog
	def wddel(hostname)
		puts "Delete host from zabbix..."
		@hostname = hostname
		agent = Mechanize.new
		agent.add_auth($wd_hh , $wd_api_login, $wd_api_pass)
		page = agent.get $wd_hh
		form = page.forms.last
		form.field_with(:name => 'host' ).value = @hostname
		page = agent.submit form
		puts page.body.gsub("<p>", "")
	end

	def wdadd(hostname , name , email , activeif , ip)
		@hostname = hostname
		@name = name
		@email = email
		@activeif = activeif
		@ip = ip
		
		puts "Add host to zabbix..."
		
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
		puts page.body.gsub("<p>", "")
		
		puts "Update host templates..."
		
		zbx = ZabbixApi.connect(
			:url => 'https://' + $wd_host + '/api_jsonrpc.php',
			:user => $wd_admin_login ,
			:password => $wd_admin_pass
		)
		zbx.templates.mass_add(
			:hosts_id => [zbx.hosts.get_id(:host => @hostname)],
			:templates_id => [100100000010962 , 100100000010003 , 100100000010099]
		)
		$idscreen = zbx.screens.get(
 			:name => @hostname
 		)
 		$idscreen = Hash[*$idscreen]
 		zbx.screens.delete(
 			$idscreen["screenid"]	
		)
		
		puts "Add host to group..."
		
		zbx.query(:method => "hostgroup.massadd" , :params => {:groups => {:groupid => "100100000000614"} , :hosts => {:hostid => zbx.hosts.get_id(:host => @hostname)}} )
		
		puts "Update screen graphs..."
		
		iface = "Traffic " + @activeif
		$graphtoscreen1 = zbx.graphs.get_ids_by_host(:host => @hostname , :filter => iface )
		$graphtoscreen2 = zbx.graphs.get_ids_by_host(:host => @hostname , :filter => "CPU\ Utilization")
		$graphtoscreen3 = zbx.graphs.get_ids_by_host(:host => @hostname , :filter => "Load\ Average")
		$graphtoscreen4 = zbx.graphs.get_ids_by_host(:host => @hostname , :filter => "MySQL\ queries")
		$graphtoscreen5 = zbx.graphs.get_ids_by_host(:host => @hostname , :filter => "Processes")
		$graphtoscreen6 = zbx.graphs.get_ids_by_host(:host => @hostname , :filter => "Memory")
		$graphtoscreen1 = $graphtoscreen1.map(&:to_i)
		$graphtoscreen2 = $graphtoscreen2.map(&:to_i)
		$graphtoscreen3 = $graphtoscreen3.map(&:to_i)
		$graphtoscreen4 = $graphtoscreen4.map(&:to_i)
		$graphtoscreen5 = $graphtoscreen5.map(&:to_i)
		$graphtoscreen6 = $graphtoscreen6.map(&:to_i)

		zbx.screens.get_or_create_for_host(
			:hosts_id => [zbx.hosts.get_id(:host => @hostname)],
	  		:screen_name => @hostname,
	  		:height => 180,
	  		:width => 360,
	  		:vsize => 3,
	  		:hsize => 2,
	  		:halign => 0,
	  		:valign => 0,
	  		:graphids => [ $graphtoscreen1[0] , $graphtoscreen2[0] , $graphtoscreen3[0] , $graphtoscreen4[0] , $graphtoscreen5[0] , $graphtoscreen6[0] ]
		)
		puts "Done!"
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


