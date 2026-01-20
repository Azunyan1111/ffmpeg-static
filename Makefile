# ffmpeg static build
# Required: h264 (libx264), vpx (libvpx), opus (libopus) and srt support
#
# Note: Download targets are defined in download.mk
#       See download.mk for: download-all, download-x264, download-vpx,
#       download-openssl, download-srt, download-opus, download-ffmpeg

include download.mk

OPENSSL_SRC     := openssl-$(OPENSSL_VERSION)
OPENSSL_PREFIX  := $(CURDIR)/build-ffmpeg/$(OPENSSL_SRC)-static

# pkg-config path for local builds
PKG_CONFIG_PATH_LOCAL := $(CURDIR)/build-ffmpeg/srt/install/lib/pkgconfig:$(CURDIR)/build-ffmpeg/ffmpeg_install/lib/pkgconfig:$(OPENSSL_PREFIX)/lib/pkgconfig

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
	chmod -R u+rwx build-ffmpeg 2>/dev/null || true
	rm -rf build-ffmpeg
	rm -rf bin

.PHONY: copy-ffmpeg
copy-ffmpeg:
	@if [ ! -f bin/ffmpeg ]; then \
		mkdir -p bin && \
		cp ./build-ffmpeg/bin/ffmpeg bin/ffmpeg; \
	else \
		echo "bin/ffmpeg already exists, skipping copy"; \
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

.PHONY: build-vpx
build-vpx: download-vpx
	@if [ -f build-ffmpeg/ffmpeg_install/lib/libvpx.a ]; then \
		echo "libvpx already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		cp -r download/libvpx build-ffmpeg/libvpx && \
		cd build-ffmpeg/libvpx && \
			./configure --prefix=../ffmpeg_install --disable-shared --enable-static --disable-examples --disable-tools --disable-docs --disable-unit-tests && \
			make -j$(NPROC) && \
			make install; \
	fi

.PHONY: build-openssl
build-openssl: download-openssl
	@if [ -f $(OPENSSL_PREFIX)/lib/libssl.a ]; then \
		echo "OpenSSL already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		cp -r download/openssl build-ffmpeg/$(OPENSSL_SRC) && \
		cd build-ffmpeg/$(OPENSSL_SRC) && \
			./Configure $(OPENSSL_TARGET) no-shared no-dso no-tests --prefix=$(OPENSSL_PREFIX) --libdir=lib && \
			make -j$(NPROC) && \
			make install_sw; \
	fi

.PHONY: build-opus
build-opus: download-opus
	@if [ -f build-ffmpeg/ffmpeg_install/lib/libopus.a ]; then \
		echo "opus already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		cp -r download/opus build-ffmpeg/opus && \
		cd build-ffmpeg/opus && \
			./autogen.sh && \
			./configure --prefix=$(shell pwd)/build-ffmpeg/ffmpeg_install --enable-static --disable-shared --disable-doc --disable-extra-programs && \
			make -j$(NPROC) && \
			make install; \
	fi

.PHONY: build-srt
build-srt: build-openssl download-srt
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

.PHONY: _build-ffmpeg
_build-ffmpeg: download-ffmpeg
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
				--extra-cflags="-I../srt/install/include -I../$(OPENSSL_SRC)-static/include -I../ffmpeg_install/include" \
				--extra-ldflags="-L../srt/install/lib -L../$(OPENSSL_SRC)-static/lib -L../ffmpeg_install/lib -lssl -lcrypto" \
				--extra-libs="-lpthread -lm" \
				--enable-gpl \
				--bindir=../bin \
				--enable-libx264 \
				--enable-libvpx \
				--enable-libopus \
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
build-ffmpeg: build-x264 build-vpx build-opus build-srt _build-ffmpeg copy-ffmpeg
	./build-ffmpeg/bin/ffmpeg -version

# =============================================================================
# Experimental: WHIP VP8 patch
# =============================================================================

.PHONY: _build-ffmpeg-with-whip-vp8
_build-ffmpeg-with-whip-vp8: download-ffmpeg
	@if [ -f build-ffmpeg/bin/ffmpeg ]; then \
		echo "ffmpeg already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		cp -r download/ffmpeg build-ffmpeg/ffmpeg && \
		cd build-ffmpeg/ffmpeg && patch -p1 < ../../whip-vp8.patch && \
		export PKG_CONFIG_PATH="$(PKG_CONFIG_PATH_LOCAL)" && \
		./configure \
			--prefix=../ffmpeg_install \
			--pkg-config-flags="--static" \
			--extra-cflags="-I../srt/install/include -I../$(OPENSSL_SRC)-static/include -I../ffmpeg_install/include" \
			--extra-ldflags="-L../srt/install/lib -L../$(OPENSSL_SRC)-static/lib -L../ffmpeg_install/lib -lssl -lcrypto" \
			--extra-libs="-lpthread -lm" \
			--enable-gpl \
			--bindir=../bin \
			--enable-libx264 \
			--enable-libvpx \
			--enable-libopus \
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

.PHONY: build-ffmpeg-with-whip-vp8
build-ffmpeg-with-whip-vp8: build-x264 build-vpx build-opus build-srt _build-ffmpeg-with-whip-vp8 copy-ffmpeg
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
