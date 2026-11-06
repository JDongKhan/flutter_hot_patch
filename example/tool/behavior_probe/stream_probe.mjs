// JS 侧行为基线：与 `stream_probe.dart` 的用例逐条对应，输出必须逐字一致。
//
// 用法（在 example/ 下，先 build_runner 产出 patch/）：
//   node tool/behavior_probe/stream_probe.mjs patch
//
// 直接加载仓库真实产物（patch/runtime.js + patch/flutter.js），不另写运行时副本。
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const patchDir = resolve(process.argv[2] ?? 'patch');
const load = (name) => import(pathToFileURL(resolve(patchDir, name)).href);

await load('runtime.js');
const { Stream, StreamController, Future, Duration } = await load('flutter.js');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// A 广播 pause
{
  const log = [];
  const c = StreamController.broadcast({});
  const sub = c.stream.listen((v) => log.push(`data:${v}`), {
    onError: (e) => log.push(`err:${e}`),
    onDone: () => log.push('done'),
  });
  sub.pause();
  c.add(1);
  c.addError('e1');
  let closed = false;
  c.close().then(() => (closed = true));
  log.push('afterCloseCall');
  await sleep(20);
  log.push(`closeDone=${closed}`);
  sub.resume();
  await sleep(30);
  console.log(`A ${log.join('|')}`);
}

// B 单订阅：首个订阅前 add
{
  const got = [];
  const c = new StreamController({});
  c.add(1);
  await sleep(0);
  c.stream.listen((v) => got.push(v));
  await sleep(20);
  console.log(`B ${got.join(',')}`);
}

// C map：上游 error 不终止下游流
{
  const out = [];
  const c = new StreamController({});
  c.stream.map((x) => x * 2).listen((v) => out.push(v), {
    onError: (e) => out.push(`err:${e}`),
    onDone: () => out.push('done'),
  });
  c.add(1);
  c.addError('boom');
  c.add(2);
  c.close();
  await sleep(30);
  console.log(`C ${out.join(',')}`);
}

// D cancelOnError：提供 onError 时依然取消
{
  const out = [];
  const c = new StreamController({});
  c.stream.listen((v) => out.push(v), {
    onError: () => out.push('err'),
    cancelOnError: true,
  });
  c.add(1);
  c.addError('x');
  c.add(2);
  await sleep(20);
  console.log(`D ${out.join(',')}`);
}

// E await for break：取消传播到上游
{
  let produced = 0;
  const gen = Stream.fromAsyncGenerator(
    (async function* () {
      for (let i = 0; i < 20; i++) {
        produced += 1;
        yield i;
      }
    })(),
  );
  for await (const _ of gen) {
    break;
  }
  await sleep(30);
  console.log(`E ${produced}`);
}

// F 同目标同名扩展的显式分派（等价于产物里的 `TagA.tag.call(x)`）
const register = globalThis.registerExtension;
{
  const A = register('String', {
    tag() {
      return 'A';
    },
    loud() {
      return `${A.tag.call(this)}!`;
    },
  }, { id: 'probe#TagA' });
  const B = register('String', { tag() { return 'B'; } }, { id: 'probe#TagB' });
  console.log(`F ${A.tag.call('x')} / ${B.tag.call('x')} / ${A.loud.call('y')}`);
}

// G 显式扩展 setter / 复合赋值（与产物同一形态：先接收者，再右值）
class Counter {
  constructor() {
    this.value = 0;
    this.note = null;
  }
}
{
  const L = register(Counter, {
    level: {
      get() {
        return Math.trunc(this.value / 10);
      },
      set(v) {
        this.value = v * 10;
      },
    },
    label: {
      get() {
        return this.note;
      },
      set(v) {
        this.note = v;
      },
    },
  }, { id: 'probe#LevelEx' });
  const c = new Counter();
  ((__r) => { const __v = 2; L.level.set.call(__r, __v); return __v; })(c);
  ((__r) => { const __v = 1; const __n = L.level.get.call(__r) + __v; L.level.set.call(__r, __n); return __n; })(c);
  console.log(`G ${L.level.get.call(c)}/${c.value}`);

  // H 显式访问器的自增 / 自减 / 空合并赋值（与产物同一形态）
  const c2 = new Counter();
  L.level.set.call(c2, 2);
  ((__r) => { const __v = 1; const __n = L.level.get.call(__r) + __v; L.level.set.call(__r, __n); return __n; })(c2);
  const post = ((__r) => { const __o = L.level.get.call(__r); L.level.set.call(__r, __o + 1); return __o; })(c2);
  const pre = ((__r) => { const __n = L.level.get.call(__r) + 1; L.level.set.call(__r, __n); return __n; })(c2);
  ((__r) => { const __c = L.label.get.call(__r); if (__c != null) return __c; const __v = 'x'; L.label.set.call(__r, __v); return __v; })(c2);
  ((__r) => { const __c = L.label.get.call(__r); if (__c != null) return __c; const __v = 'y'; L.label.set.call(__r, __v); return __v; })(c2);
  console.log(`H ${L.level.get.call(c2)}/${c2.value}/${post}/${pre}/${L.label.get.call(c2)}`);
}
