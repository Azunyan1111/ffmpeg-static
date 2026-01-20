# ffmpeg static build
# Required: h264 (libx264) and srt support

OPENSSL_VERSION := 3.4.1
OPENSSL_SRC     := openssl-$(OPENSSL_VERSION)
OPENSSL_PREFIX  := $(shell pwd)/build-ffmpeg/$(OPENSSL_SRC)-static

# pkg-config path for local builds
PKG_CONFIG_PATH_LOCAL := $(shell pwd)/build-ffmpeg/srt/install/lib/pkgconfig:$(shell pwd)/build-ffmpeg/ffmpeg_install/lib/pkgconfig:$(OPENSSL_PREFIX)/lib/pkgconfig

# OS detection
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# CPU core count
ifeq ($(UNAME_S),Darwin)
    NPROC := $(shell sysctl -n hw.ncpu)
else
    NPROC := $(shell nproc)
endif

# OpenSSL target
ifeq ($(UNAME_S),Darwin)
    OPENSSL_TARGET := darwin64-$(UNAME_M)-cc
else
    ifeq ($(UNAME_M),x86_64)
        OPENSSL_TARGET := linux-x86_64
    else ifeq ($(UNAME_M),aarch64)
        OPENSSL_TARGET := linux-aarch64
    else
        OPENSSL_TARGET := linux-generic64
    endif
endif

.PHONY: all
all: build-ffmpeg

.PHONY: clean
clean: clean-build clean-download

.PHONY: clean-build
clean-build:
	rm -rf build-ffmpeg
	rm -rf bin

.PHONY: clean-download
clean-download:
	rm -rf download

.PHONY: copy-ffmpeg
copy-ffmpeg:
	@if [ ! -f bin/ffmpeg ]; then \
		mkdir -p bin && \
		cp ./build-ffmpeg/bin/ffmpeg bin/ffmpeg; \
	else \
		echo "bin/ffmpeg already exists, skipping copy"; \
	fi

# =============================================================================
# Download targets
# =============================================================================

.PHONY: download-all
download-all: download-x264 download-openssl download-srt download-ffmpeg

.PHONY: download-x264
download-x264:
	@if [ -d download/x264 ]; then \
		echo "x264 already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://code.videolan.org/videolan/x264.git --branch stable download/x264; \
	fi

.PHONY: download-openssl
download-openssl:
	@if [ -d download/$(OPENSSL_SRC) ]; then \
		echo "OpenSSL already downloaded, skipping"; \
	else \
		mkdir -p download && \
		curl -L -o download/$(OPENSSL_SRC).tar.gz https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VERSION)/$(OPENSSL_SRC).tar.gz && \
		tar -xf download/$(OPENSSL_SRC).tar.gz -C download; \
	fi

.PHONY: download-srt
download-srt:
	@if [ -d download/srt ]; then \
		echo "SRT already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://github.com/Haivision/srt.git --branch v1.5.4 download/srt; \
	fi

.PHONY: download-ffmpeg
download-ffmpeg:
	@if [ -d download/ffmpeg ]; then \
		echo "ffmpeg already downloaded, skipping"; \
	else \
		mkdir -p download && \
		git clone https://git.ffmpeg.org/ffmpeg.git --branch n8.0.1 download/ffmpeg --depth 1; \
	fi

# =============================================================================
# Build targets
# =============================================================================

.PHONY: build-x264
build-x264: download-x264
	@if [ -f build-ffmpeg/ffmpeg_install/lib/libx264.a ]; then \
		echo "x264 already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		cp -r download/x264 build-ffmpeg/x264 && \
		cd build-ffmpeg/x264 && \
			./configure --prefix=../ffmpeg_install --enable-static && \
			make -j$(NPROC) && \
			make install; \
	fi

.PHONY: build-openssl-3-static
build-openssl-3-static: download-openssl
	@if [ -f $(OPENSSL_PREFIX)/lib/libssl.a ]; then \
		echo "OpenSSL already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		cp -r download/$(OPENSSL_SRC) build-ffmpeg/$(OPENSSL_SRC) && \
		cd build-ffmpeg/$(OPENSSL_SRC) && \
			./Configure $(OPENSSL_TARGET) no-shared no-dso no-tests --prefix=$(OPENSSL_PREFIX) --libdir=lib && \
			make -j$(NPROC) && \
			make install_sw; \
	fi

