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
docker build -t ffmpeg-static .
```

ビルド完了後、コンテナからバイナリを取り出します。

```
mkdir -p bin/linux
docker create --name ffmpeg-tmp ffmpeg-static
docker cp ffmpeg-tmp:/build/bin/ffmpeg bin/linux/ffmpeg
docker rm ffmpeg-tmp
```

## その他のコマンド

| コマンド | 説明 |
|----------|------|
| `make clean` | ビルド成果物とダウンロードファイルを全て削除 |
| `make clean-build` | ビルド成果物のみ削除 |
| `make clean-download` | ダウンロードしたアーカイブのみ削除 |

## ライセンスに関する注意

本プロジェクトはビルドスクリプトのみを提供しております。ビルド時にダウンロードされる各ライブラリ（ffmpeg、libx264、libsrt、OpenSSL）のライセンスは、ビルドを実行するユーザーに適用されます。生成されたバイナリの利用にあたっては、各ライブラリのライセンス条項をご確認ください。
