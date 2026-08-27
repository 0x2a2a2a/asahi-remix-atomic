ARG BASE_IMAGE

FROM scratch AS ctx

COPY build_files /

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/var/log \
    --mount=type=tmpfs,dst=/var/lib \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/01.base.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/var/log \
    --mount=type=tmpfs,dst=/var/lib \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/02.asahi.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/var/log \
    --mount=type=tmpfs,dst=/var/lib \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/03.desktop.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/var/log \
    --mount=type=tmpfs,dst=/var/lib \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/04.misc.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/var/log \
    --mount=type=tmpfs,dst=/var/lib \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/05.initramfs.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/var/log \
    --mount=type=tmpfs,dst=/var/lib \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/99.cleanup.sh

RUN bootc container lint

LABEL containers.bootc 1
LABEL ostree.bootable 1

ENV container=oci
STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
