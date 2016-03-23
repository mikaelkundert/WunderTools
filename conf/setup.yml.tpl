# taken from project.yml
project:
  name: <%= projectName %> #ansibleref
ansible:
  remote: <%= wunderMachina %> #git@github.com:wunderkraut/WunderMachina.git
  branch: <%= wunderMachina_branch %> #master
  revision:
buildsh:
  enabled: <%= buildSh_enabled %> #true
  branch: <%= buildSh_branch %> #develop
  revision:
# these come from vagrant_local.yml
name : <%= projectName %> #ansibleref
hostname : <%= projectLocalURL%> #local.ansibleref.com
mem : 2000
cpus : 2
ip : <%= projectLocalIP %> #192.168.10.170
box : <%= projectLocalBox %> #https://www.dropbox.com/s/wa0vs54lgngfcrx/vb-centos-6.5-x86_64-v0.box?dl=1
# these come from vagrant.yml
---

- hosts: vagrant
  sudo: true
  roles:
   - role: common
   - role: cache
   - role: database
   - role: solr
   - role: varnish
   - role: web-front
   - role: drupal
   - role: devtools
   - role: solr_config
# these come from variables.yml

---
# file: roles/web-front/defaults/main.yml

# file: roles/web-front/defaults/main.yml

# Databases
databases:
  drupal:
    user: drupal
    pass: password

drush: {
  version: "6.*",
}
drupal_files: drupal/files
# PHP
php_package: php56u

# Sections APC and suhosin are only for php53u
# OPCACHE is for php55u, PHP section is shared

php:
 - section: PHP
   options:
    - key: sendmail_path
      val: "/usr/sbin/ssmtp -t"
    - key: memory_limit
      val: 512M
    - key: realpath_cache_size
      val: 1M
    - key: realpath_cache_ttl
      val: 7200
    - key: max_execution_time
      val: 60
    - key: max_input_time
      val: 60
    - key: post_max_size
      val: 24M
    - key: upload_max_filesize
      val: 50M
    - key: max_file_uploads
      val: 20
    - key: allow_url_fopen
      val: On
    - key: display_errors
      val: Off
    - key: html_errors
      val: Off
    - key: display_errors
      val: On
    - key: html_errors
      val: On
 - section: DATE
   options:
    - key: date.timezone
      val: Europe/Helsinki
# - section: APC
#   options:
#    - key: apc.shm_size
#      val: 256M
#    - key: apc.ttl
#      val: 0
#    - key: apc.user_ttl
#      val: 7200
#    - key: apc.stat
#      val: 1
# - section: suhosin
#   options:
#     - key: suhosin.mail.protect
#       val: 2
#     - key: suhosin.filter.action
#       val: 402
#     - key: suhosin.log.syslog
#       val: S_ALL & ~S_SQL
#     - key: suhosin.post.max_vars
#       val: 1000
#     - key: suhosin.request.max_vars
#       val: 1000
 - section: OPCACHE
   options:
    - key: opcache.memory
      val: 256
    - key: opcache.validate
      val: 1
    - key: opcache.revalidate_freq
      val: 0

# MariaDB
mysql_root_password: 1asirjg9834t35t
server_hostname: localhost
innodb_log_file_size: '128MB'
innodb_buffer_pool_size: '512MB'
wait_timeout: '3600'

# Varnish
varnish_port: '80'
varnish_memory: '512M'

varnish_backends:
  - name: web1
    host: localhost
    port: 8080
ssl_ip_fix: false

#Docs
docs:
  hostname : '<%= projectLocalDocsURL%>' #'docs.local.ansibleref.com'
  dir : '/vagrant/docs'

# Nginx
worker_processes: '1'
nginx_sites:
  - hostname: '<%= projectLocalURL%> *.<%= projectLocalURL%>' #'local.ansibleref.com *.local.ansibleref.com'
    port: '8080 default_server'
    docroot: '/vagrant/drupal/current'
    accesslog: true
    accesslog_params: 'main buffer=32k'
    errorlog: true
    logprefix: '<%= projectLocalURL%>' #'local.ansibleref.com'
    ssl: false
    sslproxy: false
    ssl_certificate: default.crt
    ssl_certificate_key: default.key
    include_drupal: true
    cdn: false
    nocdnhostname: 'www.wunder.io'
    redirect: false
    redirecthost: 'https://www.wunder.io'
  - hostname: "{{ docs.hostname }}"
    port: '8080'
    docroot: "{{ docs.dir }}"
    accesslog: true
    accesslog_params: 'main buffer=32k'
    errorlog: true
    logprefix: "{{ docs.hostname }}"
    ssl: false
    sslproxy: false
    ssl_certificate: default.crt
    ssl_certificate_key: default.key
    include_drupal: false
    include_wiki: true
    cdn: false
    nocdnhostname: 'www.wunder.io'
    redirect: false
    redirecthost: 'https://www.wunder.io'

solr_collection_name: 'ansibleref'