# BUild the Go Binary 
FROM golang:1.19 as build_profile-api
ENV CGO_ENABLED 0
ARG BUILD_REF


RUN mkdir /backend
COPY . /backend_v2
WORKDIR /backend_v2/app/services/profile-api/
RUN go build -ldflags "-X main.build=${BUILD_REF}"


FROM alpine:3.17
ARG BUILD_DATE
ARG BUILD_REF
RUN addgroup -g 1000 -S profile && \
    adduser -u 1000 -h /backend_v2 -G profile -S profile
COPY --from=build_profile-api --chown=profile:profile /backend_v2/app/services/profile-api /backend_v2/profile-api
RUN chmod +x /backend_v2/profile-api
RUN pwd
USER profile
CMD ["backend_v2/profile-api"]

# Copy the source code into the container. 
# COPY . /backend_v2


# # Build the service binary 
# WORKDIR /backend_v2/app/services/profile-api/
# RUN go build -ldflags "-X main.build=${BUILD_REF}"


# # Run the Go Binary in Alpine.
# FROM alpine:3.17
# ARG BUILD_DATE
# ARG BUILD_REF
# RUN addgroup -g 1000 -S profile && \
#     adduser -u 1000 -h /backend_v2 -G profile -S profile
# # COPY --from=build_profile-api --chown=profile:profile /service/zarf/keys/. /service/zarf/keys/.
# # COPY --from=build_profile-api --chown=profile:profile /service/app/tooling/profile-admin/profile-admin /service/profile-admin
# COPY --from=build_profile-api --chown=profile:profile /backend_v2/app/services/profile-api /backend/profile-api
# WORKDIR /backend
# USER profile
# CMD ["./profile-api"]

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="profile-api" \
      org.opencontainers.image.authors="Jeremy Elam <jelam2975@gmail.com>" \
      org.opencontainers.image.source="https://github.com/ardanlabs/service/app/profile-api" \
      org.opencontainers.image.revision="${BUILD_REF}" \
      org.opencontainers.image.vendor="Ardan Labs"
