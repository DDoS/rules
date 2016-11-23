FROM ubuntu:14.04

RUN apt-get update && apt-get install -y wget
RUN wget http://netcologne.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list
RUN apt-get update && apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring && apt-get update \
    && apt-get install -y dmd-bin dub libcurl3-gnutls libevent-dev libcrypto++-dev libssl-dev

ADD langserver /langserver
ADD lang /lang

RUN apt-get update && apt-get install dub
RUN cd /lang && dub add-local . && cd /

WORKDIR /langserver

EXPOSE 9090

RUN dub fetch libasync vibe-d &>/dev/null
RUN dub run libasync &>/dev/null

CMD ["dub"]
