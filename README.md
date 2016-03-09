# Zabbapi

Zabbapi -  script / cli tool for (create / delete / update) Zabbix hosts  
zabbapi based on zabbixapi gem (https://github.com/express42/zabbixapi.git)  

### zabbapi ready for use and can :  
*  a. add host to user  
*  b. if user not exist - create user and give login / pass ( add media , permissions , actions , etc.)  
*  c. add templates for host such as exim , mysql , linux or freebsd  
*  d. discovery iface and add graph to screen  
*  e. delete host  
 
### There are two branches of zabbapi.

## 1. Github : 
  https://github.com/gadost/zabbapi
## 2. Rubygems : 
  https://rubygems.org/gems/zabbapi

## **How to use :**  
###  1. from github :  
 `git clone https://github.com/gadost/zabbapi.git  `  
 `cd zabbapi  `  
 `nano config.json  `  
 `bundle`  
 `ruby wda.rb add <hostname> <user> <usermail> <activeinterface> <ip>  `  
 `ruby wda.rb del <hostname> `  

###  2. from rubygems :  
 `gem install zabbapi`  
 `sudo nano /etc/config.json`  
 `$ wda add <hostname> <user> <usermail> <activeinterface> <ip>`  
 `$ wda wda.rb del <hostname>`  


### Config.json

> {  
> "host" : "zabbix.host.tld",  
> "login" : "Adminlogin",  
> "pass" : "AdminPass"  
> }
