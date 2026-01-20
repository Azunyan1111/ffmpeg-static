# ffmpeg-static

macOSおよびLinux向けに、ffmpegを静的ビルドするためのMakefileを提供するプロジェクトです。

## 概要

依存ライブラリを静的にリンクしたffmpegバイナリを生成します。外部ライブラリのインストール不要で利用できます。

## 含まれる機能

- H.264エンコード（libx264）
- SRTプロトコル対応（libsrt）
  - ポート制限を回避するパッチを適用

## 対応環境

- macOS（x86_64 / arm64）
- Linux（x86_64 / aarch64）

## ライブラリバージョン

| ライブラリ | バージョン |
|------------|------------|
| ffmpeg | n8.0.1 |
| libx264 | stable |
| libsrt | v1.5.4 |
| OpenSSL | 3.4.1 |

## ビルドされるffmpegの機能

### 有効な機能

- GPL ライセンス機能
- libx264（H.264エンコード）
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

## ディレクトリ構成

```
ffmpeg-static/
  download/          # ダウンロードしたソースコード（再利用可能）
    x264/
    srt/
    ffmpeg/
    openssl-3.4.1/
  build-ffmpeg/      # ビルド作業ディレクトリ
  bin/               # 出力バイナリ
    ffmpeg           # macOS用
    linux/
      arm64/ffmpeg   # Linux arm64用
      amd64/ffmpeg   # Linux amd64用
```

ダウンロードとビルドを分離することで、ビルドをやり直す際にソースの再ダウンロードが不要になり、外部サーバーへの負荷を軽減できます。

## コマンド一覧

### ビルド

| コマンド | 説明 |
|----------|------|
| `make build-ffmpeg` | ffmpegをビルド（ダウンロードも自動実行） |
| `make docker-build-linux-arm64` | Docker経由でLinux arm64用をビルド |
| `make docker-build-linux-amd64` | Docker経由でLinux amd64用をビルド |

### ダウンロード

| コマンド | 説明 |
|----------|------|
| `make download-all` | 全ソースをダウンロード |
| `make download-x264` | x264のみダウンロード |
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

本プロジェクトはビルドスクリプトのみを提供しております。ビルド時にダウンロードされる各ライブラリ（ffmpeg、libx264、libsrt、OpenSSL）のライセンスは、ビルドを実行するユーザーに適用されます。生成されたバイナリの利用にあたっては、各ライブラリのライセンス条項をご確認ください。

### srt-port.patch について

本プロジェクトに含まれる `srt-port.patch` は、SRTライブラリ（MPL 2.0）のソースコードを修正するパッチファイルです。このファイルはMPL 2.0ライセンスの影響下にあります。
