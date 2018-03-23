FROM ubuntu:16.04

ENV LANG C.UTF-8

# Default versions
ENV GRAFANA_VERSION  4.1.1-1484211277
ENV INFLUXDB_VERSION 1.2.4
ENV TELEGRAF_VERSION 1.2.0

# Prevent some error messages
ENV DEBIAN_FRONTEND noninteractive

# Fix bad proxy issue
COPY system/99fixbadproxy /etc/apt/apt.conf.d/99fixbadproxy

# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites
RUN apt-get -y update && \
 apt-get -y dist-upgrade && \
 apt-get -y --force-yes install \
  apt-utils \
  ca-certificates \
  curl \
  git \
  htop \
  libfontconfig \
  mysql-client \
  mysql-server \
  nano \
  net-tools \
  openssh-server \
  supervisor \
  nginx-light \
  vim \
  lsof \
  wget && \
 curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
 apt-get install -y nodejs

# Install Grafana
RUN     wget https://grafanarel.s3.amazonaws.com/builds/grafana_${GRAFANA_VERSION}_amd64.deb && \
        dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb && rm grafana_${GRAFANA_VERSION}_amd64.deb

# Install InfluxDB
RUN		wget https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
        dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb

# Install Telegraf
RUN wget https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}_amd64.deb && \
        dpkg -i telegraf_${TELEGRAF_VERSION}_amd64.deb && rm telegraf_${TELEGRAF_VERSION}_amd64.deb

# ----------------- #
#   Configuration   #
# ----------------- #

# Configure InfluxDB
ADD		influxdb/influxdb.conf /etc/influxdb/influxdb.conf 
ADD		influxdb/run.sh /usr/local/bin/run_influxdb
# These two databases have to be created. These variables are used by set_influxdb.sh and set_grafana.sh
ENV		PRE_CREATE_DB data grafana
ENV		INFLUXDB_HOST localhost:8086
ENV             INFLUXDB_DATA_USER data
ENV             INFLUXDB_DATA_PW data
ENV		INFLUXDB_GRAFANA_USER grafana
ENV		INFLUXDB_GRAFANA_PW grafana
ENV		ROOT_PW root

# Configure Grafana
ADD             ./grafana/config.ini /etc/grafana/config.ini
ADD		grafana/run.sh /usr/local/bin/run_grafana
ADD		./configure.sh /configure.sh
ADD		./set_grafana.sh /set_grafana.sh
ADD		./set_influxdb.sh /set_influxdb.sh
RUN 		/configure.sh

# Configure Telegraf
ADD              telegraf/telegraf.conf /etc/telegraf/telegraf.conf
ADD              telegraf/run.sh /usr/local/bin/run_telegraf

# Configure nginx and supervisord
ADD		./nginx/nginx.conf /etc/nginx/nginx.conf
ADD		./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ----------- #
#   Cleanup   #
# ----------- #

RUN		apt-get autoremove -y wget curl && \
			apt-get -y clean && \
			rm -rf /var/lib/apt/lists/* && rm /*.sh

# alias
RUN echo 'alias mylog="cd /var/log/supervisor"' >> ~/.bashrc


# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
EXPOSE	3000

# InfluxDB Admin server
EXPOSE	8083

# InfluxDB HTTP API
EXPOSE	8086

# InfluxDB HTTPS API
EXPOSE	8084

# -------- #
#   Run!   #
# -------- #

CMD		["/usr/bin/supervisord"]
