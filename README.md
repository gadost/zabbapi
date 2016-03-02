# zabbapi
ruby zabbix api 
host create/delete/update

#Use
 for add:
ruby wda.rb add <hostname> <name> <email> <activeif> <ip>
 for del:
ruby wda.rb del <hostname>
 for update:
ruby wda.rb update <hostname>

where :
 <activeif> - active interface ( eth0 , em1 ,etc) 
 discovery included for screen graphs
