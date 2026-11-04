// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/vm/community_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { CommunityFeed } from '../model/app_models.js';
import { Post } from '../model/app_models.js';
import { Resource } from '../model/app_models.js';
import { ChangeNotifier } from '../../flutter.js';

// 模型 CommunityVm
export class CommunityVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this._service = new AppService();
    this.feed = null;
    this.posts = null;
    this.resources = null;
    this.listLoading = false;
    this.filterOpen = false;
    this.feedError = null;
    this.resourcesError = null;
    this.postsError = null;
    this.tab = "";
    this.sort = "";
    this.type = "";
    this.dist = "";
    this.price = "";
  }
  load() {
    this.loadFeed();
    this.loadPosts();
    this.loadResources();
  }
  async loadFeed() {
    try {
      var value = await this._service.fetchCommunity();
      this.feed = value;
      this.tab = value.tabs.first;
      this.sort = value.sorts.first;
      this.type = value.postTypes.first;
      this.dist = value.dists.first;
      this.price = value.priceRanges.first;
      this.feedError = null;
      this.notifyListeners();
    } catch (e) {
      print("CommunityVm 配置加载失败: " + e);
      this.feedError = e.toString();
      this.notifyListeners();
    }
  }
  async loadPosts() {
    this.listLoading = true;
    this.notifyListeners();
    try {
      var value = await this._service.fetchPostList(this.tab, this.sort, this.type, this.dist, this.price);
      this.posts = value;
      this.listLoading = false;
      this.postsError = null;
      this.notifyListeners();
    } catch (e) {
      print("CommunityVm 帖子列表加载失败: " + e);
      this.listLoading = false;
      this.postsError = e.toString();
      this.notifyListeners();
    }
  }
  async loadResources() {
    try {
      var value = await this._service.fetchCommunityResources(this.tab);
      this.resources = value;
      this.resourcesError = null;
      this.notifyListeners();
    } catch (e) {
      print("CommunityVm 资源横幅加载失败: " + e);
      this.resourcesError = e.toString();
      this.notifyListeners();
    }
  }
  retry() {
    this.feedError = null;
    this.resourcesError = null;
    this.postsError = null;
    this.notifyListeners();
    this.load();
  }
  selectTab(value) {
    this.tab = value;
    this.notifyListeners();
    this.loadPosts();
    this.loadResources();
  }
  selectFilter(key, value) {
    switch (key) {
      case "sort":
      this.sort = value;
      break;
      case "type":
      this.type = value;
      break;
      case "dist":
      this.dist = value;
      break;
      case "price":
      this.price = value;
      break;
    }
    this.notifyListeners();
    this.loadPosts();
  }
  resetFilter() {
    var value = this.feed;
    if ((value == null)) {
      return;
    }
    this.sort = value.sorts.first;
    this.type = value.postTypes.first;
    this.dist = value.dists.first;
    this.price = value.priceRanges.first;
    this.notifyListeners();
    this.loadPosts();
  }
  toggleFilter() {
    this.filterOpen = (!this.filterOpen);
    this.notifyListeners();
  }
}

