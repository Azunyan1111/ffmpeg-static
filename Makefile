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
	rm -rf build-ffmpeg/x264
	rm -rf build-ffmpeg/srt
	rm -rf build-ffmpeg/ffmpeg
	rm -rf build-ffmpeg/ffmpeg_install
	rm -rf build-ffmpeg/bin
	rm -rf $(OPENSSL_SRC)
	rm -rf $(OPENSSL_PREFIX)
	rm -rf bin

.PHONY: clean-download
clean-download:
	rm -rf $(OPENSSL_SRC).tar.gz

.PHONY: copy-ffmpeg
copy-ffmpeg:
	@if [ ! -f bin/ffmpeg ]; then \
		mkdir -p bin && \
		cp ./build-ffmpeg/bin/ffmpeg bin/ffmpeg; \
	else \
		echo "bin/ffmpeg already exists, skipping copy"; \
	fi

.PHONY: build-x264
build-x264:
	@if [ -f build-ffmpeg/ffmpeg_install/lib/libx264.a ]; then \
		echo "x264 already built, skipping"; \
	else \
		mkdir -p build-ffmpeg && \
		git clone https://code.videolan.org/videolan/x264.git --branch stable build-ffmpeg/x264 && \
		cd build-ffmpeg/x264 && \
			./configure --prefix=../ffmpeg_install --enable-static && \
			make -j$(NPROC) && \
			make install; \
	fi

.PHONY: build-openssl-3-static
build-openssl-3-static:
	@if [ -f $(OPENSSL_PREFIX)/lib/libssl.a ]; then \
		echo "OpenSSL already built, skipping"; \
	else \
		curl -L -o $(OPENSSL_SRC).tar.gz https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VERSION)/$(OPENSSL_SRC).tar.gz && \
		rm -rf $(OPENSSL_SRC) $(OPENSSL_PREFIX) && \
		tar -xf $(OPENSSL_SRC).tar.gz && \
		cd $(OPENSSL_SRC) && \
			./Configure $(OPENSSL_TARGET) no-shared no-dso no-tests --prefix=$(OPENSSL_PREFIX) && \
			make -j$(NPROC) && \
			make install_sw; \
	fi

.PHONY: build-srt
build-srt: build-openssl-3-static
	@if [ -f build-ffmpeg/srt/install/lib/libsrt.a ]; then \
		echo "SRT already built, skipping"; \
	else \
		git clone https://github.com/Haivision/srt.git --branch v1.5.4 build-ffmpeg/srt && \
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
build-ffmpeg-only:
	@if [ -f build-ffmpeg/bin/ffmpeg ]; then \
		echo "ffmpeg already built, skipping"; \
	else \
		git clone https://git.ffmpeg.org/ffmpeg.git --branch n8.0.1 build-ffmpeg/ffmpeg --depth 1 && \
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
