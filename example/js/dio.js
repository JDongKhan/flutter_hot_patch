// 三方库 JS（宿主维护）：dio
//
// 文件名即 Dart 包名（`js/dio.js` ↔ `package:dio`），构建时由
// `ui_third_party_js` 原样拷贝到 `patch/packages/dio.js`；业务产物按
// `import { Dio } from '../packages/dio.js'` 取用。
//
// # 为什么这里能做「同名类」而不是工具类
//
// dio 的 API 面（`Dio()` / `dio.get(path, queryParameters: …)` / `res.data` /
// `res.statusCode`）是**可构造 + 可读字段**的形态，翻译层本来就能一对一映射，
// 不需要任何特殊处理。唯一要换的是「谁真正发请求」：JS 侧没有 XHR 适配器，
// 这一层统一交给宿主——本模块内部只调一个宿主通道 `dioRequest`，由宿主用
// **真实 dio** 发请求（见 `example/lib/base/dio_bridge.dart`）。
//
// 因此在 Dart 源码里写法与原生完全一致：
//
//   final Dio _dio = Dio();
//   final res = await _dio.get(url, queryParameters: {'page': 2});
//   final data = res.data;
//
// 原生侧 _dio 是真正的 dio；JS 侧 _dio 是本文件的同名类，`await` 的是一段
// Promise，落到宿主 dio。两种路径的产物形态、字段名、异常类型全部同名。
//
// # 约定（Dart 全局唯一调用约定，见 js_translator 的 `_methodCallJs`）
//
// 具名实参合并成尾参对象 `o`；位置实参按原名在前。故 `get(path, o)` 里
// `o.queryParameters` / `o.options` / `o.data` 就是 Dart 的具名实参。
// 本文件只读这些键，不依赖任何「运行时按名字猜类型」的启发式。

/// 宿主通道名：与宿主 `@HostInjected('dioRequest')` 一一对应。
const HOST_CHANNEL = 'dioRequest';

/// 把 Dart 侧的值（`Map` 字面量会被翻译成 JS `Map`）转成可 JSON 的普通对象。
///
/// `_app_host_.invoke` 的载荷走 `JSON.stringify`，而 `JSON.stringify(new Map(…))`
/// 得到 `{}`——不在这里摊平就会**静默丢参数**。故所有跨桥的值统一过一遍：
/// `Map` → 普通对象、数组逐项、普通对象逐键，其余原样（含 null）。
function plain(v) {
  if (v === null || v === undefined) {
    return null;
  }
  if (typeof Map !== 'undefined' && v instanceof Map) {
    var o = {};
    v.forEach(function (value, key) {
      o[String(key)] = plain(value);
    });
    return o;
  }
  if (Array.isArray(v)) {
    return v.map(plain);
  }
  if (typeof v === 'object') {
    var r = {};
    Object.keys(v).forEach(function (k) {
      r[k] = plain(v[k]);
    });
    return r;
  }
  return v;
}

/// 把 query 参数拼进 URL（仅用于 `requestOptions.uri` 的可读展示与宿主旁证）。
function joinQuery(url, query) {
  if (query === null || query === undefined) {
    return url;
  }
  var pairs = [];
  var keys = Object.keys(query);
  for (var i = 0; i < keys.length; i++) {
    var k = keys[i];
    var v = query[k];
    if (v === null || v === undefined) {
      continue;
    }
    pairs.push(encodeURIComponent(k) + '=' + encodeURIComponent(String(v)));
  }
  return pairs.length === 0 ? url : url + (url.indexOf('?') >= 0 ? '&' : '?') + pairs.join('&');
}

/// 与 dio 的 `BaseOptions` 同名：`baseUrl` 参与拼路径，其余字段原样留存。
export class BaseOptions {
  constructor(args) {
    var a = args || {};
    this.baseUrl = a.baseUrl === undefined ? null : a.baseUrl;
    this.headers = a.headers === undefined ? null : plain(a.headers);
    this.connectTimeout = a.connectTimeout === undefined ? null : a.connectTimeout;
    this.receiveTimeout = a.receiveTimeout === undefined ? null : a.receiveTimeout;
    this.responseType = a.responseType === undefined ? null : a.responseType;
    this.contentType = a.contentType === undefined ? null : a.contentType;
    this.validateStatus = a.validateStatus === undefined ? null : a.validateStatus;
  }
}

/// 与 dio 的 `Options` 同名：单次请求的可选覆盖项。
export class Options {
  constructor(args) {
    var a = args || {};
    this.method = a.method === undefined ? null : a.method;
    this.headers = a.headers === undefined ? null : plain(a.headers);
    this.responseType = a.responseType === undefined ? null : a.responseType;
    this.contentType = a.contentType === undefined ? null : a.contentType;
    this.extra = a.extra === undefined ? null : plain(a.extra);
    this.followRedirects = a.followRedirects === undefined ? null : a.followRedirects;
    this.validateStatus = a.validateStatus === undefined ? null : a.validateStatus;
  }
}

/// 与 dio 的 `RequestOptions` 同名：`res.requestOptions.uri` 可读。
export class RequestOptions {
  constructor(args) {
    var a = args || {};
    this.path = a.path === undefined ? '' : a.path;
    this.method = a.method === undefined ? 'GET' : a.method;
    this.uri = a.uri === undefined ? '' : a.uri;
    this.headers = a.headers === undefined ? null : plain(a.headers);
    this.queryParameters = a.queryParameters === undefined ? null : plain(a.queryParameters);
    this.data = a.data === undefined ? null : plain(a.data);
  }

