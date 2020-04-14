FROM mysql:5.6

ENV MYSQL_DATABASE teko_development
ENV MYSQL_ROOT_PASSWORD teko
ENV MYSQL_USER teko
ENV MYSQL_PASSWORD teko

ADD schema/teko_development.sql /docker-entrypoint-initdb.d/
