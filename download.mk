# Download targets for ffmpeg static build

OPENSSL_VERSION := 3.4.1
LIBDATACHANNEL_VERSION := v0.24.1
FFMPEG_WHIP_WHEP_VERSION := whip-whep/7.1.1

.PHONY: download-all
download-all: download-x264 download-vpx download-openssl download-srt download-opus download-ffmpeg download-libdatachannel

.PHONY: download-x264
download-x264:
	@if [ -d download/x264 ]; then \
		echo "x264 already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://code.videolan.org/videolan/x264.git --branch stable download/x264; \
	fi

.PHONY: download-vpx
download-vpx:
	@if [ -d download/libvpx ]; then \
		echo "libvpx already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://chromium.googlesource.com/webm/libvpx --branch v1.15.2 download/libvpx --depth 1; \
	fi

.PHONY: download-openssl
download-openssl:
	@if [ -d download/openssl ]; then \
		echo "OpenSSL already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://github.com/openssl/openssl.git --branch openssl-$(OPENSSL_VERSION) download/openssl --depth 1; \
	fi

.PHONY: download-srt
download-srt:
	@if [ -d download/srt ]; then \
		echo "SRT already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://github.com/Haivision/srt.git --branch v1.5.4 download/srt; \
	fi

.PHONY: download-opus
download-opus:
	@if [ -d download/opus ]; then \
		echo "opus already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://gitlab.xiph.org/xiph/opus.git --branch v1.6.1 download/opus --depth 1; \
	fi

.PHONY: download-ffmpeg
download-ffmpeg:
	@if [ -d download/ffmpeg ]; then \
		echo "ffmpeg already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://git.ffmpeg.org/ffmpeg.git --branch n8.0.1 download/ffmpeg --depth 1; \
	fi

.PHONY: download-libdatachannel
download-libdatachannel:
	@if [ -d download/libdatachannel ]; then \
		echo "libdatachannel already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://github.com/paullouisageneau/libdatachannel.git --branch $(LIBDATACHANNEL_VERSION) download/libdatachannel --recursive --depth 1; \
	fi

.PHONY: download-ffmpeg-whip-whep
download-ffmpeg-whip-whep:
	@if [ -d download/ffmpeg-whip-whep ]; then \
		echo "ffmpeg-whip-whep already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://github.com/parallelcc/FFmpeg-WHIP-WHEP.git --branch $(FFMPEG_WHIP_WHEP_VERSION) download/ffmpeg-whip-whep --depth 1; \
	fi

.PHONY: clean-download
clean-download:
	rm -rf download
