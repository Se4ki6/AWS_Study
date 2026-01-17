#!/bin/bash

# ライブラリを一時フォルダにインストールしてzip化するスクリプト
export PKG_DIR="python_payload"
rm -rf $PKG_DIR && mkdir $PKG_DIR
rm -f lambda_function_payload.zip

# ライブラリのインストール
pip install -r lambda/requirements.txt -t $PKG_DIR

# ソースコードのコピー
cp lambda/handler.py $PKG_DIR

# zip化
cd $PKG_DIR
zip -r ../lambda_function_payload.zip .
cd ..

# クリーンアップ
rm -rf $PKG_DIR

echo "Build complete: lambda_function_payload.zip"
