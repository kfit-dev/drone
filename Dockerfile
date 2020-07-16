FROM alpine:3 as alpine
RUN apk add -U --no-cache ca-certificates

FROM golang as golang

WORKDIR /src

ADD go.mod .
ADD go.sum .
RUN go mod download
ADD . .
RUN go build -ldflags "-extldflags '-static'" -tags "nolimit" ./cmd/drone-server

FROM alpine:3

EXPOSE 80 443
VOLUME /data

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=true
ENV DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=golang /src/drone-server /bin/

ENTRYPOINT ["/bin/drone-server"]