import 'package:flutter/foundation.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';

/// 社区页 VM：把原页面 state 收敛成「数据 + 交互方法」。
///
/// 配置、帖子列表、横向资源三条接口并行发出；切 tab 时横幅与列表一起换，
/// 改其它筛选条件只重发列表。
class CommunityVm extends ChangeNotifier {
  final AppService _service = AppService();

  CommunityFeed? feed;
  List<Post>? posts;
  List<Resource>? resources;

  bool listLoading = false;
  bool filterOpen = false;

  String? feedError;
  String? resourcesError;
  String? postsError;

  String tab = '';
  String sort = '';
  String type = '';
  String dist = '';
  String price = '';

  /// 首屏：三条接口并行发，只等一个往返。
  void load() {
    loadFeed();
    loadPosts();
    loadResources();
  }

  Future<void> loadFeed() async {
    try {
      final CommunityFeed value = await _service.fetchCommunity();
      feed = value;
      tab = value.tabs.first;
      sort = value.sorts.first;
      type = value.postTypes.first;
      dist = value.dists.first;
      price = value.priceRanges.first;
      feedError = null;
      notifyListeners();
    } catch (e) {
      print('CommunityVm 配置加载失败: $e');
      feedError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPosts() async {
    listLoading = true;
    notifyListeners();
    try {
      final List<Post> value = await _service.fetchPostList(
        tab,
        sort,
        type,
        dist,
        price,
      );
      posts = value;
      listLoading = false;
      postsError = null;
      notifyListeners();
    } catch (e) {
      print('CommunityVm 帖子列表加载失败: $e');
      listLoading = false;
      postsError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadResources() async {
    try {
      final List<Resource> value = await _service.fetchCommunityResources(tab);
      resources = value;
      resourcesError = null;
      notifyListeners();
    } catch (e) {
      print('CommunityVm 资源横幅加载失败: $e');
      resourcesError = e.toString();
      notifyListeners();
    }
  }

  /// 失败重试：配置、列表、横幅一起重发。
  void retry() {
    feedError = null;
    resourcesError = null;
    postsError = null;
    notifyListeners();
    load();
  }

  /// 切双 tab：横幅与帖子列表一起换。
  void selectTab(String value) {
    tab = value;
    notifyListeners();
    loadPosts();
    loadResources();
  }

  /// 改任一筛选项后按新条件重新请求列表。
  void selectFilter(String key, String value) {
    switch (key) {
      case 'sort':
        sort = value;
      case 'type':
        type = value;
      case 'dist':
        dist = value;
      case 'price':
        price = value;
    }
    notifyListeners();
    loadPosts();
  }

  void resetFilter() {
    final value = feed;
    if (value == null) return;
    sort = value.sorts.first;
    type = value.postTypes.first;
    dist = value.dists.first;
    price = value.priceRanges.first;
    notifyListeners();
    loadPosts();
  }

  void toggleFilter() {
    filterOpen = !filterOpen;
    notifyListeners();
  }
}
