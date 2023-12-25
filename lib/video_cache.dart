import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'dart:async';
import 'package:video_cache_plugin/video_cache_utils.dart';

/// 视频缓存，仅支持 mp4 格式
class VideoCache {
  /// 开启代理服务器
  ///
  /// - port 代理服务器的端口号
  static Future<void> setupProxy({int port = 8099}) async {
    await VideoCacheServer().setupProxy(port: port);
  }

  /// 停止代理服务器
  static Future<void> proxyStop() async {
    await VideoCacheServer().proxyStop();
  }

  /// 生成统一的代理链接
  ///
  /// - originalURL 原始链接
  static String? proxyURL(String originalURL) {
    if (originalURL.isEmpty) {
      return null;
    }

    return VideoCacheServer().createProxyURL(originalURL);
  }
}

/// 视频缓存服务
class VideoCacheServer {
  static final _instance = VideoCacheServer._();

  /// web server
  HttpServer? _server;

  static const String host = 'localhost';
  static const String path = 'request';

  VideoCacheServer._() {
    _init();
  }

  factory VideoCacheServer() => _instance;

  void _init() async {
    // 缓存初始化
    await VideoCacheManager().init();
  }

  /// 设置代理服务
  Future<void> setupProxy({int port = 8099}) async {
    final handler = const Pipeline().addHandler(_echoRequest);
    _server = await shelf_io.serve(handler, host, port);
    // Enable content compression
    _server?.autoCompress = true;
    print('Serving at http://${_server?.address.host}:${_server?.port}');
  }

  /// 停止代理服务
  Future<void> proxyStop() async {
    await _server?.close();
    _server = null;
  }

  /// 创建代理请求链接
  String createProxyURL(String url) {
    return 'http://$host:${_server?.port ?? 80}/$path?url=$url';
  }

  /// 提取原始链接
  String getOriginalURL(String url) {
    if (url.contains('request?url=')) {
      return url.replaceAll('request?url=', '');
    }

    return '';
  }

  /// 请求
  Future<Response> _echoRequest(Request request) async {
    final url = Uri.tryParse(getOriginalURL(request.url.toString()));
    print('请求的 Uri: $url');

    final headers = <String, dynamic>{};
    headers.addAll(request.headers);
    headers['host'] = url?.host ?? ''; // 替换代理服务器中的 host 字段

    // print('组装后的 Headers: $headers');

    // 获取数据，以 stream 流的形式返回
    final result =
        await VideoCacheManager().requestData(url!.toString(), headers);

    // print('响应头: ${result.headers}');
    print('状态码: ${result.statusCode} 消息: ${result.statusMessage}');

    if (result.data == null) {
      return Response.notFound(result.data, headers: result.headers.map);
    }

    // 返回响应，shelf_io 必须使用 stream 流的形式返回数据
    return Response(
      result.statusCode ?? 200,
      body: result.data?.stream,
      headers: result.headers.map,
    );
  }
}

/// 视频缓存管理
class VideoCacheManager {
  static final shared = VideoCacheManager._();
  String? _cachePath;
  String get cachePath => _cachePath!;
  Future<String> Function(String)? processingCachekey; // 处理缓存的key

  /// 下载分片
  late final _dio = dio.Dio();

  VideoCacheManager._();

  factory VideoCacheManager() => shared;

  /// 初始化
  Future<void> init() async {
    // 创建缓存文件夹
    await _createCacheDirectoryIfNotExists();
  }

  /// 如果不存在缓存文件夹就创建
  Future<void> _createCacheDirectoryIfNotExists() async {
    // 创建缓存文件夹
    final path = '${(await getTemporaryDirectory()).path}/videoCache/';
    final cacheDir = Directory(path);
    if (!(await cacheDir.exists())) {
      await cacheDir.create(recursive: true);
      print('视频缓存目录不存在，已经重新创建');
    }

    _cachePath = cacheDir.path;
    print('视频缓存文件目录: $_cachePath');
  }

  /// 清除缓存
  Future<void> cleanCache() async {
    final dir = Directory(cachePath);
    if (!dir.existsSync()) {
      return;
    }

    await dir.delete(recursive: true);
    await _createCacheDirectoryIfNotExists();
  }

  /// 判断文件是否存在
  ///
  /// - path 文件完整路径
  Future<bool> fileExists(String path) async => await File(path).exists();

  /// 使用 Stream 的方式读取文件
  ///
  /// - path 文件完整路径
  Stream<Uint8List> readFileStream(String path) async* {
    yield await readFile(path);
  }

  /// 转换成文件流
  Stream<Uint8List> asFileStream(Uint8List data) async* {
    yield data;
  }

  /// 读取文件
  Future<Uint8List> readFile(String path) async {
    return await File(path).readAsBytes();
  }

