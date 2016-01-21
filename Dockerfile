FROM scratch

MAINTAINER Michael Golfi <michael.m.golfi@gmail.com>, Aleksi Sapon <aleksi.sapon@gmail.com>, Sheng Liu <shenghaoliu.399@gmail.com>

ADD $GOPATH/bin/rules .

RUN ./rules