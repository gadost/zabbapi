require 'rubygems'
require 'mechanize'
require 'hpricot'
require 'openssl'
require "zabbixapi"

$wd_host = ''
$wd_admin_login = ''
$wd_admin_pass = ''

$type = ARGV[0]
$host = ARGV[1]
$name = ARGV[2]
$email = ARGV[3]
$activeif = ARGV[4]
$ip = ARGV[5]

class WatchDog

	def wddel(hostname)

		@hostname = hostname
		zbx = ZabbixApi.connect(
			:url => 'https://' + $wd_host + '/api_jsonrpc.php',
			:user => $wd_admin_login ,
			:password => $wd_admin_pass
		)
		begin
			zbx.hosts.delete zbx.hosts.get_id(:host => @hostname )
		rescue 
			puts "unknown host with hostname " + @hostname  	
  		else
  			begin
	  			$idscreenfordel = zbx.screens.get(
	 			:name => @hostname
	 			)
	 			$idscreenfordel = Hash[*$idscreenfordel]
	 			zbx.screens.delete(
	 			$idscreenfordel["screenid"]	
				)
			rescue
  				puts "host with hostname " + @hostname + " deleted"	
  			else
  				puts "host with hostname " + @hostname + " deleted"	
  			end
    		end
	end

	def wdadd(hostname , name , email , activeif , ip)
		@hostname = hostname
		@name = name
		@email = email
		@activeif = activeif
		@ip = ip
		passwd = [*('a'..'z'),*('0'..'9')].sample(12).join

		puts "Add host to zabbix..."
		zbx = ZabbixApi.connect(
			:url => 'https://' + $wd_host + '/api_jsonrpc.php',
			:user => $wd_admin_login ,
			:password => $wd_admin_pass
		)
		begin
			zbx.hostgroups.create(:name => @name)
		rescue
			puts "HostGroup exist!"
		else
			puts "HostGroup created!"
		end

		begin
			zbx.usergroups.get_or_create(:name => @name)
		rescue
			puts "UserGroup exist!"
		else
			zbx.query(
				:method => "usergroup.massadd",
				:params => {
					:usrgrpids => [zbx.usergroups.get_id(:name => @name)],
					:rights => [{
						:groupid => [zbx.usergroups.get_id(:name => @name)],
						:id => zbx.hostgroups.get_id(:name => $name) ,
						:permission => 2
						}]
				}
			)
			puts "UserGroup #{@name} added.."
		end

		begin
			zbx.users.create(
				:alias => $name,
				:type => 1,
  				:passwd => passwd,
  				:usrgrps => [zbx.usergroups.get_id(:name => @name)],
  	 			:url => '/screens.php'
			)
		rescue
			puts "User exist!"
		else
			puts "User created!"
			puts " "
			puts "#WDAmhost"
			puts 'https://' + $wd_host
			puts "#{@name} / #{passwd}"
			puts " " 
		end

		begin
			zbx.query(:method => "host.create" ,
				:params => {
		  			:host => @hostname ,
		  			:interfaces => {
		      				:type => 1,
		      				:main => 1,
		      				:ip => $ip ,
		      				:dns => "",
		      				:useip => 1,
		      				:port => 10050
		    			},
		  			:groups => [{ :groupid => zbx.hostgroups.get_id(:name => @name) }],
		  			:templates => { :templateid => 100100000010001 }
				}
			)
		rescue
			puts "Host exist or got error!"
			abort "please del #{@hostname} first."
		else
			puts "Added host #{@hostname} to #{@name} !"
		end

		begin
			getuserid =  zbx.query(
				:method => "user.get",
				:params => {
    				:filter => { "alias":[@name] },
    				:output => {
    					:filter => "userid"
    				}
				}

			)
			getuserid = Hash[*getuserid]

			zbx.query(:method => "user.addmedia",
				:params => {
	  				:users => { :userid => getuserid["userid"]},
	  				:medias => [
	   				{
	      					:mediatypeid => "100100000000001" ,
	      					:sendto => @email,
	      					:active => 0,
	      					:severity => 48,
	      					:period => "1-7,00:00-24:00"
	    				}
					]
				}
			)
		rescue
			puts "UserMedia exist!"
		else
			puts "UserMedia added to #{@name}"
		end

		begin
		zbx.query(
			:method => "action.create" ,
			:params => [ {
				:name => "all #{@name} triggs", 
				:eventsource => 0 ,
				:status => 0 ,
				:evaltype => 0 ,
				:esc_period => 3600 ,
				:def_shortdata => '{TRIGGER.NAME}: {STATUS}' ,
				:def_longdata => '{TRIGGER.NAME}: {STATUS}',
				:usrgrpid => zbx.usergroups.get_id(:name => @name),
				:conditions => [
					{ 
						:conditiontype => 0 ,
						:operator => 0 ,
						:value => zbx.hostgroups.get_id(:name => $name)
					}
				],
				:operations => [
					{ 
						:operationtype => 0 ,
			    		:opmessage_grp => [
				   		{
				   			:usrgrpid => zbx.usergroups.get_id(:name => @name)
			    		}],
			    		:opmessage => {:default_msg => 1 }
			    	}
			    ]
			}]
		)
		rescue
			puts "Action exist!"
		end

		puts "Update host templates..."

		zbx.templates.mass_add(
			:hosts_id => [zbx.hosts.get_id(:host => @hostname)],
			:templates_id => [100100000010962 , 100100000010003 , 100100000010099]
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


