FROM alpine:latest

RUN apk update && \
	apk upgrade && \
	apk add nginx

EXPOSE 80 80

ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]

