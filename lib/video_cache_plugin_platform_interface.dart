import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_cache_plugin_method_channel.dart';

abstract class VideoCachePluginPlatform extends PlatformInterface {
  /// Constructs a VideoCachePluginPlatform.
  VideoCachePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoCachePluginPlatform _instance = MethodChannelVideoCachePlugin();

  /// The default instance of [VideoCachePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoCachePlugin].
  static VideoCachePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoCachePluginPlatform] when
  /// they register themselves.
  static set instance(VideoCachePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
