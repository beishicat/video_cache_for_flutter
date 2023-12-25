import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_cache_plugin_platform_interface.dart';

/// An implementation of [VideoCachePluginPlatform] that uses method channels.
class MethodChannelVideoCachePlugin extends VideoCachePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_cache_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
