# FROM wordpress:php8.2-fpm-alpine
FROM debian:bullseye

RUN apt update -y && apt upgrade -y && apt-get install wget -y && apt install procps -y 

RUN apt-get install -y php7.4\
						php-fpm\
						php-mysql\
						mariadb-client \
						curl

RUN wget https://wordpress.org/latest.zip -P /var/www

RUN apt-get install -y unzip && cd /var/www && unzip latest.zip && rm latest.zip

RUN	chown -R root:root /var/www/wordpress

COPY ./conf/php.conf /etc/php/7.4/fpm/pool.d/www.conf

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

RUN chmod +x wp-cli.phar

RUN mv wp-cli.phar /usr/local/bin/wp

COPY conf/wp-config-cli.sh wp-config-cli.sh

EXPOSE 9000

ENTRYPOINT ["bash", "wp-config-cli.sh"]