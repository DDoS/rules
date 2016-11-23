FROM golang:1.7

MAINTAINER Michael Golfi <michael.m.golfi@gmail.com>, Aleksi Sapon <aleksi.sapon@gmail.com>, Sheng Liu <shenghaoliu.399@gmail.com>

ADD . /go/src/github.com/michael-golfi/rules/server
WORKDIR /go/src/github.com/michael-golfi/rules/server

RUN go get github.com/Masterminds/glide
RUN glide install
RUN go install github.com/michael-golfi/rules/server

CMD [ "/go/bin/server" ]
EXPOSE 8080