  /// 获取视频分片数据，先从缓存中获取，如果没有就从网络端获取
  ///
  /// - url 视频链接
  /// - headers 请求头，包含请求视频所需要的信息，例如 Range 信息
  Future<dio.Response<dio.ResponseBody>> requestData(
    String url,
    Map<String, dynamic>? headers,
  ) async {
    // 获取 Range 信息
    final contentRange = (headers?['range'] ?? headers?['Range']) as String?;
    final videoDirName =
        (processingCachekey != null ? await processingCachekey!.call(url) : url)
            .toMD5(); // 当前视频缓存文件的文件夹名称
    final fileName =
        '${videoDirName}_${contentRange ?? 'no_range'}'; // 当前片段的文件名
    final headersFileName = '${fileName}_headers_data'; // 当前响应头文件名
    final videoRoot = '$cachePath$videoDirName/'; // 当前视频缓存文件夹路径
    final cacheFilePath = '$videoRoot$fileName'; // 当前片段的缓存文件路径
    final cacheHeadersPath = '$videoRoot$headersFileName'; // 当前片段的响应头信息缓存路径

    // 检测当前视频缓存路径是否存在
    final videoRootDir = Directory(videoRoot);
    if (!(await videoRootDir.exists())) {
      await videoRootDir.create();
    }

    if (await fileExists(cacheFilePath) && await fileExists(cacheHeadersPath)) {
      // 读取缓存
      return await getCacheResult(cacheFilePath, cacheHeadersPath);
    }

    if (Platform.isIOS) {
      // iOS 从服务器获取数据
      final result = await _dio.get<dio.ResponseBody>(
        url,
        options: dio.Options(
          headers: headers,
          responseType: dio.ResponseType.stream,
        ),
      );

      final dataResult = result;
      dataResult.data!.stream = result.data!.stream.asBroadcastStream();

      // 缓存 headers
      final responseHeaders = result.headers.map;
      if (!responseHeaders.containsKey('statusCode')) {
        responseHeaders['statusCode'] = [result.statusCode.toString()];
      }

      cacheData(Uint8List.fromList(jsonEncode(responseHeaders).codeUnits),
          cacheHeadersPath);
      StreamSubscription? subscription;
      subscription = dataResult.data!.stream.listen((e) {
        // 缓存片段
        cacheData(e, cacheFilePath);
        subscription?.cancel();
      });

      return dataResult;
    } else {
      // Android 从服务器获取数据
      final result = await _dio.get<Uint8List>(
        url,
        options: dio.Options(
          headers: headers,
          responseType: dio.ResponseType.bytes,
        ),
      );

      // 缓存 headers
      final responseHeaders = result.headers.map;
      if (!responseHeaders.containsKey('statusCode')) {
        responseHeaders['statusCode'] = [result.statusCode.toString()];
      }

      cacheData(Uint8List.fromList(jsonEncode(responseHeaders).codeUnits),
          cacheHeadersPath);
      // 缓存片段
      cacheData(result.data!, cacheFilePath);

      return dio.Response(
        data: dio.ResponseBody(
          Stream.value(result.data!), // 返回 Stream 流
          result.statusCode ?? 200,
          headers: result.headers.map,
          statusMessage: result.statusMessage,
        ),
        requestOptions: result.requestOptions,
        statusCode: result.statusCode,
        statusMessage: result.statusMessage,
      );
    }
  }

  /// 缓存结果
  ///
  /// - data 下载的数据（可以是分片）
  /// - path 缓存的文件的路径
  void cacheData(Uint8List data, String path) {
    print('开始缓存文件: $path 文件长度: ${data.lengthInBytes} 字节');
    // 开起一个 isolate 保存文件
    compute((message) async {
      final file = File(message.$2);
      if (await file.exists()) {
        file.delete();
      }

      // 写入文件
      await file.writeAsBytes(message.$1);
      print('文件 $path 已经缓存完成');
    }, (data, path));
  }

  /// 获取缓存的数据
  ///
  /// - key 缓存的key或者url
  /// - contentRange Range
  Future<dio.Response<dio.ResponseBody>> getCacheResult(
    String fileName,
    String headersFileName,
  ) async {
    print('开始读取缓存文件: $fileName');
    print('开始读取缓存 headers: $headersFileName');
    // 读取文件
    final data = await readFile(fileName);

    // 读取缓存的 headers
    final headersJsonData = await File(headersFileName).readAsBytes();
    final headersMap = jsonDecode(const Utf8Decoder().convert(headersJsonData))
        as Map<String, dynamic>?;
    final headers = <String, List<String>>{};
    if (headersMap != null) {
      for (final key in headersMap.keys) {
        if (key == 'content-length') {
          // 纠正内容的大小 content-length，防止播放器发现内容大小和 headers 里面的不一致
          final contentLength = data.lengthInBytes;
          headers['content-length'] = [contentLength.toString()];
          print('缓存文件的长度 Content-Length: $contentLength 字节');
          continue;
        }

        headers[key] = (headersMap[key] as List<dynamic>).cast<String>();
      }
    }

    print('读取了缓存的 headers: $headers');

    // 读取 headers
    final statusCode =
        int.tryParse(headers['statusCode']?.first ?? '206') ?? 206;
    // 删除 headers 中的 statusCode
    headers.remove('statusCode');

    // 读取片段
    final body = dio.ResponseBody(
      Stream.value(data),
      statusCode,
      headers: headers,
      statusMessage: 'OK',
    );

    return dio.Response(
      data: body,
      requestOptions: dio.RequestOptions(),
      headers: dio.Headers.fromMap(headers),
      statusCode: statusCode,
      statusMessage: 'OK',
    );
  }
}
