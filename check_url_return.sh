#!/bin/bash
#
#  Author: zippycup
#  Description: Checks the status of a regional url return value
#               Works to bypass the caching layer such as akamai to connect to loadbalance with the correct domain without change to /etc/hosts
#
#

connection_timeout=15
user_agent='Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36'
current_time=`/bin/date +%Y%m%d-%H%M%S`
temp=/var/tmp/check_url_return_${current_time}

function exit_ok()      { echo "OK: $*"; exit 0; }
function exit_warn()    { echo "WARN: $*"; exit 1; }
function exit_crit()    { echo "CRIT: $*"; exit 2; }
function exit_unknown() { echo "UNKNOWN: $*"; exit 3; }

host=$1
url=$2
regex=$3

usage(){
  echo "$0 [host] [url] [regex]"
  echo "example: $0 mydomain.elb.amazon.com 'http://mydomain.com/?q=tudxc+midfsegagmsind' 'Mydomain Results'"
  echo "regex is a simple text search separated by a pipe |"
  echo "this is an 'AND' operation which find the string on the same line" 
  exit
}

get_protocol() {
  protocol=`echo "${url}" | awk '{split($0,a,":"); print a[1]}'`
}

get_domain() {
  tmp_domain_name=`echo "${url}" | awk '{split($0,a,"//"); split(a[2],b,"/"); print b[1]}'`

  if [ "${protocol}" == 'https' ]
  then
    domain_name=${tmp_domain_name}
    port=443
    return
  fi

  echo ${tmp_domain_name} | grep '\:' > /dev/null 2>&1

  if [ "$?" -eq 0 ]
  then
    domain_name=`echo ${tmp_domain_name} | awk '{split($0,a,":"); print a[1]}'`
    port=`echo ${tmp_domain_name} | awk '{split($0,a,":"); print a[2]}'`
  else
    domain_name=${tmp_domain_name}
    port=80
  fi
}

get_domain_ip() {
  domain_ip=`dig +short ${host} | tail -1`

  if [ "x${domain_ip}" == "x" ]
  then
    exit_warn "get_domain_ip for ${host} failed"
  fi

}

gen_regex_file() {
  regex_str=`echo "${regex}" | awk '{n=split($0,a,"|"); for ( i=1; i<=n; i++){ if (i==1){ b="/" a[i] "/"} else { b=b " && /" a[i] "/"}}print b }'`
}

match_regex() {
  gen_regex_file
  retvalue=`cat ${temp} | awk "${regex_str}"`

  if [ "x${retvalue}" != 'x' ]
  then
    exit_ok "regex [${regex_str}] found in url response: ${url}"
  else
    exit_crit "$cannot find regex [${regex_str}] in url response ${url}"
  fi
}

if [ "$#" -lt 3  ]
then
   usage
fi

get_protocol
get_domain
get_domain_ip

curl -X GET \
-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
-H "Accept-Encoding: gzip, deflate" \
-H "Accept-Language: en-US,en;q=0.8" \
-H "Cache-Control: max-age=0" \
-H "Upgrade-Insecure-Requests: 1" \
-H "Connection: keep-alive" \
-H "User-Agent: ${user_agent}" \
--resolve ${domain_name}:${port}:${domain_ip} \
--connect-timeout ${connection_timeout} \
${url} > ${temp} 2>&1

match_regex
