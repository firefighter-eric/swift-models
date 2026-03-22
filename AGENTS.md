# AGENTS.md

本文件为在本仓库内工作的智能体与协作者提供统一约定。除非用户明确要求，否则本仓库中的新增文档、注释说明、对外说明文字应使用中文。

## 项目概述

本仓库是一个基于 Swift Package Manager 的模型评测项目，当前包含两个主要产物：

- `ModelEvaluationKit`：核心库，负责 CLI 参数解析、评测规格注册、推理框架适配、结果格式化与执行调度。
- `model-test`：命令行程序入口，用于触发一次模型评测流程。

当前工程平台约束如下：

- `macOS 15+`
- `iOS 18+`
- `swift-tools-version: 6.0`

## 目录说明

- `Package.swift`：SwiftPM 包定义。
- `Sources/ModelEvaluationKit/`：核心业务逻辑。
- `Sources/ModelTestCLI/`：CLI 可执行入口。
- `Tests/ModelEvaluationKitTests/`：测试代码。
- `logs/`：本地运行产物或实验记录，不应默认视为源码的一部分。

## 工作原则

- 文档默认使用中文；如必须保留英文原文，应说明原因。
- 修改前先阅读相关文件，避免写出与当前注册表、协议或 CLI 约定不一致的实现。
- 优先做小而明确的改动，避免无关重构。
- 不要随意修改 `logs/` 下内容，除非任务明确要求。
- 不要引入与当前任务无关的新依赖。

## 代码约定

- 保持现有 Swift 代码风格，遵循当前文件中的命名、访问控制与结构拆分方式。
- 新增能力时，优先复用已有协议与注册表模式，例如：
  - `RepositoryEvaluationSpec`
  - `InferenceFrameworkAdapter`
  - `RepositoryRegistry`
  - `FrameworkRegistry`
- CLI 相关改动应同时检查：
  - 参数解析
  - 错误提示
  - 文本/JSON 输出
  - 对应测试
- 错误处理优先复用 `ModelEvaluationError`，避免散落的裸字符串错误。

## 构建与测试

常用命令：

```bash
swift build
swift test
swift run model-test --help
```

如果改动影响以下内容，通常应补充或更新测试：

- CLI 参数解析
- Registry 查找逻辑
- EvaluationRunner 执行流程
- 输出格式化
- 仓库规格与框架适配器之间的兼容性判断

## 文档要求

- 新增的 Markdown 文档默认使用中文。
- 面向仓库使用者的示例命令可以保留命令本体英文，但说明文字需为中文。
- 如需新增 README、设计说明、测试记录，优先保证内容简洁、可执行、可验证。

## 提交前检查

在结束工作前，尽量完成以下检查：

1. 相关目标可以成功构建。
2. 受影响测试可以通过。
3. 新增文档为中文。
4. 改动没有误触无关文件。

## 对智能体的额外要求

- 在实现功能前，先确认改动落点属于核心库、CLI 入口还是测试。
- 如果用户要求不明确，优先做与当前工程结构一致的最小实现。
- 输出结论时，优先说明实际修改了什么、如何验证、还有哪些未验证项。
