# nagios_http_url_return

## Description

Parses out the return values of a url to avoid cache and hit loadbalancer directly

## Requirements

curl 7.21.3

## Installation

git clone or download file(s) to your host to /usr/lib64/nagios/plugins/check_url_return.sh

## Configuration

```bash
edit /etc/nrpe.d/checks.cfg
add
command[check_url_returns]=/usr/lib64/nagios/plugins/check_url_return.sh '$ARG1$' '$ARG2$' '$ARG3$'
```

## limitation
Note that when running check_nrpe with double-quotes or other characters, this will cause
```bash
Dec 19 08:59:50 hostname-01 nrpe[10964]: Error: Request contained illegal metachars!
Dec 19 08:59:50 hostname-01 nrpe[10964]: Client request was invalid, bailing out...
```

solution
```bash
command[check_url_returns]=/usr/lib64/nagios/plugins/check_url_return.sh '$ARG1$' '$ARG2$' '[search_string]'
```

## Running utility

check directly from command line
```bash
/usr/lib64/nagios/plugins/check_url_return.sh [url] [loadbalancer_dnsname] [search_string]
```

check via nrpe
```bash
/usr/lib64/nagios/plugins/check_nrpe -H [host] -c check_url_return -a  [url] [loadbalancer_dnsname] [search_string] -v
```


