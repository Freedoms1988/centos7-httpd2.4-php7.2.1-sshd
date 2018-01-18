#基础镜像
FROM freedoms1988/centos7-sshd:v2

#作者
MAINTAINER freedoms1988 zzt328697768@gmail.com

#用户
USER root

#安装php依赖
RUN yum install -y perl libxml2 openssl bzip2 libjpeg libpng freetype libmcrypt mbstring

#安装apache依赖
RUN yum install -y  apr apr-util pcre

#复制编译好的httpd文件到容器（要求在相同环境下编译好apache2，并将目录复制至dockfile保存目录）
COPY apache2 /usr/local/apache2

#复制编译好的php7.2.1文件到容器（要求在相同环境下编译好php，并将目录复制至dockfile保存目录）
COPY php /usr/local/php

#复制编译好的libphp7.so文件到容器（要求在相同环境下编译好php，并将apache2/modules中的libphp7.so文件复制至dockfile保存目录）
COPY libphp7.so /usr/local/apache2/modules/

#修改apache配置
RUN sed -i 's#DirectoryIndex index.html#DirectoryIndex index.html index.php index.htm#g' /usr/local/apache2/conf/httpd.conf
RUN sed -i 's#ServerName www.example.com:8#ServerName localhost:80#g' /usr/local/apache2/conf/httpd.conf
RUN sed -i '/AddType application\/x-gzip .gz .tgz/a\    AddType application/x-httpd-php \.php' /usr/local/apache2/conf/httpd.conf

#开放端口
EXPOSE 80

#启动apache服务
CMD /usr/local/apache2/bin/httpd -D FOREGROUND