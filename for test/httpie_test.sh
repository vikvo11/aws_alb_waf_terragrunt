#!/bin/bash

check_url() {
  url=$1
  status_code=$(http --print=h --ignore-stdin "$url" 2>/dev/null | grep HTTP | awk '{print $2}')
  content=$(http --print=b --ignore-stdin "$url" 2>/dev/null)

  if [[ $status_code == 200 ]]; then
    echo "OK $url"
    #echo "Status Code: $status_code"
    #echo "$content"
  else
    echo "NA $url"
    #echo "Status Code: $status_code"
  fi
}

# URLs to check
check_url "http://waf-acme-lb-1253159279.us-west-2.elb.amazonaws.com/static"
check_url "http://foo.waf-acme-lb.example.com/static/"
check_url "http://bar.waf-acme-lb.example.com/static/"
check_url "http://foo.waf-acme-lb.example.com/static/foo"
check_url "http://bar.waf-acme-lb.example.com/static/foo"
check_url "http://foo.waf-acme-lb.example.com/static/foo/bar"
check_url "http://bar.waf-acme-lb.example.com/static/foo/bar"
check_url "http://foo.waf-acme-lb.example.com/status"
check_url "http://bar.waf-acme-lb.example.com/status"
check_url "http://foo.waf-acme-lb.example.com"
check_url "http://bar.waf-acme-lb.example.com"
check_url "http://foo.waf-acme-lb.example.com/webhook"
check_url "http://bar.waf-acme-lb.example.com/webhook"
check_url "http://foo.waf-acme-lb.example.com/webhook/viber"
check_url "http://bar.waf-acme-lb.example.com/webhook/viber"
check_url "http://foo.waf-acme-lb.example.com/webhooks/viber"
check_url "http://bar.waf-acme-lb.example.com/webhooks/viber"
check_url "http://bar.waf-acme-lb.example.com/webhooks/facebook/webhook"
check_url "http://bar.waf-acme-lb.example.com/webhooks/facebook/webhook/foo"
check_url "http://foo.waf-acme-lb.example.com/webhooks/facebook/webhook"
