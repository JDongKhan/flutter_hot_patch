// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/service/app_service.dart 自动生成
// 重新生成：dart run build_runner build

import { HomeFeed } from '../model/app_models.js';
import { CommunityFeed } from '../model/app_models.js';
import { OrderFeed } from '../model/app_models.js';
import { MineFeed } from '../model/app_models.js';
import { SearchFeed } from '../model/app_models.js';
import { ResourceFeed } from '../model/app_models.js';
import { kAdImg, kAvatarImg, kBanners, kCommunityTabs, kDists, kGrid, kHotSearch, kMineMenu, kMineStats, kOrderStatus, kOrders, kPostTypes, kPosts, kPriceRanges, kResources, kSorts, kSpots } from 'app_data.js';

// 模型 AppService
export class AppService {
  constructor() {
  }
  async _request(api) {
    await _app_host_.invoke("post", {"params": {"api": api}});
  }
  async fetchHome() {
    await this._request("/app/home");
    return new HomeFeed({banners: kBanners, grid: kGrid, spots: kSpots, adImg: kAdImg});
  }
  async fetchCommunity() {
    await this._request("/app/community");
    return new CommunityFeed({tabs: kCommunityTabs, sorts: kSorts, postTypes: kPostTypes, dists: kDists, priceRanges: kPriceRanges, resources: kResources, posts: kPosts});
  }
  async fetchOrders() {
    await this._request("/app/orders");
    return new OrderFeed({statuses: kOrderStatus, orders: kOrders});
  }
  async fetchMine() {
    await this._request("/app/mine");
    return new MineFeed({avatar: kAvatarImg, stats: kMineStats, menu: kMineMenu});
  }
  async fetchSearch() {
    await this._request("/app/search");
    return new SearchFeed({hot: kHotSearch, guesses: kSpots});
  }
  async fetchResource(id) {
    await this._request("/app/resource");
    return new ResourceFeed({resource: this._resourceOf(id), related: kPosts});
  }
  async fetchSpot(id) {
    await this._request("/app/spot");
    return this._spotOf(id);
  }
  async fetchPost(id) {
    await this._request("/app/post");
    return this._postOf(id);
  }
  async fetchOrder(no) {
    await this._request("/app/order");
    return this._orderOf(no);
  }
  _spotOf(id) {
    for (let s of kSpots) {
      if ((s.id == id)) {
        return s;
      }
    }
    return kSpots[0];
  }
  _postOf(id) {
    for (let p of kPosts) {
      if ((p.id == id)) {
        return p;
      }
    }
    return kPosts[0];
  }
  _orderOf(no) {
    for (let o of kOrders) {
      if ((o.no == no)) {
        return o;
      }
    }
    return kOrders[0];
  }
  _resourceOf(id) {
    for (let r of kResources) {
      if ((r.id == id)) {
        return r;
      }
    }
    return kResources[0];
  }
}

