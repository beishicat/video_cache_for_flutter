import 'package:flutter_test/flutter_test.dart';
import 'package:video_cache_plugin/video_cache_plugin_platform_interface.dart';
import 'package:video_cache_plugin/video_cache_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoCachePluginPlatform
    with MockPlatformInterfaceMixin
    implements VideoCachePluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VideoCachePluginPlatform initialPlatform =
      VideoCachePluginPlatform.instance;

  test('$MethodChannelVideoCachePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoCachePlugin>());
  });

  test('getPlatformVersion', () async {});
}
