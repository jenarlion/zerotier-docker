ARG ALPINE_IMAGE=alpine
ARG ALPINE_VERSION=3.15
ARG ZT_COMMIT=eac56a2e25bbd27f77505cbd0c21b86abdfbd36b
ARG ZT_VERSION=1.8.4

FROM ${ALPINE_IMAGE}:${ALPINE_VERSION} as builder

ARG ZT_COMMIT

RUN apk add --update alpine-sdk linux-headers \
  && git clone --quiet https://github.com/zerotier/ZeroTierOne.git /src \
  && git -C src reset --quiet --hard ${ZT_COMMIT} \
  && cd /src \
  && make -f make-linux.mk

FROM ${ALPINE_IMAGE}:${ALPINE_VERSION}

ARG ZT_VERSION

LABEL org.opencontainers.image.title="zerotier" \
      org.opencontainers.image.version="${ZT_VERSION}" \
      org.opencontainers.image.description="ZeroTier One as Docker Image" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/zyclonite/zerotier-docker"

COPY --from=builder /src/zerotier-one /usr/sbin/

RUN apk add --no-cache --purge --clean-protected --update libc6-compat libstdc++ supervisor iptables \
  && mkdir -p /var/lib/zerotier-one \
  && mkdir -p /var/log/supervisor \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli \
  && rm -rf /var/cache/apk/*

ENV LOG_PATH=/var/log/supervisor \
    BRIDGE=false

COPY conf /opt
COPY scripts /opt

EXPOSE 9993/udp

ENTRYPOINT ["/opt/entrypoint.sh"]

CMD ["-U"]
