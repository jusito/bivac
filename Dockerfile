ARG GO_VERSION
ARG RUNTIME_IMAGE
FROM golang:${GO_VERSION} as builder

COPY scripts/build/* /usr/local/bin
RUN (apt-get update && apt-get install git make) \
    || (apk update && apk add git make); \
    git config --global advice.detachedHead false; \
    chmod +x /usr/local/bin/*

ARG GOOS
ARG GOARCH
ARG GOARM

ENV GO111MODULE=on
ENV GOOS=${GOOS}
ENV GOARCH=${GOARCH}
ENV GOARM=${GOARM}

# Rclone
ARG RCLONE_VERSION
WORKDIR /go/src/github.com/rclone/rclone
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    build_rclone.sh "$RCLONE_VERSION" "${BUILD_OPTS:-}"

# Restic
WORKDIR /go/src/github.com/restic/restic
ARG RESTIC_VERSION
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    build_restic.sh "$RESTIC_VERSION" "${BUILD_OPTS:-}"

# Bivac
WORKDIR /go/src/github.com/camptocamp/bivac
COPY . .
RUN env ${BUILD_OPTS:-} make bivac

FROM "$RUNTIME_IMAGE"
RUN set -eux; \
    if apt --version; then \
        apt-get update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-client procps; \
        rm -rf /var/lib/apt/lists/*; \
    else \
        apk add --no-cache openssh; \
    fi;
COPY --from=builder /etc/ssl /etc/ssl
COPY --from=builder /go/src/github.com/camptocamp/bivac/bivac /bin/bivac
COPY --from=builder /go/src/github.com/camptocamp/bivac/providers-config.default.toml /
COPY --from=builder /go/src/github.com/restic/restic/restic /bin/restic
COPY --from=builder /go/src/github.com/rclone/rclone/rclone /bin/rclone
ENTRYPOINT ["/bin/bivac"]
CMD [""]
