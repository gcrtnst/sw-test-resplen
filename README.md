# sw-test-resplen
sw-test-resplen は、Stormworks の HTTP 機能で受信できるレスポンスの最大データ長を検証するためのツールです。

## 検証結果
- 約 633 KiB 未満のレスポンスは問題なく受信できます。
- 約 633 KiB を超えるレスポンスは受信が間に合わずタイムアウトします。
  - `httpReply` の `reply` 引数に `"timeout"` が渡されます。
  - タイムアウトは5秒のようです。
- タイムアウト有無の閾値は検証する度にランダムに変わります。
  - おおよそ 631 ~ 635 KiB の範囲でランダムとなります。
  - この閾値はマシンの性能差などによって変わるかもしれません。

前提条件
- Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz (x64)
- GeForce GTX 1050/PCIe/SSE2 4.6.0 NVIDIA 457.51
- 8192MB RAM
- Windows 10 Home 10.0 64bit
- go version go1.20.3 windows/amd64
- Stormworks 64-bit v1.7.2
- シングルプレイ
- Search and Destroy DLC 有効
- Industrial Frontier DLC 有効
- アドオンの HTTP 機能で検証
- 検証用アドオン以外のすべてのアドオンは無効
- 新規作成直後のワールドで検証
- O'Neill Airbase のベッド付近で検証

## 検証ツールの使い方
本リポジトリには、検証で使用するアドオンと HTTP サーバーのソースコードが含まれます。

### 検証用アドオン
検証用アドオンは、HTTP サーバーに対して繰り返し HTTP リクエストを行い、最大データ長を測定します。

検証用アドオンを Stormworks 上で有効化するには、下記手順に従います。
1. 本リポジトリの `addon/test_resplen/` フォルダを、`%APPDATA%\Stormworks\data\missions\` にコピーします。
1. Stormworks を起動して、"HTTP Response Length Test" アドオンを有効化したワールドを新規作成します。\
   New Game > Enabled Addons > Saved > HTTP Response Length Test

検証用アドオンは下記カスタムコマンドを提供します。
```
?test port [start [limit [step]]]
```
- `port`：HTTP サーバーのポート番号
  - 指定必須
- `start`：データ長の初期値（byte）
  - デフォルト：`0`
- `limit`：データ長の終了値（byte）
  - デフォルト：`1073741824`（1 GiB）
- `step`：データ長の増加値（byte）
  - デフォルト：`1`

`?test` コマンドは下記の通り動作します。
1. データ長を `start` 引数で指定された初期値に設定します。
2. 設定された長さのデータを HTTP サーバーに対して要求します。
3. HTTP サーバーからデータを受信すると、データ長が要求と一致しているかどうか確認します。\
   一致していない場合、エラーを報告して動作を終了します。
4. データ長を `step` 引数で指定された増加値だけ増加させます。
5. データ長が `limit` 引数で指定された終了値を超えている場合、動作を終了します。\
   そうでない場合は、2. に戻ります。

### 検証用 HTTP サーバー
検証用 HTTP サーバーは、アドオンの HTTP リクエストに応答します。

検証用 HTTP サーバーは、下記の手順でビルドできます。
1. [The Go Programming Language](https://go.dev/) をインストールします。
1. 本リポジトリの `server/` フォルダをカレントディレクトリとして、次のコマンドを実行します。\
   `go build -o sw-test-resplen.exe`

検証用 HTTP サーバーはコンソールアプリケーションであり、コマンドの書式は以下の通りです。
```
sw-test-resplen.exe [-port PORT]
```
- `-port`：HTTP サーバーのポート番号
  - 未指定の場合、空きポートを自動的に割り当てます。
