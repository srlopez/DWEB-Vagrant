DNSIP=$1
DIR=$(echo $1 | cut -d '.' -f-3)
REV=$(echo $1 | tac -s. | tail -1 | cut -d '.' -f-3)
ZONA="aula104.local"

apt-get update
apt-get install -y bind9 bind9utils bind9-doc
 
cat <<EOF >/etc/bind/named.conf.options
acl "allowed" {
    $DIR.0/24;
};

options {
    directory "/var/cache/bind";
    dnssec-validation auto;

    listen-on-v6 { any; };
    forwarders { 1.1.1.1;  1.0.0.1;  };
};
EOF

cat <<EOF >/etc/bind/named.conf.local
zone $ZONA {
        type master;
        file "/var/lib/bind/$ZONA";
        };
zone "$REV.in-addr.arpa" {
        type master;
        file "/var/lib/bind/$DIR.rev";
        };
EOF

cat <<EOF >/var/lib/bind/$ZONA
\$TTL 3600
$ZONA.     IN      SOA     ns.$ZONA. santi.$ZONA. (
                3            ; serial
                7200         ; refresh after 2 hours
                3600         ; retry after 1 hour
                604800       ; expire after 1 week
                86400 )      ; minimum TTL of 1 day

$ZONA.                  IN      NS      ns.$ZONA.
ns.aula104.local.       IN      A       $DNSIP
ns1.aula104.local.      IN      CNAME   ns
ns2.aula104.local.      IN      CNAME   ns
apache1.aula104.local.  IN      A       $DIR.11
apache2                 IN      A       $DIR.12
sv1                     IN      CNAME   apache1
sv2                     IN      CNAME   apache2
nginx                   IN      A       $DIR.10
proxy                   IN      CNAME   nginx
balanceador             IN      CNAME   nginx
EOF

cat <<EOF >/var/lib/bind/$DIR.rev
\$ttl 3600
$REV.in-addr.arpa.  IN      SOA     ns.aula104.local. santi.aula104.local. (
                3            ; serial
                7200         ; refresh after 2 hours
                3600         ; retry after 1 hour
                604800       ; expire after 1 week
                86400 )      ; minimum TTL of 1 day
$REV.in-addr.arpa.  IN      NS      ns.aula104.local.
100 IN  PTR dns
10  IN  PTR nginx
11  IN  PTR apache1
12  IN  PTR apache2
EOF

cp /etc/resolv.conf{,.bak}
cat <<EOF >/etc/resolv.conf
nameserver 127.0.0.1
domain $ZONA
EOF

named-checkconf
named-checkconf /etc/bind/named.conf.options
named-checkzone $ZONA /var/lib/bind/$ZONA
named-checkzone $REV.in-addr.arpa /var/lib/bind/$DIR.rev
sudo systemctl restart bind9

