/// 本地开发服务地址的**唯一来源**：补丁 zip（patch_config）与 mock 接口
/// （Network / dio / HostHttp）都从这里取。
///
/// 换电脑 / 换网段时只改这一行的 IP（端口与服务端 `tool/patch_server.dart` 一致）。
/// 服务端绑定 `0.0.0.0`，所以本机模拟器可用 `127.0.0.1`，真机用电脑的局域网 IP。
// const String devServerBaseUrl = 'http://10.42.40.18:8765';
const String devServerBaseUrl = 'http://127.0.0.1:8765';
