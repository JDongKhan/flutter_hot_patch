// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/service/app_service.dart 自动生成
// 重新生成：dart run build_runner build

import { HomeFeed } from '../model/app_models.js';
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
import { MenuEntry } from '../model/app_models.js';
import { SearchFeed } from '../model/app_models.js';
import { ResourceFeed } from '../model/app_models.js';

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
    var banners = [];
    for (let e of entry["banners"]) {
      banners.add(this._banner(e));
    }
    var grid = [];
    for (let e of data["grid"]) {
      grid.add(this._grid(e));
    }
    var spots = [];
    for (let e of entry["spots"]) {
      spots.add(this._spot(e));
    }
    return new HomeFeed({banners: banners, grid: grid, spots: spots, adImg: entry["adImg"]});
  }
  async fetchCommunity() {
    var data = await this._request("/app/community");
    return new CommunityFeed({tabs: this._strings(data["tabs"]), sorts: this._strings(data["sorts"]), postTypes: this._strings(data["postTypes"]), dists: this._strings(data["dists"]), priceRanges: this._strings(data["priceRanges"])});
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
      list.add(this._notice(e));
    }
    return list;
  }
  async fetchOrders() {
    var data = await this._request("/app/orders");
    return new OrderFeed({statuses: this._strings(data["statuses"])});
  }
  async fetchOrderList(status) {
    var data = await this._requestQuery("/app/orders/list", {"status": status});
    return this._orderListOf(this._orders(data["list"]), status);
  }
  async fetchMine() {
    var data = await this._request("/app/mine");
    var stats = [];
    for (let row of data["stats"]) {
      stats.add(this._strings(row));
    }
    var menu = [];
    for (let e of data["menu"]) {
      menu.add(this._menu(e));
    }
    return new MineFeed({avatar: data["avatar"], stats: stats, menu: menu});
  }
  async fetchSearch() {
    var data = await this._request("/app/search");
    var home = await this._request("/app/home");
    var entry = this._cityOf(home["cities"], "");
    return new SearchFeed({hot: this._strings(data["hot"]), guesses: this._spots(entry["spots"])});
  }
  async fetchResource(id) {
    var community = await this._request("/app/community");
    var posts = await this._request("/app/posts");
    return new ResourceFeed({resource: this._resourceOf(this._resources(community["resources"]), id), related: this._posts(posts["list"])});
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
  _strings(raw) {
    var list = [];
    for (let v of raw) {
      list.add(v);
    }
    return list;
  }
  _spots(raw) {
    var list = [];
    for (let e of raw) {
      list.add(this._spot(e));
    }
    return list;
  }
  _posts(raw) {
    var list = [];
    for (let e of raw) {
      list.add(this._post(e));
    }
    return list;
  }
  _orders(raw) {
    var list = [];
    for (let e of raw) {
      list.add(this._order(e));
    }
    return list;
  }
  _resources(raw) {
    var list = [];
    for (let e of raw) {
      list.add(this._resource(e));
    }
    return list;
  }
  _banner(e) {
    return new HomeBanner({img: e["img"], title: e["title"], sub: e["sub"]});
  }
  _grid(e) {
    return new GridEntry({emoji: e["emoji"], title: e["title"]});
  }
  _spot(e) {
    return new Spot({id: e["id"], title: e["title"], sub: e["sub"], sold: e["sold"], tag: e["tag"], img: e["img"], desc: e["desc"], price: e["price"], tags: this._strings(e["tags"])});
  }
  _post(e) {
    return new Post({id: e["id"], title: e["title"], sub: e["sub"], type: e["type"], author: e["author"], time: e["time"], img: e["img"], like: e["like"], tab: e["tab"]});
  }
  _notice(e) {
    return new AppNotice({id: e["id"], title: e["title"], content: e["content"], time: e["time"], type: e["type"], unread: e["unread"]});
  }
  _resource(e) {
    return new Resource({id: e["id"], title: e["title"], sub: e["sub"], img: e["img"], tab: e["tab"]});
  }
  _cityOf(cities, city) {
    for (let c of cities) {
      if ((c["name"] == city)) {
        return c;
      }
    }
    return cities.first;
  }
  _order(e) {
    return new Order({no: e["no"], status: e["status"], title: e["title"], spec: e["spec"], img: e["img"], price: e["price"], step: e["step"]});
  }
  _menu(e) {
    return new MenuEntry({emoji: e["emoji"], title: e["title"], screen: e["screen"], arg: e["arg"]});
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
  _resourceOf(resources, id) {
    for (let r of resources) {
      if ((r.id == id)) {
        return r;
      }
    }
    return resources.first;
  }
}

