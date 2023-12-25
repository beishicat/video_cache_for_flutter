# Flutter 视频缓存插件

一个基于 `Shelf` Web Server 的视频缓存框架，使用 `Shelf` 做代理服务器，拦截播放器的请求做重定向，然后缓存结果，下一次请求就先读取缓存，没有缓存就重新请求结果。

## 如何使用

1. 开启代理

    ```dart
    VideoCache.setupProxy();
    ```

    如果想要对视频缓存的 key 进行处理

    ```dart
    VideoCacheManager().processingCachekey = (key) async {
      // 示范处理，更具自己需求来
      return key.split('?').first;
    };
    ```

2. 生成代理播放链接

    ```dart
    final url = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
    final videoUrl = VideoCache.proxyURL(url);
    ```

3. 将生成的代理播放链接放入播放器直接播放。

4. 清除缓存

    ```dart
    VideoCacheManager().cleanCache();
    ```

## 依赖插件

  - shelf 1.4.1
  - dio 5.2.1+1
  - path_provider 2.1.1
  - crypto 3.0.3
