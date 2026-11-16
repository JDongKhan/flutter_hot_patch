/// barrel `hide` 覆盖载体：包出口转发 [modulePublicTag]，但不转发 [moduleHiddenTag]。
library;

/// 公开符号：`export ... hide moduleHiddenTag` 之后仍可经包出口使用。
const String modulePublicTag = 'public-tag';

/// 被 hide 的符号：只能从本文件直接 import（包出口不转发）。
const String moduleHiddenTag = 'hidden-tag';