  toString() {
    return 'RequestOptions{method: ' + this.method + ', uri: ' + this.uri + '}';
  }
}

/// 与 dio 的 `Response<T>` 同名：字段与 Dart 一致（`data` / `statusCode` /
/// `statusMessage` / `headers` / `requestOptions`），Dart 侧 `res.xxx` 原样可用。
export class Response {
  constructor(args) {
    var a = args || {};
    this.data = a.data === undefined ? null : a.data;
    this.statusCode = a.statusCode === undefined ? null : a.statusCode;
    this.statusMessage = a.statusMessage === undefined ? null : a.statusMessage;
    this.headers = a.headers === undefined ? null : a.headers;
    this.requestOptions = a.requestOptions === undefined ? null : a.requestOptions;
    this.extra = a.extra === undefined ? null : a.extra;
  }

  /// 与 dio 同义：2xx 视为成功。
  get isSuccessful() {
    return this.statusCode !== null && this.statusCode >= 200 && this.statusCode < 300;
  }

  toString() {
    return 'Response{statusCode: ' + this.statusCode + ', data: ' + this.data + '}';
  }
}

/// 与 dio 的 `DioExceptionType` 同名（Dart 是 enum，这里用静态常量表）：
/// `DioExceptionType.badResponse` 这类引用形态在 JS 一侧同样成立。
export class DioExceptionType {
  static connectionTimeout = 'connectionTimeout';
  static sendTimeout = 'sendTimeout';
  static receiveTimeout = 'receiveTimeout';
  static badCertificate = 'badCertificate';
  static badResponse = 'badResponse';
  static cancel = 'cancel';
  static connectionError = 'connectionError';
  static unknown = 'unknown';
}

/// 与 dio 的 `DioException` 同名：宿主抛错被 `_app_host_.invoke` reject 后，
/// 这里包成同名异常，Dart 侧 `catch (e) { … '$e' … }` 拿到的是可读错误。
export class DioException {
  constructor(args) {
    var a = args || {};
    this.type = a.type === undefined ? DioExceptionType.unknown : a.type;
    this.message = a.message === undefined ? null : a.message;
    this.error = a.error === undefined ? null : a.error;
    this.response = a.response === undefined ? null : a.response;
    this.requestOptions = a.requestOptions === undefined ? null : a.requestOptions;
  }

  toString() {
    return 'DioException [' + this.type + ']: ' + this.message;
  }
}

/// 与 dio 的 `Dio` 同名：构造 + 六个动词 + `request`。
///
/// 所有请求最终都走 `request(path, o)` → `_app_host_.invoke('dioRequest', [spec])`，
/// 宿主用真实 dio 执行并回填 JSON；返回值再包成 [Response]，异常包成
/// [DioException]。这样 Dart 侧的 `await` / `catch` 语义与原生完全一致。
export class Dio {
  constructor(args) {
    var a = args || {};
    this.options = a.options || new BaseOptions({});
  }

  get(path, o) {
    return this.request(path, Object.assign({}, o || {}, { method: 'GET' }));
  }

  post(path, o) {
    return this.request(path, Object.assign({}, o || {}, { method: 'POST' }));
  }

  put(path, o) {
    return this.request(path, Object.assign({}, o || {}, { method: 'PUT' }));
  }

  patch(path, o) {
    return this.request(path, Object.assign({}, o || {}, { method: 'PATCH' }));
  }

  delete(path, o) {
    return this.request(path, Object.assign({}, o || {}, { method: 'DELETE' }));
  }

  head(path, o) {
    return this.request(path, Object.assign({}, o || {}, { method: 'HEAD' }));
  }

  request(path, o) {
    var cfg = o || {};
    var opt = cfg.options || null;
    var method = (opt && opt.method) || cfg.method || 'GET';
    var baseUrl = (this.options && this.options.baseUrl) || '';
    var url = String(path === null || path === undefined ? '' : path);
    // 相对路径拼 baseUrl（与 dio 的 `_transformUrl` 同义）；绝对 URL 直接用。
    if (baseUrl && !/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(url) &&
        !url.startsWith('//')) {
      url = baseUrl.replace(/\/+$/, '') + '/' + url.replace(/^\/+/, '');
    }
    var query = cfg.queryParameters === undefined || cfg.queryParameters === null
      ? null : plain(cfg.queryParameters);
    var headers = Object.assign({},
        ((this.options && this.options.headers) || {}), (opt && opt.headers) || {});
    var body = cfg.data === undefined ? null : plain(cfg.data);
    var requestOptions = new RequestOptions({
      path: String(path === null || path === undefined ? '' : path),
      method: method,
      uri: joinQuery(url, query),
      headers: headers,
      queryParameters: query,
      data: body,
    });
    var spec = {
      method: method,
      url: url,
      query: query,
      headers: plain(headers),
      body: body,
    };
    return _app_host_.invoke(HOST_CHANNEL, [spec]).then(function (raw) {
      // 宿主回填的是 JSON：直接包成同名 Response（字段名与 Dart 一致）。
      var r = raw || {};
      return new Response({
        data: r.data === undefined ? null : r.data,
        statusCode: r.statusCode === undefined ? null : r.statusCode,
        statusMessage: r.statusMessage === undefined ? null : r.statusMessage,
        headers: r.headers === undefined ? null : r.headers,
        requestOptions: requestOptions,
      });
    }, function (err) {
      // 宿主 reject → 转成同名 DioException（`catch (e)` 里 `$e` 可读）。
      throw new DioException({
        type: DioExceptionType.unknown,
        message: String(err),
        error: err,
        requestOptions: requestOptions,
      });
    });
  }
}
