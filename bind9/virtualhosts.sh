ID=$1
IP1=$2
IP2=$3
DOM=$4

# Instala el módulo php para apache y el php correspondiente
apt install -y libapache2-mod-php 
# Preparamos index.php
mv /var/www/html/index.html /var/www/html/index.html.org
cat <<EOF >/var/www/html/index.php
<style>*{font-family:Consolas,monaco,monospace; font-size: 20px;}</style><pre>
<?php print
"SERVER_NAME     ".\$_SERVER['SERVER_NAME']."\n".
"SERVER_ADDR     ".\$_SERVER['SERVER_ADDR']."\n".
"SERVER_PORT     ".\$_SERVER['SERVER_PORT']."\n".
"HTTP_HOST       ".\$_SERVER['HTTP_HOST']."\n".
"REQUEST_URI     ".\$_SERVER['REQUEST_URI']."\n".
"SCRIPT_FILENAME ".\$_SERVER['SCRIPT_FILENAME']."\n".
"REMOTE_ADDR     ".\$_SERVER['REMOTE_ADDR']."\n".
"X_FORWARDED_FOR ".\$_SERVER['HTTP_X_FORWARDED_FOR']."\n".
"The time is     " . date("h:i:sa")."\n";
// foreach(\$_SERVER as \$key => \$value) print \$key."=".\$value."\n";
?>
</pre>
EOF

# Preparamos la configuración de hosts
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.org
cat <<EOF >/etc/apache2/sites-available/000-default.conf
# Discriminamos por ServerAlias
<VirtualHost *:80>
  DocumentRoot "/var/www/apache"
  ServerAlias apache$ID.$DOM
</VirtualHost>
<VirtualHost *:80>
  DocumentRoot "/var/www/sv"
  ServerAlias sv$ID.$DOM
</VirtualHost>
<VirtualHost *:80>
  DocumentRoot "/var/www/80"
  ServerAlias *
</VirtualHost>
# Lo que venga por IP:8080
Listen 8080
# Discriminamos por IP
<VirtualHost $IP1:8080>
  DocumentRoot "/var/www/192"
</VirtualHost>
<VirtualHost $IP2:8080>
  DocumentRoot "/var/www/10"
</VirtualHost>
# Nada entra por aquí
# Se redirigen según la IP anterior que resuelva
<VirtualHost *:8080>
  DocumentRoot "/var/www/8080"
  ServerAlias *
</VirtualHost>
EOF

# Creamos los directorios de las aplicaciones
# todos igual ya que variaran a la hora de mostrar la información
cd /var/www/
rm apache sv 80 192 10 8080
ln -s html apache
ln -s html sv
ln -s html 80
ln -s html 192
ln -s html 10
ln -s html 8080

systemctl restart apache2
curl -s apache$ID
curl -s $IP2:8080