# ffmpeg-static

macOSおよびLinux向けに、ffmpegを静的ビルドするためのMakefileを提供するプロジェクトです。

## 概要

依存ライブラリを静的にリンクしたffmpegバイナリを生成します。外部ライブラリのインストール不要で利用できます。

## 含まれる機能

- H.264エンコード（libx264）
- VP8/VP9エンコード（libvpx）
- Opusオーディオエンコード（libopus）
- SRTプロトコル対応（libsrt）
  - ポート制限を回避するパッチを適用

## 対応環境

- macOS（x86_64 / arm64）
- Linux（x86_64 / aarch64）

## ライブラリバージョン

| ライブラリ | バージョン | リポジトリ |
|------------|------------|------------|
| ffmpeg | n8.0.1 | https://git.ffmpeg.org/ffmpeg.git |
| FFmpeg-WHIP-WHEP | whip-whep/7.1.1（WHIP/WHEP版のみ） | https://github.com/parallelcc/FFmpeg-WHIP-WHEP.git |
| libx264 | stable | https://code.videolan.org/videolan/x264.git |
| libvpx | v1.15.2 | https://chromium.googlesource.com/webm/libvpx |
| libopus | v1.6.1 | https://gitlab.xiph.org/xiph/opus.git |
| libsrt | v1.5.4 | https://github.com/Haivision/srt.git |
| OpenSSL | openssl-3.4.1 | https://github.com/openssl/openssl.git |
| libdatachannel | v0.24.1（WHIP/WHEP版のみ） | https://github.com/paullouisageneau/libdatachannel.git |

## ビルドされるffmpegの機能

### 有効な機能

- GPL ライセンス機能
- libx264（H.264エンコード）
- libvpx（VP8/VP9エンコード）
- libopus（Opusオーディオエンコード）
- libsrt（SRTプロトコル）
- OpenSSL（HTTPS/DTLS/WHIP対応）
- 静的リンク

### 無効化されている機能

- 共有ライブラリ
- デバッグ情報
- libxcb
- SDL2
- X11関連（x11grab入力、x11出力）
- ffprobe
- ドキュメント

## 必要な依存パッケージ

### macOS

```
xcode-select --install
brew install nasm cmake pkg-config
```

### Linux（Debian/Ubuntu）

```
apt-get install git curl build-essential nasm cmake pkg-config
```

## 使用方法

```
make build-ffmpeg
```

ビルドされたバイナリは `bin/ffmpeg` に出力されます。

## Dockerでのビルド（Linux向け）

```
make docker-build-linux-arm64
```

または

```
make docker-build-linux-amd64
```

ビルドされたバイナリは `bin/linux/arm64/ffmpeg` または `bin/linux/amd64/ffmpeg` に出力されます。

## ファイル構成

```
ffmpeg-static/
  Makefile           # ビルドターゲット定義
  download.mk        # ダウンロードターゲット定義（Makefileからinclude）
  srt-port.patch     # SRTのポート制限回避パッチ
  Dockerfile         # Linux向けDockerビルド
  Dockerfile.whip-vp8    # WHIP VP8パッチ適用版Dockerビルド
  Dockerfile.whip-whep   # WHIP/WHEPサポート版Dockerビルド
  download/          # ダウンロードしたソースコード（再利用可能）
    x264/
    libvpx/
    opus/
    openssl/
    srt/
    ffmpeg/
  build-ffmpeg/      # ビルド作業ディレクトリ
  bin/               # 出力バイナリ
    ffmpeg           # macOS用
    linux/
      arm64/ffmpeg   # Linux arm64用
      amd64/ffmpeg   # Linux amd64用
    ffmpeg-whip-whep/  # WHIP/WHEPサポート版
      ffmpeg           # macOS用
      linux/
        arm64/ffmpeg   # Linux arm64用
        amd64/ffmpeg   # Linux amd64用
```

ダウンロードとビルドを分離することで、ビルドをやり直す際にソースの再ダウンロードが不要になり、外部サーバーへの負荷を軽減できます。

Makefileは`download.mk`と`Makefile`に分割されております。ダウンロード関連のターゲットは`download.mk`に定義されており、Dockerビルド時のキャッシュ効率を向上させております。

## コマンド一覧

### ビルド

