import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_cache_plugin/video_cache.dart';
import 'package:video_cache_plugin_example/video_player_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final videos = [
    'https://shaungqin.oss-cn-chengdu.aliyuncs.com/uploads%2Fuploads%2F2023-11-24%2F381700809305.mp4video?Expires=1703495245&OSSAccessKeyId=LTAI5tFZfsoqFrbbep4tbtYm&Signature=uipEk%2B%2FP0YjN4hlfHfWptrZaysA%3D',
    'https://shaungqin.oss-cn-chengdu.aliyuncs.com/uploads%2Fuploads%2F2023-10-10%2F301696908843.png?Expires=1703495447&OSSAccessKeyId=LTAI5tFZfsoqFrbbep4tbtYm&Signature=%2FlHXW7ECV%2FgYdzrsXvFtmLkY8VY%3D',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4',
  ];

  @override
  void initState() {
    super.initState();

    initServer();
  }

  void initServer() async {
    // 开启代理服务器
    VideoCache.setupProxy();
    VideoCacheManager().processingCachekey = (key) async {
      return key.split('?').first;
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView.separated(
          itemBuilder: (context, index) => ListTile(
            title: Text(videos[index]),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => VideoPlayerPage(
                    videoUrl: videos[index],
                  ),
                ),
              );
            },
          ),
          separatorBuilder: (context, index) => const Divider(
            indent: 16,
            endIndent: 16,
            height: 0.5,
            color: Colors.black12,
          ),
          itemCount: videos.length,
        ),
      ),
    );
  }
}
