// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/model/app_models.dart 自动生成
// 重新生成：dart run build_runner build


// 模型 Spot
export class Spot {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.id = (args && args.id !== undefined) ? args.id : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.sub = (args && args.sub !== undefined) ? args.sub : '';
    this.sold = (args && args.sold !== undefined) ? args.sold : '';
    this.tag = (args && args.tag !== undefined) ? args.tag : '';
    this.img = (args && args.img !== undefined) ? args.img : '';
    this.desc = (args && args.desc !== undefined) ? args.desc : '';
    this.price = (args && args.price !== undefined) ? args.price : 0;
    this.tags = (args && args.tags !== undefined) ? args.tags : [];
  }
  static fromJson(e) {
    var tags = [];
    for (let t of e["tags"]) {
      tags.add(t);
    }
    return new Spot({
      "id": e["id"],
      "title": e["title"],
      "sub": e["sub"],
      "sold": e["sold"],
      "tag": e["tag"],
      "img": e["img"],
      "desc": e["desc"],
      "price": e["price"],
      "tags": this.tags
    });
  }
}

// 模型 HomeBanner
export class HomeBanner {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.img = (args && args.img !== undefined) ? args.img : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.sub = (args && args.sub !== undefined) ? args.sub : '';
  }
  static fromJson(e) {
    return new HomeBanner({
      "img": e["img"],
      "title": e["title"],
      "sub": e["sub"]
    });
  }
}

// 模型 GridEntry
export class GridEntry {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.emoji = (args && args.emoji !== undefined) ? args.emoji : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
  }
  static fromJson(e) {
    return new GridEntry({
      "emoji": e["emoji"],
      "title": e["title"]
    });
  }
}

// 模型 Post
export class Post {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.id = (args && args.id !== undefined) ? args.id : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.sub = (args && args.sub !== undefined) ? args.sub : '';
    this.type = (args && args.type !== undefined) ? args.type : '';
    this.author = (args && args.author !== undefined) ? args.author : '';
    this.time = (args && args.time !== undefined) ? args.time : '';
    this.img = (args && args.img !== undefined) ? args.img : '';
    this.like = (args && args.like !== undefined) ? args.like : 0;
    this.tab = (args && args.tab !== undefined) ? args.tab : '';
  }
  static fromJson(e) {
    return new Post({
      "id": e["id"],
      "title": e["title"],
      "sub": e["sub"],
      "type": e["type"],
      "author": e["author"],
      "time": e["time"],
      "img": e["img"],
      "like": e["like"],
      "tab": e["tab"]
    });
  }
}

// 模型 AppNotice
export class AppNotice {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.id = (args && args.id !== undefined) ? args.id : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.content = (args && args.content !== undefined) ? args.content : '';
    this.time = (args && args.time !== undefined) ? args.time : '';
    this.type = (args && args.type !== undefined) ? args.type : '';
    this.unread = (args && args.unread !== undefined) ? args.unread : false;
  }
  static fromJson(e) {
    return new AppNotice({
      "id": e["id"],
      "title": e["title"],
      "content": e["content"],
      "time": e["time"],
      "type": e["type"],
      "unread": e["unread"]
    });
  }
}

// 模型 Resource
export class Resource {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.id = (args && args.id !== undefined) ? args.id : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.sub = (args && args.sub !== undefined) ? args.sub : '';
    this.img = (args && args.img !== undefined) ? args.img : '';
    this.tab = (args && args.tab !== undefined) ? args.tab : '';
  }
  static fromJson(e) {
    return new Resource({
      "id": e["id"],
      "title": e["title"],
      "sub": e["sub"],
      "img": e["img"],
      "tab": e["tab"]
    });
  }
}

// 模型 Order
export class Order {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.no = (args && args.no !== undefined) ? args.no : '';
    this.status = (args && args.status !== undefined) ? args.status : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.spec = (args && args.spec !== undefined) ? args.spec : '';
    this.img = (args && args.img !== undefined) ? args.img : '';
    this.price = (args && args.price !== undefined) ? args.price : 0;
    this.step = (args && args.step !== undefined) ? args.step : 0;
  }
  static fromJson(e) {
    return new Order({
      "no": e["no"],
      "status": e["status"],
      "title": e["title"],
      "spec": e["spec"],
      "img": e["img"],
      "price": e["price"],
      "step": e["step"]
    });
  }
}

