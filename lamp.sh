#!/bin/bash

# #Automation - By Your-Fullname
# Date: 14/06/2020 mod :10/01/2022
# Install LAMP (Linux-Apache-MySQL/MariaDB-PHP) on CentOS7

# --------------------------------------------------------------------

### Update he thong
funcion_update () {
echo ""
echo "Dang tien hanh update he thong"
echo ""
sleep 1
yum update -y
echo ""
echo "He thong da duoc update thanh cong"
echo ""
sleep 1
}

### Tat SELINUX ( not recommended)
funcion_disable_selinux () {
echo ""
echo "Dang kiem tra SELINUX ..."
echo ""
DS=`cat /etc/selinux/config | grep ^SELINUX= | awk '{print $0}'`
sleep 1
if [[ "$DS" == "SELINUX=enforcing" ]]; then
sed -i 's/enforcing/disabled/' /etc/selinux/config
echo ""
echo "Da tat SELINUX thanh cong"
echo ""
sleep 1
else
echo ""
echo "SELINUX da duoc tat"
echo ""
sleep 1
fi
}

### Cai dat LAMP
funcion_install_lamp () {
########## Cai dat Apache ##########
echo ""
echo “Dang cai dat Apache ...”
echo ""
sleep 1
yum install httpd -y
sleep 1
# Cau hinh va khoi dong httpd service
systemctl enable httpd.service
systemctl restart httpd.service
echo ""
echo "Cai dat Apache thanh cong"
echo ""
sleep 1
########## Cat dat MariaDB ##########

# Them MariaDB vao repositories
echo ""
echo "Them MariaDB vao repositories ..."
echo ""
sleep 1
cat <<EOF > /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl =http://yum.mariadb.org/10.6.5/centos7-amd64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
sleep 1
echo ""
echo "Da them MariaDB vao repositories"
echo ""
yum clean all
sleep 1

# Dang cai dat MariaDB
echo ""
echo "Dang cai dat MariaDB..."
echo ""
sleep 1
yum install -y MariaDB-server MariaDB-client
sleep 1
# Cau hinh va khoi dong mysql service
systemctl enable mariadb
systemctl start mariadb
echo ""
echo "Cai dat MariaDB thanh cong"
echo ""
sleep 1
 
########## Dang cai dat PHP ##########
echo ""
echo "Dang cai dat PHP..."
echo ""
sleep 1
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
echo ""
echo "Clean - Repolist"
echo ""
yum clean all
yum repolist
sleep 1
echo ""
echo "Yum Utils"
echo ""
yum install -y yum-utils
yum-config-manager --enable remi-php74
yum install -y php php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-xml php-pear php-bcmath php-json
sleep 1

# Khoi dong lai Apache
echo ""
echo "Dang khoi dong lai Apache"
echo ""
systemctl restart httpd
echo ""
echo "Cai dat PHP thanh cong"
echo ""
sleep 1

}

#Set MariaDB-server root password
mariadb_root_pass () {
[ ! -e /usr/bin/expect ] && { yum -y install expect; }
 
MYSQL_ROOT_PASSWORD="root@123"
 
SECURE_MYSQL=$(expect -c "
 
set timeout 10
spawn mysql_secure_installation
 
expect \"Enter current password for root (enter for none): \"
send \"n\r\"
expect \"Switch to unix_socket authentication \[Y/n\] \"
send \"n\r\"
expect \"Change the root password? \[Y/n\] \"
send \"y\r\"
expect \"New password: \"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password: \"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Remove anonymous users? \[Y/n\] \"
send \"y\r\"
expect \"Disallow root login remotely? \[Y/n\] \"
send \"y\r\"
expect \"Remove test database and access to it? \[Y/n\] \"
send \"y\r\"
expect \"Reload privilege tables now? \[Y/n\] \"
send \"y\r\"
expect eof
")

#Create a database
echo "create database wp_db" | mysql -u root -p$MYSQL_ROOT_PASSWORD
echo "GRANT ALL PRIVILEGES ON wp_db.* TO 'wp_user'@'localhost' IDENTIFIED BY '123@123Aa'" | mysql -u root -p$MYSQL_ROOT_PASSWORD
echo "flush privileges" | mysql -u root -p$MYSQL_ROOT_PASSWORD


#More: https://likegeeks.com/expect-command/
}

# Mo port 80, 443
funcion_open_port () {
echo ""
echo "Dang mo port 80 va 443"
echo ""
sleep 1
firewall-cmd --permanent --add-service={http,https}
firewall-cmd --reload
sleep 1
echo ""
echo "Port da duoc mo thanh cong"
echo ""
sleep 1
}

deploy_code ()
{
[ ! -e /usr/bin/wget ] && { yum -y install wget; }

cd /tmp	
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -R /tmp/wordpress/* /var/www/html/
#Tao file cau hinh cho wordpress
cd /var/www/html
cp wp-config-sample.php wp-config.php
# Chinh sua file cau hinh voi thong tin database, user, pass
# (DB: wp_db; User: wp_user; Pass: 123@123Aa)

sed -i s/database_name_here/wp_db/g wp-config.php
sed -i s/username_here/wp_user/g wp-config.php
sed -i s/password_here/123@123Aa/g wp-config.php

# Thay doi Ownership va Permission
chown -R $USER:apache /var/www/html
chmod -R 2775 /var/www/html
find /var/www/html -type f -exec chmod 0664 {} \;
systemctl restart httpd

}

backup () {
mkdir -p /backup/{codes,db}
DB_NAME=wp_db
DB_USER=root
DB_PASS=123@123A
nowD=$(date +%d-%m-%Y)
SRC=/var/www/html
# Backup codes
DES_CODES=/backup/codes/codes_bak_$nowD.tar.gz
DES_DB=/backup/db/wpdb_back_$nowD.sql
echo “Dang backup Codes”
tar -czf $DES_CODES $SRC > /dev/null 2>&1
#Backup DB
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $DES_DB

#Upload len google drive
rclone copy $DES_CODES gg:/BACKUP && rclone copy $DES_DB gg:/BACKUP

}
# All Install LAMP
funcion_all () {
#funcion_update
#funcion_disable_selinux
funcion_install_lamp
mariadb_root_pass
deploy_code
funcion_open_port
#backup
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
#echo "He thong se reboot sau 10s, vui long dang nhap lai de hoan tat qua trinh cai dat"
echo "De cau hinh bao mat MariaDB chay lenh: mysql_secure_installation"
echo "De xem thong tin PHP truy cap: http://IP-CUA-BAN/info.php - Trong do IP-CUA-BAN la dia chi IP cua ban"
sleep 5

}
 
funcion_all


