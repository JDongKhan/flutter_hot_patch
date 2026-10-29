// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/service/app_service.dart 自动生成
// 重新生成：dart run build_runner build

import { HomeFeed } from '../model/app_models.js';
import { CommunityFeed } from '../model/app_models.js';
import { Resource } from '../model/app_models.js';
import { Post } from '../model/app_models.js';
import { AppNotice } from '../model/app_models.js';
import { OrderFeed } from '../model/app_models.js';
import { Order } from '../model/app_models.js';
import { MineFeed } from '../model/app_models.js';
import { SearchFeed } from '../model/app_models.js';
import { ResourceFeed } from '../model/app_models.js';
import { Spot } from '../model/app_models.js';

// 模型 AppService
export class AppService {
  constructor() {
  }
  async _request(url) {
    return await _app_host_.invoke("post", {"url": url, "params": {"api": url}});
  }
  async _requestQuery(url, query) {
    return await _app_host_.invoke("post", {"url": url, "params": {"api": url, "query": query}});
  }
  async fetchHome(city) {
    var data = await this._request("/app/home");
    var entry = this._cityOf(data["cities"], city);
  }
  async fetchCommunity() {
    var data = await this._request("/app/community");
  }
  async fetchCommunityResources(tab) {
    var data = await this._request("/app/community");
    var all = this._resources(data["resources"]);
    if ((tab.isEmpty || (tab == "广场"))) {
      return all;
    }
    return all.where((r) => { return (r.tab == tab); }).toList();
  }
  async fetchPostList(tab, sort, type, dist, price) {
    var data = await this._requestQuery("/app/posts", {"tab": tab, "sort": sort, "type": type, "dist": dist, "price": price});
    return this._postListOf(this._posts(data["list"]), tab, sort, type);
  }
  async fetchNotifications() {
    var data = await this._request("/app/notifications");
    var list = [];
    for (let e of data["list"]) {

    }
    return list;
  }
  async fetchOrders() {
    var data = await this._request("/app/orders");
  }
  async fetchOrderList(status) {
    var data = await this._requestQuery("/app/orders/list", {"status": status});
    return this._orderListOf(this._orders(data["list"]), status);
  }
  async fetchMine() {
    var data = await this._request("/app/mine");
  }
  async fetchSearch() {
    var data = await this._request("/app/search");
    var home = await this._request("/app/home");
    var entry = this._cityOf(home["cities"], "");
  }
  async fetchResource(id) {
    var community = await this._request("/app/community");
    var posts = await this._request("/app/posts");
  }
  async fetchSpot(id) {
    var data = await this._request("/app/home");
    var cities = data["cities"];
    var all = [];
    for (let c of cities) {
      all.addAll(this._spots(c["spots"]));
    }
    return this._spotOf(all, id);
  }
  async fetchPost(id) {
    var data = await this._request("/app/posts");
    return this._postOf(this._posts(data["list"]), id);
  }
  async fetchOrder(no) {
    var data = await this._request("/app/orders/list");
    return this._orderOf(this._orders(data["list"]), no);
  }
  _spots(raw) {
    var list = [];
    for (let e of raw) {

    }
    return list;
  }
  _posts(raw) {
    var list = [];
    for (let e of raw) {

    }
    return list;
  }
  _orders(raw) {
    var list = [];
    for (let e of raw) {

    }
    return list;
  }
  _resources(raw) {
    var list = [];
    for (let e of raw) {

    }
    return list;
  }
  _resourceJsonOf(raw, id) {
    for (let r of raw) {
      if ((r["id"] == id)) {
        return r;
      }
    }
    return raw.first;
  }
  _cityOf(cities, city) {
    for (let c of cities) {
      if ((c["name"] == city)) {
        return c;
      }
    }
    return cities.first;
  }
  _postListOf(posts, tab, sort, type) {
    var result = ((tab.isEmpty || (tab == "广场")) ? posts : posts.where((p) => { return (p.tab == tab); }).toList());
    result = ((type.isEmpty || (type == "全部")) ? result : result.where((p) => { return (p.type == type); }).toList());
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
    if ((status.isEmpty || (status == "全部"))) {
      return orders;
    }
    return orders.where((o) => { return (o.status == status); }).toList();
  }
  _spotOf(spots, id) {
    for (let s of spots) {
      if ((s.id == id)) {
        return s;
      }
    }
    return spots.first;
  }
  _postOf(posts, id) {
    for (let p of posts) {
      if ((p.id == id)) {
        return p;
      }
    }
    return posts.first;
  }
  _orderOf(orders, no) {
    for (let o of orders) {
      if ((o.no == no)) {
        return o;
      }
    }
    return orders.first;
  }
}

