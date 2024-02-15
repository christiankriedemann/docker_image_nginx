# Verwende Alpine Linux als Basis
FROM alpine:3.15

# Setze Umgebungsvariablen für den Nginx-Build
ARG NGINX_VERSION
ENV NGINX_VERSION ${NGINX_VERSION}
ENV PREFIX /etc/nginx
ENV SBIN_PATH /usr/sbin/nginx
ENV MODULES_PATH /etc/nginx/modules
ENV CONF_PATH /etc/nginx/nginx.conf
ENV ERROR_LOG_PATH /var/log/nginx/error.log
ENV HTTP_LOG_PATH /var/log/nginx/access.log
ENV PID_PATH /var/run/nginx.pid
ENV LOCK_PATH /var/run/nginx.lock

# Installiere Abhängigkeiten
RUN apk add --update --no-cache \
    build-base \
    linux-headers \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    libedit-dev \
    bash \
    alpine-sdk \
    findutils \
    certbot \
    dcron \
    wget \
    git \
    curl

RUN mkdir -p /usr/src
WORKDIR /usr/src

# Lade Nginx-Quellcode herunter und entpacke ihn
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar -zxvf nginx-${NGINX_VERSION}.tar.gz

# Lade Nginx und zusätzliche Module herunter
RUN git clone https://github.com/arut/nginx-rtmp-module.git
RUN git clone https://github.com/kaltura/nginx-vod-module.git
RUN git clone https://github.com/google/ngx_brotli.git && cd ngx_brotli && git submodule update --init
RUN git clone https://github.com/FRiCKLE/ngx_cache_purge.git
RUN git clone https://github.com/arut/nginx-dav-ext-module.git

WORKDIR /usr/src/nginx-${NGINX_VERSION}

# Kompiliere Nginx mit zusätzlichen Modulen
RUN ./configure \
    --prefix=${PREFIX} \
    --sbin-path=${SBIN_PATH} \
    --modules-path=${MODULES_PATH} \
    --conf-path=${CONF_PATH} \
    --error-log-path=${ERROR_LOG_PATH} \
    --http-log-path=${HTTP_LOG_PATH} \
    --pid-path=${PID_PATH} \
    --lock-path=${LOCK_PATH} \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-cc-opt='-g -O2 -flto=auto -ffat-lto-objects -flto=auto -ffat-lto-objects -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -flto=auto -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --add-module=/usr/src/nginx-rtmp-module \
    --add-module=/usr/src/nginx-vod-module \
    --add-module=/usr/src/ngx_brotli \
    --add-module=/usr/src/ngx_cache_purge \
    --add-module=/usr/src/nginx-dav-ext-module \
    && make \
    && make install

WORKDIR /usr/src

# Bereinige
RUN rm -rf /usr/src/*
RUN apk del build-base linux-headers alpine-sdk findutils wget git openssl-dev zlib-dev libxslt-dev gd-dev geoip-dev perl-dev libedit-dev

# Installiere Abhängigkeiten (Ersatz der dev-Pakete)
RUN apk add --update --no-cache \
    openssl \
    zlib \
    libxslt \
    gd \
    geoip \
    perl \
    libedit

# Richte Verzeichnisse ein
RUN mkdir -p /var/www/certbot
RUN mkdir -p /etc/nginx/conf.d
RUN mkdir -p /var/log/nginx
RUN mkdir -p /var/cache/nginx

# Füge ein Start-Skript hinzu
COPY ./data/start.sh /start.sh
RUN chmod +x /start.sh

# Füge ein Crontab-Datei hinzu
COPY ./data/crontab.txt /crontab.txt
RUN /usr/bin/crontab /crontab.txt

# Füge Nginx-Konfigurationen hinzu
# Hinweis: Füge hier deine eigenen Nginx-Konfigurationen hinzu
# COPY nginx.conf /etc/nginx/nginx.conf
# COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

WORKDIR /

CMD ["/start.sh"]
