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

# Copy build files
COPY Makefile .
COPY srt-port.patch .

# Build OpenSSL
RUN make build-openssl-3-static

# Build x264
RUN make build-x264

# Build SRT
RUN make build-srt

# Build ffmpeg
RUN make build-ffmpeg-only

# Copy binary to output directory
RUN make copy-ffmpeg
