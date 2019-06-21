#基础镜像
FROM centos:latest

#作者
MAINTAINER freedoms1988 zzt328697768@gmail.com

#用户
USER root

#更新yum
RUN yum update -y

#安装vim wget openssh-server openssh-clients
RUN yum install -y vim wget openssh-server openssh-clients

#修改ssh配置
RUN sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
RUN sed -i '/^#Host_Key/'d /etc/ssh/sshd_config
RUN sed -i '/^Host_Key/'d /etc/ssh/sshd_config
RUN echo 'HostKey /etc/ssh/ssh_host_rsa_key'>/etc/ssh/sshd_config

#生成ssh-key与配置ssh-key
RUN ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key
RUN mkdir -p /root/.ssh
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNYXyDd8RLahbcgW7uLzoJgg9LHxNbl9EO82jdCh2VTOKl4ky/oK94wNeifdX8dpty9yjvV/47JU84CQWxUPm5d4xuV9zraq0G0COOMFZ0bNPQHYKaJGyDIVKbi0eWXBRxy+Doq7GCYAP1zKJSpsmHKkInJ0JOvzzcxbAFmzfgTV+2AKTv8W6o8fKFr8uA81XHbHSnUCHiiZbbQxpMaBlOPufZI1RB0E9TflGsBmjuLmVUhoDHKessZ65Mk47SSLL6B23hRWNgLdfkS6N2zAKpBUBubO4MUYwhmWLRzrvMjI7PtuhypoyKCGvd53gOzeRbtsq+q7PaGVpoRa4I0xlF freedoms@Freedoms.local'>/root/.ssh/authorized_keys

#修改root用户登录密码
RUN echo 'root:zztXXXXzzt'|chpasswd

#安装httpd依赖
RUN yum install -y apr-devel apr apr-util apr-util-devel pcre-devel gcc make

#下载httpd
WORKDIR /usr/local/src
RUN wget http://apache.01link.hk/httpd/httpd-2.4.39.tar.gz
RUN tar -zxvf httpd-2.4.39.tar.gz

#编译httpd
RUN ./httpd-2.4.39/configure --prefix=/usr/local/apache2 --enable-mods-shared=most --enable-so
RUN make && make install

#修改httpd配置
RUN sed -i 's/#ServerName www.example.com:80/ServerName localhost:80/g' /usr/local/apache2/conf/httpd.conf
RUN /usr/local/apache2/bin/httpd
#RUN systemctl enable httpd.service

#安装php依赖
RUN yum install -y unzip epel-release perl perl-devel libxml2-devel openssl-devel bzip2-devel libjpeg libjpeg-devel libpng-devel freetype-devel libmcrypt-devel

#下载php7.2.1
WORKDIR /usr/local/src
RUN wget https://www.php.net/distributions/php-7.2.1.tar.gz
RUN ls -a 
RUN tar -zxvf php-7.2.1.tar.gz

#下载mysql5.6.42
WORKDIR /usr/local/src
RUN wget http://ftp.jaist.ac.jp/pub/mysql/Downloads/MySQL-5.6/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz
RUN tar -zxvf mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz
RUN mv ./mysql-5.6.42-linux-glibc2.12-x86_64 /usr/local/mysql

#编译php7.2.1
RUN pwd
RUN ls -a
RUN ./php-7.2.1/configure --prefix=/usr/local/php --with-apxs2=/usr/local/apache2/bin/apxs --with-config-file-path=/usr/local/php/etc --with-mysql=/usr/local/mysql --with-libxml-dir --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --with-iconv-dir --with-zlib-dir --with-bz2 --with-openssl --with-mcrypt --enable-soap --enable-gd-native-ttf --enable-mbstring --enable-sockets --enable-exif --disable-ipv6
RUN make && make install

#检查php7.2.1编译结果
RUN ls /usr/local/apache2/modules/libphp7.so

#修改apache配置
RUN sed -i 's#DirectoryIndex index.html#DirectoryIndex index.html index.php index.htm#g' /usr/local/apache2/conf/httpd.conf
RUN sed -i 's#ServerName www.example.com:80#ServerName localhost:80#g' /usr/local/apache2/conf/httpd.conf
RUN sed -i 's#<IfModule dir_module> DirectoryIndex index.html </IfModule>#<IfModule dir_module> DirectoryIndex index.html index.htm index.php </IfModule>#g' /usr/local/apache2/conf/httpd.conf
RUN sed -i '/AddType application\/x-gzip .gz .tgz/a\    AddType application/x-httpd-php \.php' /usr/local/apache2/conf/httpd.conf
RUN /usr/local/apache2/bin/apachectl -k graceful

#开放端口
EXPOSE 80 22

#启动镜像时，启动sshd与httpd
CMD /usr/sbin/sshd & /usr/local/apache2/bin/httpd -D FOREGROUND