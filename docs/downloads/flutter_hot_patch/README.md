# flutter_hot_patch

[简体中文](README_ZH.md)

> **Read first — [Tech Blog (Chinese)](https://html-preview.github.io/?url=https://github.com/JDongKhan/flutter_hot_patch/blob/main/docs/blog/tech-blog.html)**
> Architecture overview, translation pipeline, runtime closed-loop, capability catalog and known limitations — the complete introduction to the framework.

**A hot-update framework for Flutter widgets**: fix a component in production without a new release.

Flutter's AOT output cannot be hot-patched, so production bugs normally wait for a store review and a
re-release. This framework translates "components that may break" into equivalent JS at build time; at
runtime a JS engine loads the patch and drives its logic, while **rendering still happens on native
Flutter** — so fixing a component is as simple as shipping one JS patch, with no app release.

The component itself needs no changes: the hot-patched class stays a completely ordinary Flutter widget,
and its JS version is loaded only when it actually needs fixing.

## How it works

1. Annotate a component with `@PatchEntry` (from `hot_patch_annotations`);
2. At build time `hot_patch_generator` **statically translates** it into an equivalent JS module
   (no Dart code is executed);
3. At runtime `hot_patch`'s `JsUiWidget` loads that JS patch: **logic runs in JS**, node rendering
   falls back to native Flutter.

## Repository layout

This repository is a monorepo in the form of a Dart **pub workspace**; the three responsibilities
are split into packages:

| Directory | Description |
|---|---|
| `packages/hot_patch_annotations` | Declarative annotations (`@PatchEntry` / `@PatchIgnore` / `@HostInjected`) |
| `packages/hot_patch_generator` | Build-time: Dart widget → JS translation and artifact assembly (build_runner builders) |
| `packages/hot_patch` | Runtime: JS engine + host rendering + capability bridge |
| `example/` | Example app: native vs JS hot-patch comparison demo (business Dart sources in `example/lib/`, generated JS artifacts in [example/patch/](example/patch/)) |
| `tool/patch_server.dart`、`tool/server/`、`start_patch_server.sh` | Local server: `/patch/*` static artifact routes + plain API routes (reads `tool/mock/<path>.json` by URL path) |

The root `pubspec.yaml` is the workspace root; every member pubspec declares `resolution: workspace`,
so the whole repo shares one `pubspec.lock` and one `.dart_tool/`.

## Getting started

```bash
# Install all dependencies once from the root
flutter pub get

# Start the local patch server: build_runner generates artifacts → zip → http server
bash start_patch_server.sh

# Run the example app (patches are served by the server above)
cd example && flutter run
```

## Documentation

| Document | Content |
|---|---|
| [User Manual (Chinese)](docs/使用手册.md) | Integration steps, annotation cheatsheet, build configuration, runtime integration, local debugging, FAQ |
| [Architecture Guide (Chinese)](docs/项目架构文档.md) | Core design laws, architecture overview, core mechanisms, design red lines, extension guide, key file index |
| [Widget Support Reference (Chinese)](docs/组件支持文档.md) | Widget support matrix, style/value/event protocol, generic translation capabilities, known limitations, JS engine capability baseline |
| [TODO.md](TODO.md) | Pending tasks, implementation order, detailed TODOs and deferred items |
| [Blog Center (Chinese)](https://html-preview.github.io/?url=https://github.com/JDongKhan/flutter_hot_patch/blob/main/docs/blog/index.html) | Tech blog, Dart → JS syntax comparison, interactive app prototype |
| [App Prototype (Chinese)](https://html-preview.github.io/?url=https://github.com/JDongKhan/flutter_hot_patch/blob/main/docs/blog/app-prototype.html) | High-fidelity interactive prototype of the example app (HTML) |
| [hot_patch_annotations](packages/hot_patch_annotations/README.md) | Annotations package: `@PatchEntry` / `@PatchIgnore` |
| [hot_patch_generator](packages/hot_patch_generator/README.md) | Generator: artifact layout, options, translation design principles, adding widget support |
| [hot_patch](packages/hot_patch/README.md) | Runtime: patch loading, host capability bridge, logging |
