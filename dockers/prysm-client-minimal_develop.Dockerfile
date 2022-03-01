FROM ubuntu:20.04 as builder

ENV TZ=America
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        software-properties-common \
        curl \
        git \
        build-essential \
        python3-dev \
        python3-pip \
        jq \
        vim

RUN add-apt-repository ppa:longsleep/golang-backports && \
    apt-get install -y --no-install-recommends \
	golang && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /git

# some dependencies
RUN go install github.com/bazelbuild/bazelisk@latest && \
    go get -d github.com/ethereum/go-ethereum && \
    cd /root/go/pkg/mod/github.com/ethereum/go-ethereum* && \
    pip3 install --no-cache-dir web3 ruamel.yaml

RUN git clone https://github.com/prysmaticlabs/prysm && \
    cd prysm && \
    git checkout develop

RUN cd prysm && /root/go/bin/bazelisk build //beacon-chain:beacon-chain --config=minimal
RUN cd prysm && /root/go/bin/bazelisk build //validator:validator --config=minimal

from debian:latest

COPY --from=builder /git/prysm/bazel-bin/cmd/beacon-chain/beacon-chain_/beacon-chain /usr/local/bin/beacon-chain
COPY --from=builder /git/prysm/bazel-bin/cmd/validator/validator_/validator /usr/local/bin/validator