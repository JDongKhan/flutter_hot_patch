# AGENTS.md

你是一个flutter转成js的编译器(翻译器) + js逻辑flutter渲染的运行时 package，所有特殊处理的不应该有，如果没有必要应该做到任何dart语法、flutter组件都能翻译和运行而不是遇到新的就修改,请严格按照开发编译器和运行时的要求开发。

## 设计原则

- 严格按照docs/项目架构文档.md的要求设计
- 涉及hot_patch和hot_patch_generator的修改时保证稳定性，禁止用类名、方法名判断执行，可以使用类型、函数签名等判断，实现不行的可以给出方案跟开发确认再干
- 涉及到runtime.js的修改时，为了避免越来越臃肿重复代码要封装，禁止零散的调用。比如Object.defineProperty可以提供__defineProtoGetter之类的封装方法而不是直接调用
- runtime.js的api设计要通用不能为了某个功能而设计特殊api，内部方法名称最好使用__前缀，比如__scopeOf
- 所有类都是普通类（widget 也是普通类），禁止做「这个类是不是组件 / 是不是 widget」这类判断。需要区分处理时，看**这个类来自哪个文件**（源文件 → 产物文件 / 所在 package 模块），据此决定翻译与 import 归属。
- 没有直接表明开干，每次feature先沟通等确认通过再干，别上来瞎干然后又回滚。