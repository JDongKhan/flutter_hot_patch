# AGENTS.md

## 设计原则

- 严格按照docs/项目架构文档.md的要求设计
- 涉及hot_patch和hot_patch_generator的修改时保证稳定性，禁止用类名、方法名判断执行，可以使用类型、函数签名等判断，实现不行的可以给出方案跟开发确认再干
- 涉及到runtime.js的修改时，为了避免越来越臃肿重复代码要封装，禁止零散的调用。比如Object.defineProperty可以提供__defineProtoGetter之类的封装方法而不是直接调用