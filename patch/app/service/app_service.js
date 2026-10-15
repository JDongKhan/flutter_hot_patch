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
  async _request(url, api) {
    await _app_host_.invoke("post", {"url": url, "params": {"api": api}});
  }
  async _requestQuery(api, query) {
    await _app_host_.invoke("post", {"url": api, "params": {"api": api, "query": query}});
  }
  async fetchHome() {
    await this._request("/app/home", "/app/home");
    return new HomeFeed({banners: kBanners, grid: kGrid, spots: kSpots, adImg: kAdImg});
  }
  async fetchCommunity() {
    await this._request("/app/community", "/app/community");
    return new CommunityFeed({tabs: kCommunityTabs, sorts: kSorts, postTypes: kPostTypes, dists: kDists, priceRanges: kPriceRanges, resources: kResources});
  }
  async fetchPostList(tab, sort, type, dist, price) {
    await this._requestQuery("/app/posts", {"tab": tab, "sort": sort, "type": type, "dist": dist, "price": price});
    return this._postListOf(sort, type);
  }
  async fetchOrders() {
    await this._request("/app/orders", "/app/orders");
    return new OrderFeed({statuses: kOrderStatus});
  }
  async fetchOrderList(status) {
    await this._requestQuery("/app/orders/list", {"status": status});
    return this._orderListOf(status);
  }
  async fetchMine() {
    await this._request("/app/mine", "/app/mine");
    return new MineFeed({avatar: kAvatarImg, stats: kMineStats, menu: kMineMenu});
  }
  async fetchSearch() {
    await this._request("/app/search", "/app/search");
    return new SearchFeed({hot: kHotSearch, guesses: kSpots});
  }
  async fetchResource(id) {
    await this._request("/app/resource", "/app/resource");
    return new ResourceFeed({resource: this._resourceOf(id), related: kPosts});
  }
  async fetchSpot(id) {
    await this._request("/app/spot", "/app/spot");
    return this._spotOf(id);
  }
  async fetchPost(id) {
    await this._request("/app/post", "/app/post");
    return this._postOf(id);
  }
  async fetchOrder(no) {
    await this._request("/app/order", "/app/order");
    return this._orderOf(no);
  }
  _postListOf(sort, type) {
    var list = (((type.length === 0) || (type == kPostTypes[0])) ? kPosts : kPosts.filter((p) => { return (p.type == type); }));
    switch (sort) {
      case "最新":
        list = [...list].reverse();
      break;
      case "最热":
        list = (() => { const _t = list; _t.sort((a, b) => { return (b.like - a.like); }); return _t; })();
      break;
    }
    return list;
  }
  _orderListOf(status) {
    if (((status.length === 0) || (status == kOrderStatus[0]))) {
      return kOrders;
    }
    return kOrders.filter((o) => { return (o.status == status); });
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

