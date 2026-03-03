FROM alpine:latest
RUN apk add --no-cache curl
WORKDIR /app
COPY log-gen.sh .
RUN chmod +x log-gen.sh
CMD ["./log-gen.sh"]
