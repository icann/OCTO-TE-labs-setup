#!/bin/bash
#
# This script install running resolv1, resolv2, soa, ns1 and ns2 for a group
# -- This is really handy if you have a short workshop and only want to focus on DNSSEC
# usage --: ./doit.sh <group_number> <domain>
#
set -exou

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <group_number> <domain>"
  exit 1
fi

# Validate that the first argument is numeric
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Error: The first argument must be a numeric group number."
  exit 1
fi

# save arguments to named variables
GRP=$1
DOMAIN=$2

# Let the fun begin
echo "Fixing group $GRP $DOMAIN"

#
# resolv1 - bind9
#
lxc exec grp$GRP-resolv1 -- sh -c 'mv /etc/resolv.conf /etc/resolv.conf.orig'
lxc exec grp$GRP-resolv1 -- sh -c 'echo "nameserver 9.9.9.9"|sudo tee /etc/resolv.conf'

cat <<EOF >/tmp/named.conf.options.resolv1
options {
  directory "/var/cache/bind";
  dnssec-validation no;
  listen-on port 53 { localhost; 100.100.0.0/16; };
  listen-on-v6 port 53 { localhost; fd89:59e0::/32; };
  allow-query { any; };
  recursion yes;
};
EOF

lxc exec grp$GRP-resolv1 -- sh -c 'apt install -qy bind9'
lxc file push /tmp/named.conf.options.resolv1 grp$GRP-resolv1/etc/bind/named.conf.options
lxc exec grp$GRP-resolv1 -- sh -c 'systemctl enable named'
lxc exec grp$GRP-resolv1 -- sh -c 'systemctl restart named'
lxc exec grp$GRP-resolv1 -- sh -c 'mv /etc/resolv.conf.orig /etc/resolv.conf'

#
# resolv2 - unbound
#
cat <<EOF > /tmp/unbound.conf
server:
        interface: 0.0.0.0
        interface: ::0

        access-control: 0.0.0.0/0 allow
        access-control: ::/0 allow

        port: 53

        do-udp: yes
        do-tcp: yes
        do-ip4: yes
        do-ip6: yes

remote-control:
    control-enable: yes
EOF

lxc exec grp$GRP-resolv2 -- sh -c 'apt install -qy unbound'
lxc exec grp$GRP-resolv2 -- sh -c 'rm -rf /etc/unbound/unbound.conf.d'
lxc file push /tmp/unbound.conf grp$GRP-resolv2/etc/unbound/unbound.conf
lxc exec grp$GRP-resolv2 -- sh -c 'unbound-control-setup'
lxc exec grp$GRP-resolv2 -- sh -c 'systemctl enable unbound'
lxc exec grp$GRP-resolv2 -- sh -c 'systemctl restart unbound'

#
# soa - bind9
#
cat <<EOF > /tmp/db.grp$GRP
; grp${GRP}

\$TTL    30
@       IN      SOA     ${DOMAIN}. te-labs.icann.org. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                             30 )       ; Negative Cache TTL
@           NS          ${DOMAIN}.
@           TXT         "DNS IS FUN"
ns1         A           100.100.${GRP}.130
ns1         AAAA        fd89:59e0:${GRP}:128::130
ns2         A           100.100.${GRP}.131
ns2         AAAA        fd89:59e0:${GRP}:128::131
EOF

cat <<EOF > /tmp/named.conf.local.primary
zone "grp${GRP}.${DOMAIN}." {
	type primary;
	file "/var/lib/bind/zones/db.grp${GRP}";
	allow-transfer { any; };
	also-notify {
		100.100.${GRP}.130; 
		100.100.${GRP}.131; 
		fd89:59e0:${GRP}:128::130; 
		fd89:59e0:${GRP}:128::131; 
	};
}; 
EOF

cat <<EOF > /tmp/named.conf.options.primary
options {
    directory "/var/cache/bind";
    server-id "hidden primary";
    version "grp${GRP}";
    hostname "grp${GRP}-soa";
    dnssec-validation no;
    listen-on port 53 { localhost; 100.100.0.0/16; };
    listen-on-v6 port 53 { localhost; fd89:59e0::/32; };
    allow-query { any; };
    allow-transfer { any; };
    also-notify { any; };
    recursion yes;
};
EOF

