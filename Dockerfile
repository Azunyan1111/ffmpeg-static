FROM ubuntu:24.04

WORKDIR /build

# Base packages
RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y curl
RUN apt-get install -y build-essential
RUN apt-get install -y nasm
RUN apt-get install -y cmake
RUN apt-get install -y pkg-config
RUN apt-get install -y autoconf
RUN apt-get install -y automake
RUN apt-get install -y libtool

# Copy build files
COPY Makefile .
COPY srt-port.patch .

# Download sources
RUN make download-openssl
RUN make download-x264
RUN make download-srt
RUN make download-opus
RUN make download-ffmpeg

# Build OpenSSL
RUN make build-openssl

# Build x264
RUN make build-x264

# Build SRT
RUN make build-srt

# Build Opus
RUN make build-opus

# Build ffmpeg
RUN make _build-ffmpeg

# Copy binary to output directory
RUN make copy-ffmpeg
