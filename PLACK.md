# Upgrade notes from Apache to Plack version

* proxyip_forwarders are not "chained"; only the most recent header is
read.  Plack::Middleware::ReverseProxy would have to be changed to fix
that.

* When using proxyip_forwarders, X-Forwarded-Server, X-Forwarded-Host,
X-Forwarded-Port, X-Forwarded-HTTPS and X-Forwarded-Proto headers are
also supported.

