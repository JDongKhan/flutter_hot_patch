// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/service/app_service.dart 自动生成
// 重新生成：dart run build_runner build

import { Network } from '../../hot_module_base.js';
import { AppTabConfig } from '../model/app_models.js';
import { HomeFloorConfig } from '../model/app_models.js';
import { HomeBanner } from '../model/app_models.js';
import { GridEntry } from '../model/app_models.js';
import { Spot } from '../model/app_models.js';
import { CommunityFeed } from '../model/app_models.js';
import { Resource } from '../model/app_models.js';
import { Post } from '../model/app_models.js';
import { AppNotice } from '../model/app_models.js';
import { OrderFeed } from '../model/app_models.js';
import { Order } from '../model/app_models.js';
import { MineFeed } from '../model/app_models.js';
import { SearchFeed } from '../model/app_models.js';
import { ResourceFeed } from '../model/app_models.js';

// 模型 AppService
export class AppService {
  constructor() {
  }
  async _request(url) {
    return await Network.post({ "url": url, "params": {"api": url} });
  }
  async _requestQuery(url, query) {
    return await Network.post({ "url": url, "params": {"api": url, "query": query} });
  }
  async fetchAppTabs() {
    const data = await this._request("/app/tabs");
    const list = [];
    for (let e of data["tabs"]) {
      list.add(AppTabConfig.fromJson(e));
    }
    return list;
  }
  async fetchHomeFloors() {
    const data = await this._request("/app/home/floors");
    const list = [];
    for (let e of data["floors"]) {
      list.add(HomeFloorConfig.fromJson(e));
    }
    return list;
  }
  async fetchHomeBanners(city) {
    const data = await this._request("/app/home/banner");
    const entry = this._cityOf(data["cities"], city);
    const list = [];
    for (let b of entry["banners"]) {
      list.add(HomeBanner.fromJson(b));
    }
    return list;
  }
  async fetchHomeGrid() {
    const data = await this._request("/app/home/grid");
    const list = [];
    for (let g of data["grid"]) {
      list.add(GridEntry.fromJson(g));
    }
    return list;
  }
  async fetchHomeSpots(city) {
    const data = await this._request("/app/home/spots");
    const entry = this._cityOf(data["cities"], city);
    return this._spots(entry["spots"]);
  }
  async fetchHomePromo(city) {
    const data = await this._request("/app/home/promo");
    const entry = this._cityOf(data["cities"], city);
    return entry["adImg"];
  }
  async fetchCommunity() {
    const data = await this._request("/app/community");
    return CommunityFeed.fromJson(data);
  }
  async fetchCommunityResources(tab) {
    const data = await this._request("/app/community");
    const all = this._resources(data["resources"]);
    if ((tab.isEmpty || (tab === "广场"))) {
      return all;
    }
    return all.where((r) => { return (r.tab === tab); }).toList();
  }
  async fetchPostList(tab, sort, type, dist, price) {
    const data = await this._requestQuery("/app/posts", {"tab": tab, "sort": sort, "type": type, "dist": dist, "price": price});
    return this._postListOf(this._posts(data["list"]), tab, sort, type);
  }
  async fetchNotifications() {
    const data = await this._request("/app/notifications");
    const list = [];
    for (let e of data["list"]) {
      list.add(AppNotice.fromJson(e));
    }
    return list;
  }
  async fetchOrders() {
    const data = await this._request("/app/orders");
    return OrderFeed.fromJson(data);
  }
  async fetchOrderList(status) {
    const data = await this._requestQuery("/app/orders/list", {"status": status});
    return this._orderListOf(this._orders(data["list"]), status);
  }
  async fetchMine() {
    const data = await this._request("/app/mine");
    return MineFeed.fromJson(data);
  }
  async fetchSearch() {
    const data = await this._request("/app/search");
    const home = await this._request("/app/home");
    const entry = this._cityOf(home["cities"], "");
    return SearchFeed.fromJson({"hot": data["hot"], "guesses": entry["spots"]});
  }
  async fetchResource(id) {
    const community = await this._request("/app/community");
    const posts = await this._request("/app/posts");
    return ResourceFeed.fromJson({"resource": this._resourceJsonOf(community["resources"], id), "related": posts["list"]});
  }
  async fetchSpot(id) {
    const data = await this._request("/app/home");
    const cities = data["cities"];
    const all = [];
    for (let c of cities) {
      all.addAll(this._spots(c["spots"]));
    }
    return this._spotOf(all, id);
  }
  async fetchPost(id) {
    const data = await this._request("/app/posts");
    return this._postOf(this._posts(data["list"]), id);
  }
  async fetchOrder(no) {
    const data = await this._request("/app/orders/list");
    return this._orderOf(this._orders(data["list"]), no);
  }
  _spots(raw) {
    const list = [];
    for (let e of raw) {
      list.add(Spot.fromJson(e));
    }
    return list;
  }
  _posts(raw) {
    const list = [];
    for (let e of raw) {
      list.add(Post.fromJson(e));
    }
    return list;
  }
  _orders(raw) {
    const list = [];
    for (let e of raw) {
      list.add(Order.fromJson(e));
    }
    return list;
  }
  _resources(raw) {
    const list = [];
    for (let e of raw) {
      list.add(Resource.fromJson(e));
    }
    return list;
  }
  _resourceJsonOf(raw, id) {
    for (let r of raw) {
      if ((__nn(r["id"]) === id)) {
        return r;
      }
    }
    return raw.first;
  }
  _cityOf(cities, city) {
    for (let c of cities) {
      if ((__nn(c["name"]) === city)) {
        return c;
      }
    }
    return cities.first;
  }
  _postListOf(posts, tab, sort, type) {
    let result = ((tab.isEmpty || (tab === "广场")) ? posts : posts.where((p) => { return (p.tab === tab); }).toList());
    result = ((type.isEmpty || (type === "全部")) ? result : result.where((p) => { return (p.type === type); }).toList());
    switch (sort) {
      case "最新":
      result = result.reversed.toList();
      break;
      case "最热":
      result = (() => { const _t = result.toList(); _t.sort((a, b) => { return b.like.compareTo(a.like); }); return _t; })();
      break;
    }
    return result;
  }
  _orderListOf(orders, status) {
    if ((status.isEmpty || (status === "全部"))) {
      return orders;
    }
    return orders.where((o) => { return (o.status === status); }).toList();
  }
  _spotOf(spots, id) {
    for (let s of spots) {
      if ((s.id === id)) {
        return s;
      }
    }
    return spots.first;
  }
  _postOf(posts, id) {
    for (let p of posts) {
      if ((p.id === id)) {
        return p;
      }
    }
    return posts.first;
  }
  _orderOf(orders, no) {
    for (let o of orders) {
      if ((o.no === no)) {
        return o;
      }
    }
    return orders.first;
  }
}

