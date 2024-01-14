# BUild the Go Binary 
FROM golang:1.20 as build_profile-api
ENV CGO_ENABLED 0
ARG BUILD_REF


RUN mkdir /backend
COPY . /backend_v2
WORKDIR /backend_v2/app/services/profile-api/
RUN go build -o profile-backend-api -ldflags "-X main.build=${BUILD_REF}"


FROM alpine:3.17
ARG BUILD_DATE
ARG BUILD_REF
RUN addgroup -g 1000 -S profile && \
    adduser -u 1000 -h /backend_v2 -G profile -S profile
# reason for the second profile-api is because profile-api is the binary code built from line 10
COPY --from=build_profile-api --chown=profile:profile /backend_v2/app/services/profile-api/profile-backend-api /backend_v2/profile-api
RUN chmod +x /backend_v2/profile-api
RUN pwd
USER profile
CMD ["backend_v2/profile-api"]

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="profile-api" \
      org.opencontainers.image.authors="Jeremy Elam <jelam2975@gmail.com>" \
      org.opencontainers.image.source="https://github.com/ardanlabs/service/app/profile-api" \
      org.opencontainers.image.revision="${BUILD_REF}" \
      org.opencontainers.image.vendor="Ardan Labs"
