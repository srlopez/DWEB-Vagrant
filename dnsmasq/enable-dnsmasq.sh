DNSIP=$1
apt-get update
systemctl disable --now systemd-resolved
systemctl stop systemd-resolved
 
cp /etc/resolv.conf{,.bak}
cat <<EOF >/etc/resolv.conf
nameserver 127.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

apt-get install -y dnsmasq

cp /etc/dnsmasq.conf{,.bak}
cat <<EOF >/etc/dnsmasq.conf
domain-needed
bogus-priv
strict-order
expand-hosts
listen-address=127.0.0.1, $DNSIP

cname=*.balanceador.com,nginx
host-record=www.proxy.com,192.168.56.10

domain=aula104
dhcp-range=192.168.56.101,192.168.56.150,24h
dhcp-option=option:router,$DNSIP
dhcp-option=option:ntp-server,$DNSIP
dhcp-option=option:dns-server,$DNSIP
dhcp-option=option:netmask,255.255.225.0
EOF

cat <<EOF >/etc/hosts
127.0.0.1	    localhost
$DNSIP  dns.aula104     dns ns1 ns2
192.168.56.10   nginx.aula104   nginx
192.168.56.11   apache1.aula104 apache1
192.168.56.12   apache2.aula104 apache2
EOF

dnsmasq --test
systemctl restart dnsmasq