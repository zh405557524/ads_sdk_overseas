# 项目初始化规则使用说明

## 概述

本项目为 **Flutter 插件/SDK** 工程：**lib** 为对外提供的 SDK 代码，**example** 为用于演示和测试的 Demo 应用。`task-project_init.mdc` 用于两种初始化场景：**新建 Flutter 插件（整仓结构）** 与 **在 example 内搭建完整 Demo 应用**。工程结构说明见 `01-项目结构说明.mdc`。

## 工程结构（SDK/插件）

- **lib/**：插件/SDK 对外 API、Platform Interface、Method Channel 实现；不包含完整 App 的 pages、routes、store 等。
- **example/**：独立 Flutter 应用，通过 `path: ../` 依赖根目录插件，用于演示和测试 SDK；可包含 UI、路由、状态管理等完整应用结构。
- **android/、ios/**：插件的原生实现，与 lib 中 Method Channel 对应。

详见：`01-项目结构说明.mdc`。

## 使用方法

### 触发规则

与 AI 对话时，可用以下关键词触发项目初始化规则：

- **初始化/新建插件（整仓）**：初始化插件、新建插件、创建 Flutter 插件、生成插件模板、SDK 项目结构
- **初始化 example 应用**：初始化 example、搭建 example 应用、example 完整结构、Demo 应用模板

### 示例对话

```
用户：帮我初始化一个新的 Flutter 插件项目，名字叫 my_plugin
AI：将按 task-project_init 场景 A 生成插件结构（lib + example + android/ios）...

用户：在 example 里搭一个完整 Demo，要有多页和路由
AI：将按 task-project_init 场景 B 在 example/ 下生成多页、路由、主题等...
```

## 两种初始化场景

### 场景 A：Flutter 插件（SDK）项目初始化

- **目的**：生成整仓的插件结构（根 lib + example 最小 Demo + android/ios）。
- **规则**：见 `task-project_init.mdc` 的「场景 A」。
- **检查**：根 pubspec 含 plugin 配置、lib 仅 SDK 代码、example 依赖 path: ../、android/ios 已注册。

### 场景 B：example 内完整 Demo 应用初始化

- **目的**：仅在 **example/** 内生成多页、路由、状态管理、主题等完整应用结构。
- **规则**：见 `task-project_init.mdc` 的「场景 B」。
- **检查**：所有应用代码与资源均在 example 下，未改动根 lib 的 SDK 代码。

## 相关规则文件

- **`01-项目结构说明.mdc`**：SDK/插件工程结构，lib 与 example 职责划分（建议 alwaysApply）。
- **`task-project_init.mdc`**：项目初始化两种场景的详细说明与检查清单。
- **`02-导航.mdc`**、**`07-多语言支持.mdc`**、**`task-ui_task.mdc`**：仅适用于 example 的导航、多语言与 UI 规范。

## 生成后的修改

- **场景 A**：根据实际插件名修改 pubspec 的 name、plugin 配置及 lib/android/ios 中的类名、包名。
- **场景 B**：在 example 内按需调整路由、页面、主题、依赖（如 go_router、get、flutter_screenutil 等）。

## 总结

使用项目初始化规则时，先明确是「**新建插件整仓**」还是「**在 example 内搭完整 Demo**」，再按 `task-project_init.mdc` 对应场景生成代码；所有应用级结构仅限 **example**，**lib** 保持为纯 SDK。
