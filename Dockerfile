FROM golang:1.25-alpine AS builder
RUN apk --no-cache add tzdata
WORKDIR /go/src/github.com/serjs/socks5
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-s' -o ./socks5

FROM gcr.io/distroless/static:nonroot AS distroless
COPY --from=builder /go/src/github.com/serjs/socks5/socks5 /
ENTRYPOINT ["/socks5"]

# https://hub.docker.com/r/alpine/curl/tags
FROM alpine/curl:8.8.0 AS curl
COPY --from=distroless /socks5 /bin

ENV PROXY_PORT 1080

# Expressions don't expand in single quotes, use double quotes for that.
# hadolint ignore=SC2016
RUN echo 'curl -ipv4 --proxy socks5://${PROXY_USER}:${PROXY_PASSWORD}@0.0.0.0:${PROXY_PORT} -vI -H "user-agent: socks5/healthcheck" http://example.com/' > /healthcheck.sh \
        && chown nobody /healthcheck.sh \
        && chmod 744 /healthcheck.sh

USER nobody

EXPOSE 1080
ENTRYPOINT ["/bin/socks5"]
