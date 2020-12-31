FROM ubuntu:20.10

ARG NGINX_GIT=https://github.com/nginx/nginx.git
ARG NGINX_RTMP_GIT=https://github.com/arut/nginx-rtmp-module.git
ARG NGINX_RELEASE=release-1.19.6
ARG DEBIAN_FRONTEND=noninteractive

RUN apt -y update && \
    apt install -y apt-utils && \
    apt install -y --no-install-recommends build-essential make \
    gcc git file pkg-config wget curl libpcre3-dev libssl-dev \
    ssh-client zlib1g-dev perl libperl-dev libgd3 libgd-dev \
    libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev \
    libxslt1.1 libxslt1-dev && apt-get clean && \
    apt install -y --reinstall ca-certificates && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /build_nginx

RUN git clone --depth 1 --branch $NGINX_RELEASE $NGINX_GIT
RUN git clone $NGINX_RTMP_GIT

RUN wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && \
    tar xzvf pcre-8.44.tar.gz

RUN wget https://www.zlib.net/zlib-1.2.11.tar.gz && \
    tar xzvf zlib-1.2.11.tar.gz

RUN wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz && \
    tar xzvf openssl-1.1.1g.tar.gz

RUN bash -c 'mkdir -p /home/broadcaster/stream_data/{hls,dash}' && \
    bash -c 'mkdir -p /home/broadcaster/{run,conf,log,ssl}' && \
    bash -c 'mkdir -p /home/broadcaster/cache/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp}'

RUN useradd -ms /bin/bash broadcaster

RUN cd nginx && ./auto/configure --prefix=/etc/nginx \
            --add-module=../nginx-rtmp-module \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/home/broadcaster/conf/nginx.conf \
            --error-log-path=/home/broadcaster/log/error.log \
            --pid-path=/home/broadcaster/run/nginx.pid \
            --lock-path=/home/broadcaster/run/nginx.lock \
            --user=broadcaster \
            --group=broadcaster \
            --build=Ubuntu \
            --builddir=nginx-1.19.6 \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --with-http_perl_module=dynamic \
            --with-perl_modules_path=/usr/share/perl/5.26.1 \
            --with-perl=/usr/bin/perl \
            --http-log-path=/home/broadcaster/log/access.log \
            --http-client-body-temp-path=/home/broadcaster/cache/client_temp \
            --http-proxy-temp-path=/home/broadcaster/cache/proxy_temp \
            --http-fastcgi-temp-path=/home/broadcaster/cache/fastcgi_temp \
            --http-uwsgi-temp-path=/home/broadcaster/cache/uwsgi_temp \
            --http-scgi-temp-path=/home/broadcaster/cache/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../pcre-8.44 \
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-openssl=../openssl-1.1.1g \
            --with-openssl-opt=no-nextprotoneg \
            --with-debug

RUN cd nginx && \
    make && \
    make install

WORKDIR /home/broadcaster

RUN rm -rf /build_nginx

COPY ./nginx.conf /home/broadcaster/conf/.

COPY ./cert.pem /home/broadcaster/ssl/.
COPY ./key.pem /home/broadcaster/ssl/.

RUN chown -R broadcaster:broadcaster /home/broadcaster

USER broadcaster

CMD nginx && tail -f /home/broadcaster/log/access.log