| コマンド | 説明 |
|----------|------|
| `make build-ffmpeg` | ffmpegをビルド（ダウンロードも自動実行） |
| `make build-ffmpeg-with-whip-vp8` | WHIP VP8パッチを適用してffmpegをビルド（実験的） |
| `make docker-build-linux-arm64` | Docker経由でLinux arm64用をビルド |
| `make docker-build-linux-amd64` | Docker経由でLinux amd64用をビルド |
| `make docker-build-linux-arm64-with-whip-vp8` | Docker経由でWHIP VP8パッチ適用版をビルド（arm64、実験的） |
| `make docker-build-linux-amd64-with-whip-vp8` | Docker経由でWHIP VP8パッチ適用版をビルド（amd64、実験的） |
| `make build-ffmpeg-with-whip-whep` | WHIP/WHEPサポート版ffmpegをビルド（実験的） |
| `make docker-build-linux-arm64-with-whip-whep` | Docker経由でWHIP/WHEPサポート版をビルド（arm64、実験的） |
| `make docker-build-linux-amd64-with-whip-whep` | Docker経由でWHIP/WHEPサポート版をビルド（amd64、実験的） |

### ダウンロード（download.mkで定義）

| コマンド | 説明 |
|----------|------|
| `make download-all` | 全ソースをダウンロード |
| `make download-x264` | x264のみダウンロード |
| `make download-vpx` | libvpxのみダウンロード |
| `make download-opus` | Opusのみダウンロード |
| `make download-openssl` | OpenSSLのみダウンロード |
| `make download-srt` | SRTのみダウンロード |
| `make download-ffmpeg` | ffmpegのみダウンロード |

### クリーン

| コマンド | 説明 |
|----------|------|
| `make clean` | ビルド成果物とダウンロードを全て削除 |
| `make clean-build` | ビルド成果物のみ削除（ダウンロードは保持） |
| `make clean-download` | ダウンロードしたソースを削除 |

## ライセンスに関する注意

本プロジェクトはビルドスクリプトのみを提供しております。ビルド時にダウンロードされる各ライブラリ（ffmpeg、libx264、libvpx、libopus、libsrt、OpenSSL）のライセンスは、ビルドを実行するユーザーに適用されます。生成されたバイナリの利用にあたっては、各ライブラリのライセンス条項をご確認ください。

### srt-port.patch について

本プロジェクトに含まれる `srt-port.patch` は、SRTライブラリ（MPL 2.0）のソースコードを修正するパッチファイルです。このファイルはMPL 2.0ライセンスの影響下にあります。

### whip-vp8.patch について（実験的）

本プロジェクトに含まれる `whip-vp8.patch` は、ffmpeg（LGPL 2.1）のWHIPマルチプレクサにVP8コーデックサポートを追加する実験的なパッチファイルです。このファイルはLGPL 2.1ライセンスの影響下にあります。

このパッチは実験的な機能であり、ffmpeg公式にはマージされておりません。使用は自己責任でお願いいたします。

パッチを適用したビルドを行うには以下のコマンドを使用してください:

```
make build-ffmpeg-with-whip-vp8
```

VP8でのWHIP配信例:

```
ffmpeg -i input.mp4 -c:v libvpx -b:v 1M -c:a libopus -ar 48000 -ac 2 -f whip "https://example.com/whip/endpoint"
```

### ffmpeg-whip-whep について（実験的）

[FFmpeg-WHIP-WHEP](https://github.com/parallelcc/FFmpeg-WHIP-WHEP)をベースにしたWHIP/WHEPサポート版ffmpegをビルドできます。この版はWHIPによるWebRTC配信に加え、WHEPによるWebRTC受信にも対応しております。

本機能は実験的であり、使用は自己責任でお願いいたします。

ビルドコマンド:

```
make build-ffmpeg-with-whip-whep
```

ビルドされたバイナリは `bin/ffmpeg-whip-whep/ffmpeg` に出力されます。

WHIP配信例:

```
ffmpeg -i input.mp4 -c:v libx264 -c:a libopus -f whip "https://example.com/whip/endpoint"
```

WHEP受信例:

```
ffmpeg -i "whep://example.com/whep/endpoint" -c:v copy -c:a copy output.mp4
```
