# Documentación de Forwarded
# https://codingshower.com/apache-server-get-actual-client-ip-address-behind-proxy-or-load-balancer/
# https://www.purocodigo.net/articulo/balanceo-de-carga-de-alto-rendimiento-con-nginx 
echo "<h1>Nginx como proxy inverso y balanceador de carga</h>">/var/www/html/index.html
cat <<EOF >/etc/nginx/sites-available/000-default
# Pasamos la dirección del cliente
proxy_set_header Host i\$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; # La IP Cliente
proxy_set_header X-Forwarded-Proto \$scheme;

upstream misapis {
    # Con propósitos educativos
    # Los servidores deberían proveer el mismo servicio
    server apache1.aula104.local;
    server apache2.aula104.local;
    server sv1;
    server sv2;
    server 192.168.1.11:8080;
    server 10.0.0.12:8080;
    server localhost:8080; #para jugar tambien accedo al puerto local 8080
}

server {
    # Sin ninguna confifuración ningx muestra su página en 8080
    listen 8080;
}

server {
    listen 80;

    # Permitimos acceder a las páginas directamente, si existe
    # curl http://localhost/index.nginx-debian.html
    root /var/www/html;
    index index.html index.nginx-debian.html;

    # En /api/ redirijo a los servidores de carga
    # curl -D - http://localhost/api 301
    # curl -D - http://localhost/api/ 200
    # curl -D - http://localhost/api/1 400
    location /api/ {
        proxy_pass http://misapis/;
    }

    # Proxy inverso a apache1 en /uno/
    location /uno/ {
        proxy_pass http://apache1/;
    }

    # Proxy inverso a apache2 en /dos/
    location /dos/ {
        proxy_pass http://apache2/;
    }

    # Redirección por 301 al dominio general
    # curl -s -D - -o /dev/null http://localhost/
    # curl -L http://localhost/
    location  = / {
       rewrite ^/(.*)\$ http://aula104.local/ permanent;
    }

    # Redirección por reescritura absoluta de url host de aula104.local
    # curl http://localhost/goto/(host)
    location /goto/ {
        rewrite ^/goto/(.*)\$ http://\$1.aula104.local redirect;
    }

    # Redirección por reescritura relativa de url (local)
    # curl http://localhost/local/(path)
    # curl -D - http://localhost/local/pepe # 302
    # curl -L -D - http://localhost/local/pepe # 404
    # curl -L -D - http://localhost/local/dos # 200
    location /local/ {
        rewrite ^/local/(.*)\$ /\$1 redirect;
    }

    # Caemos aquí por defecto
    # y para cualquier otra cosa  que no exista,
    # muestra el index de root
    # tiene que haber directiva root e index
    location / {
        if (!-e \$request_filename){
           # rewrite ^(.*)\$ /index.html break;
           rewrite ^(.*)\$ / break;
        }
    }
}
EOF

cd /etc/nginx/sites-enabled
rm default
ln -s ../sites-available/000-default 
nginx -t
systemctl restart nginx
curl -s -D - -o /dev/null http://localhost/
curl -L http://localhost/