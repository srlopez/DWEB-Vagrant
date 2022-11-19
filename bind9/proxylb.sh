# Documentación de Forwarded
# https://codingshower.com/apache-server-get-actual-client-ip-address-behind-proxy-or-load-balancer/

cat <<EOF >/etc/nginx/sites-available/000-default
# Pasamos la dirección del cliente
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
upstream MisBALANCEADOS {
    # Con propósitos educativos
    # Los servidores deberían proveer el mismo servico
    server apache1.aula104.local;
    server apache2.aula104.local;
    server sv1;
    server sv2;
    server 192.168.1.11:8080;
    server 10.0.0.12:8080;
}

server {
    listen 80;

    # En / redirijo a los servidores de carga
    location / {
        proxy_pass http://MisBALANCEADOS;
    }

    # Proxy inverso a apache1 en /uno
    location /uno {
        proxy_pass http://apache1/;
    }

    # Proxy inverso a apache2 en /dos
    location /dos {
        proxy_pass http://apache2/;
    }
}
EOF

cd /etc/nginx/sites-enabled
rm default
ln -s ../sites-available/000-default 
systemctl restart nginx