# DeClang

## 概要

DeClang は LLVM フレームワークを利用したコンパイル型アンチチートツールです。

既存のオープンソースプロジェクトである ollvm (https://github.com/obfuscator-llvm/obfuscator) を拡張する形で実装し、現時点では難読化機能のみを公開するに至りました。他のアンチチート機能についても、今後公開する可能性があります。

![難読化](https://user-images.githubusercontent.com/1781263/97404801-02c20780-193a-11eb-9a28-1870375e03fe.png "難読化")

コンパイル型アンチチートツールは、従来のパッカー型アンチチートツールと比べて、様々な利点が存在します。詳しくは下記資料をご覧ください。

https://www.slideshare.net/dena_tech/declang-clang-dena-techcon-2020

## サポートアーキテクチャ

下記のホストアーキテクチャの動作確認をしています。

- x86_64 macOS
- x86_64 Linux
- x86_64 Windows

下記のターゲットアーキテクチャの動作確認をしています。

- arm64 ELF (Android)
- arm64 Mach-O (iPhone)
- x86_64 ELF (Linux)
- x86_64 Mach-O (macOS)

## ビルド方法

```
$ git clone https://github.com/DeNA/DeClang
$ cd DeClang
$ cd script
$ bash build.sh
...
$ bash build_tools.sh
...
$ bash release.sh v1.0.0
...
```
上記コマンドが正常に完了すると、プロジェクトのTopディレクトリにRelease-v1.0.0というディレクトリが生成されます。

## インストール方法

- DECLANG_HOMEを定義します
  ```
  export DECLANG_HOME=/path/to/declang_home/
  ```

- DECLANG_HOMEにReleaseをコピーします。
  - 手動でビルドした場合
    - Release-v1.0.0 を $DECLANG_HOME/.DeClang としてコピーします。
    ```
    mv Release-v1.0.0 $DECLANG_HOME/.DeClang
    ```
  - DeClangのReleasesページからDeClangバイナリをダウンロードした場合
    - 展開後の Release を $DECLANG_HOME/.DeClang としてコピーします
    ```
    mv Release/ $DECLANG_HOME/.DeClang
    ```

- android-ndkの標準コンパイラとしてDeClangを利用したい場合には、次のコマンドを実行します。
  ```
  bash $DECLANG_HOME/.DeClang/script/ndk_setup.sh {/path/to/ndk_root}
  ```
  設定をDeClangから標準のコンパイラに戻したい場合は次のようにします。
  ```
  bash $DECLANG_HOME/.DeClang/script/ndk_unset.sh {/path/to/ndk_root}
  ```

- UnityのWebGLビルドの標準コンパイラとしてDeClangを利用したい場合には、次のコマンドを実行します。
  ```
  bash $DECLANG_HOME/.DeClang/script/webgl_setup.sh {/path/to/unity_webgl_support}
  ```
  設定をDeClangから標準のコンパイラに戻したい場合は次のようにします。
  ```
  bash $DECLANG_HOME/.DeClang/script/webgl_unset.sh {/path/to/unity_webgl_support}
  ```

## 使い方

- $DECLANG_HOME/.DeClang配下のconfig.pre.jsonを編集します。
  ```
  vi $DECLANG_HOME/.DeClang/config.pre.json
  ```
  | キー | 説明 | 値 |
  | -- |--| ------------- |
  | build_seed | 難読化で利用されるシード | string |
  | overall_obfuscation | コード全体に適用される簡易難読化の強さ | integer 0-100 (default 0) |
  | flatten[name] | flatten難読化を適用する関数名 | regex string |
  | flatten[seed] | flatten難読化内部で使用するシード値 | 16-digit hexadecimal string |
  | flatten[split_level] | flatten難読化の際にBasic Blockを分割するレベル | integer (default 1)|
  | enable_obfuscation | flatten難読化を有効にするか否か | integer 0-1 (default 1) |

- config.pre.jsonからconfig.jsonを生成します。
  ```
  $DECLANG_HOME/.DeClang/gen_config.sh -path $DECLANG_HOME/.DeClang/ -seed {your seed}
  ```
  seedは任意の文字列で、ビルドごとに変えるのが好ましいです。
- 以上で準備が整ったので、ndk-build等を通して、任意プログラムをコンパイルすればconfig.pre.jsonの設定にしたがって難読化が適用されます。
  - (ご注意) ndk-build等を実行する際は、環境変数DECLANG_HOMEが設定されていることを確認してください。

## 注意点

Unity上でビルドするときは、$DECLANG_HOMEは効かないので、デフォルトの~/.DeClang/が使われてしまいます。なのでコマンドラインからDECLANG_HOMEを設定した状態でビルドしてください。

Gradleを用いてAndroidライブラリをビルドするときは、build.gradle内に記載されている`ndkVersion`に応じて、`ndk_setup.sh`を実行してください。
また、CMakefile.txt内で`set(CMAKE_CXX_FLAGS_RELEASE "-O2") ` を記載し、最適化を有効にしてください。
DeClangは最適化を有効にしないと、難読化を行うLLVM Passに処理が渡らず、難読化が行われません。