// 模型 HomeFeed
export class HomeFeed {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.banners = (args && args.banners !== undefined) ? args.banners : [];
    this.grid = (args && args.grid !== undefined) ? args.grid : [];
    this.spots = (args && args.spots !== undefined) ? args.spots : [];
    this.adImg = (args && args.adImg !== undefined) ? args.adImg : '';
  }
  static fromJson(e) {
    var banners = [];
    for (let b of e["banners"]) {
      banners.add(HomeBanner.fromJson(b));
    }
    var grid = [];
    for (let g of e["grid"]) {
      grid.add(GridEntry.fromJson(g));
    }
    var spots = [];
    for (let s of e["spots"]) {
      spots.add(Spot.fromJson(s));
    }
    return new HomeFeed({
      "banners": this.banners,
      "grid": this.grid,
      "spots": this.spots,
      "adImg": e["adImg"]
    });
  }
}

// 模型 CommunityFeed
export class CommunityFeed {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.tabs = (args && args.tabs !== undefined) ? args.tabs : [];
    this.sorts = (args && args.sorts !== undefined) ? args.sorts : [];
    this.postTypes = (args && args.postTypes !== undefined) ? args.postTypes : [];
    this.dists = (args && args.dists !== undefined) ? args.dists : [];
    this.priceRanges = (args && args.priceRanges !== undefined) ? args.priceRanges : [];
  }
  static fromJson(e) {
    var tabs = [];
    for (let v of e["tabs"]) {
      tabs.add(v);
    }
    var sorts = [];
    for (let v of e["sorts"]) {
      sorts.add(v);
    }
    var postTypes = [];
    for (let v of e["postTypes"]) {
      postTypes.add(v);
    }
    var dists = [];
    for (let v of e["dists"]) {
      dists.add(v);
    }
    var priceRanges = [];
    for (let v of e["priceRanges"]) {
      priceRanges.add(v);
    }
    return new CommunityFeed({
      "tabs": this.tabs,
      "sorts": this.sorts,
      "postTypes": this.postTypes,
      "dists": this.dists,
      "priceRanges": this.priceRanges
    });
  }
}

// 模型 OrderFeed
export class OrderFeed {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.statuses = (args && args.statuses !== undefined) ? args.statuses : [];
  }
  static fromJson(e) {
    var statuses = [];
    for (let v of e["statuses"]) {
      statuses.add(v);
    }
    return new OrderFeed({
      "statuses": this.statuses
    });
  }
}

// 模型 MineFeed
export class MineFeed {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.avatar = (args && args.avatar !== undefined) ? args.avatar : '';
    this.stats = (args && args.stats !== undefined) ? args.stats : [];
    this.menu = (args && args.menu !== undefined) ? args.menu : [];
  }
  static fromJson(e) {
    var stats = [];
    for (let row of e["stats"]) {
      var cells = [];
      for (let v of row) {
        cells.add(v);
      }
      stats.add(cells);
    }
    var menu = [];
    for (let m of e["menu"]) {
      menu.add(MenuEntry.fromJson(m));
    }
    return new MineFeed({
      "avatar": e["avatar"],
      "stats": this.stats,
      "menu": this.menu
    });
  }
}

// 模型 SearchFeed
export class SearchFeed {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.hot = (args && args.hot !== undefined) ? args.hot : [];
    this.guesses = (args && args.guesses !== undefined) ? args.guesses : [];
  }
  static fromJson(e) {
    var hot = [];
    for (let v of e["hot"]) {
      hot.add(v);
    }
    var guesses = [];
    for (let s of e["guesses"]) {
      guesses.add(Spot.fromJson(s));
    }
    return new SearchFeed({
      "hot": this.hot,
      "guesses": this.guesses
    });
  }
}

// 模型 ResourceFeed
export class ResourceFeed {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.resource = (args && args.resource !== undefined) ? args.resource : null;
    this.related = (args && args.related !== undefined) ? args.related : [];
  }
  static fromJson(e) {
    var related = [];
    for (let p of e["related"]) {
      related.add(Post.fromJson(p));
    }
    return new ResourceFeed({
      "resource": Resource.fromJson({}),
      "related": this.related
    });
  }
}

// 模型 MenuEntry
export class MenuEntry {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.emoji = (args && args.emoji !== undefined) ? args.emoji : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.screen = (args && args.screen !== undefined) ? args.screen : '';
    this.arg = (args && args.arg !== undefined) ? args.arg : "";
  }
  static fromJson(e) {
    return new MenuEntry({
      "emoji": e["emoji"],
      "title": e["title"],
      "screen": e["screen"],
      "arg": e["arg"]
    });
  }
}

