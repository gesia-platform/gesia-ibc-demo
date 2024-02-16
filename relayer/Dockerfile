FROM ubuntu:latest

ARG CHAINID_ONE
ARG CHAINID_TWO
ARG PATH_NAME

ENV CHAINID_ONE=${CHAINID_ONE}
ENV CHAINID_TWO=${CHAINID_TWO}
ENV PATH_NAME=${PATH_NAME}

WORKDIR /root

ADD ./relayer /relayer

ADD ./configs /configs

ADD ./scripts/run.sh /run.sh
ADD ./scripts/util.sh /util.sh

ENTRYPOINT ["/run.sh"]