lxc exec grp$GRP-soa -- sh -c 'apt install -qy bind9'
lxc exec grp$GRP-soa -- sh -c 'mkdir -p /var/lib/bind/zones'
lxc file push /tmp/named.conf.options.primary grp$GRP-soa/etc/bind/named.conf.options
lxc file push /tmp/named.conf.local.primary grp$GRP-soa/etc/bind/named.conf.local
lxc file push /tmp/db.grp$GRP grp$GRP-soa/var/lib/bind/zones/db.grp$GRP
lxc exec grp$GRP-soa -- sh -c 'systemctl enable named'
lxc exec grp$GRP-soa -- sh -c 'systemctl restart named'
lxc exec grp$GRP-soa -- sh -c 'chown -R bind:bind /var/lib/bind'

#
# ns1 - bind9 secondary
#
cat <<EOF > /tmp/named.conf.local.secondary
zone "grp${GRP}.${DOMAIN}" {
    type secondary;
    file "/etc/bind/zones/db.grp${GRP}.secondary";
    masters { 
        100.100.${GRP}.66; 
        fd89:59e0:${GRP}:64::66;
    };
};
EOF

cat <<EOF > /tmp/named.conf.options.secondary
options {
    directory "/var/cache/bind";
    server-id "${GRP} Secondary server_id";
    version "grp${GRP}";
    hostname "${GRP} Secondary host_name";
    dnssec-validation no;
    listen-on port 53 { localhost; 100.100.0.0/16; };
    listen-on-v6 port 53 { localhost; fd89:59e0::/32; };
    allow-query { any; };
    recursion yes;
    cookie-secret "71ff147d946b942ed66e608b64dc54c9";
};
EOF

lxc exec grp$GRP-ns1 -- sh -c 'apt install -qy bind9'
lxc exec grp$GRP-ns1 -- sh -c 'mkdir -p /var/lib/bind/zones'
lxc file push /tmp/named.conf.options.secondary grp$GRP-ns1/etc/bind/named.conf.options
lxc file push /tmp/named.conf.local.secondary grp$GRP-ns1/etc/bind/named.conf.local
lxc exec grp$GRP-ns1 -- sh -c 'touch /var/lib/bind/zones/db.grp$GRP.secondary'
lxc exec grp$GRP-ns1 -- sh -c 'systemctl enable named'
lxc exec grp$GRP-ns1 -- sh -c 'systemctl restart named'
lxc exec grp$GRP-ns1 -- sh -c 'chown -R bind:bind /var/lib/bind'

#
# ns2 - nsd secondary
#
cat <<EOF > /tmp/nsd.conf
server:
    log-only-syslog: yes
    zonesdir: "/var/lib/nsd"
    nsid: "ascii_grp${GRP} NSD nsid"
    hide-version: no
    hide-identity: no
    cookie-secret: "71ff147d946b942ed66e608b64dc54c9"
    answer-cookie: yes

pattern:
    name: "fromprimary"
    allow-notify: 100.100.${GRP}.66 NOKEY
    allow-notify: fd89:59e0:${GRP}:64::66 NOKEY
    allow-notify: fd89:59e0:${GRP}::2 NOKEY
    request-xfr: AXFR 100.100.${GRP}.66 NOKEY
    request-xfr: AXFR fd89:59e0:${GRP}:64::66 NOKEY
    request-xfr: AXFR fd89:59e0:${GRP}::2 NOKEY

zone:
    name: "grp${GRP}.${DOMAIN}."
    zonefile: "db.grp${GRP}.secondary"
    include-pattern: "fromprimary"
EOF

lxc exec grp$GRP-ns2 -- sh -c 'apt install -qy nsd'
lxc exec grp$GRP-ns2 -- sh -c 'mkdir -p /var/lib/nsd'
lxc file push /tmp/nsd.conf grp$GRP-ns2/etc/nsd/nsd.conf
lxc exec grp$GRP-ns2 -- sh -c 'touch /var/lib/nsd/db.grp$GRP.secondary'
lxc exec grp$GRP-ns2 -- sh -c 'systemctl enable nsd'
lxc exec grp$GRP-ns2 -- sh -c 'systemctl restart nsd'
lxc exec grp$GRP-ns2 -- sh -c 'chown -R nsd:nsd /var/lib/nsd'

# Done
echo "All done for group $GRP $DOMAIN"
