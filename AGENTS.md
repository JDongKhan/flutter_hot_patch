# AGENTS.md

## 设计原则

### 翻译器
- flutter翻译成js除了特殊语法比如const，其他要一比一翻译，如果js不存在该类或方法可以在flutter.js或runtime.js里面注入方法、生成对应的类。
- 设计要保证hot_patch和hot_patch_generator的稳定性，禁止用类名、方法名判断执行，可以使用类型、函数签名等判断，实现不行的可以给出方案跟开发确认再干