.PHONY: build-srt
build-srt: build-openssl-3-static download-srt
	@if [ -f build-ffmpeg/srt/install/lib/libsrt.a ]; then \
		echo "SRT already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		cp -r download/srt build-ffmpeg/srt && \
		cd build-ffmpeg/srt && cp ../../srt-port.patch . && git apply srt-port.patch && \
		mkdir -p install ../ffmpeg_install ../bin && \
		mkdir build && \
		cd build && \
			export OPENSSL_ROOT_DIR=$(OPENSSL_PREFIX) && \
			export OPENSSL_LIB_DIR=$(OPENSSL_PREFIX)/lib && \
			export OPENSSL_INCLUDE_DIR=$(OPENSSL_PREFIX)/include && \
			cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
				-DENABLE_SHARED=OFF \
				-DENABLE_STATIC=ON \
				-DSRT_USE_OPENSSL_STATIC_LIBS=ON \
				-DOPENSSL_USE_STATIC_LIBS=TRUE \
				-DUSE_OPENSSL_PC=OFF \
				-DOPENSSL_INCLUDE_DIR=$(OPENSSL_PREFIX)/include \
				-DOPENSSL_CRYPTO_LIBRARY=$(OPENSSL_PREFIX)/lib/libcrypto.a \
				-DOPENSSL_SSL_LIBRARY=$(OPENSSL_PREFIX)/lib/libssl.a \
				-DCMAKE_INSTALL_PREFIX=../install .. && \
			make -j$(NPROC) && \
			make install; \
	fi

.PHONY: build-ffmpeg-only
build-ffmpeg-only: download-ffmpeg
	@if [ -f build-ffmpeg/bin/ffmpeg ]; then \
		echo "ffmpeg already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		cp -r download/ffmpeg build-ffmpeg/ffmpeg && \
		cd build-ffmpeg/ffmpeg && \
			export PKG_CONFIG_PATH="$(PKG_CONFIG_PATH_LOCAL)" && \
			./configure \
				--prefix=../ffmpeg_install \
				--pkg-config-flags="--static" \
				--extra-cflags="-I../srt/install/include -I$(OPENSSL_PREFIX)/include -I../ffmpeg_install/include" \
				--extra-ldflags="-L../srt/install/lib -L$(OPENSSL_PREFIX)/lib -L../ffmpeg_install/lib -lssl -lcrypto" \
				--extra-libs="-lpthread -lm" \
				--enable-gpl \
				--bindir=../bin \
				--enable-libx264 \
				--enable-nonfree \
				--enable-openssl \
				--enable-libsrt \
				--enable-static \
				--disable-shared \
				--disable-debug \
				--disable-libxcb \
				--disable-sdl2 \
				--disable-xlib \
				--disable-indev=x11grab \
				--disable-outdev=x11 \
				--disable-ffprobe \
				--disable-doc && \
			make -j$(NPROC) && \
			make install && \
			../bin/ffmpeg -version; \
	fi

.PHONY: build-ffmpeg
build-ffmpeg: build-x264 build-srt build-ffmpeg-only copy-ffmpeg
	./build-ffmpeg/bin/ffmpeg -version

# =============================================================================
# Docker build targets
# =============================================================================

.PHONY: docker-build-linux-arm64
docker-build-linux-arm64:
	docker build --platform linux/arm64 -t ffmpeg-static-arm64 .
	mkdir -p bin/linux/arm64
	docker create --name ffmpeg-tmp-arm64 ffmpeg-static-arm64
	docker cp ffmpeg-tmp-arm64:/build/bin/ffmpeg bin/linux/arm64/ffmpeg
	docker rm ffmpeg-tmp-arm64

.PHONY: docker-build-linux-amd64
docker-build-linux-amd64:
	docker build --platform linux/amd64 -t ffmpeg-static-amd64 .
	mkdir -p bin/linux/amd64
	docker create --name ffmpeg-tmp-amd64 ffmpeg-static-amd64
	docker cp ffmpeg-tmp-amd64:/build/bin/ffmpeg bin/linux/amd64/ffmpeg
	docker rm ffmpeg-tmp-amd64
