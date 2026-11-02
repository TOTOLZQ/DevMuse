# 开发助手 · DevMuse

[English](README.en.md) | 简体中文

![Build unsigned IPA](https://github.com/TOTOLZQ/DevMuse/actions/workflows/build-ipa.yml/badge.svg)

本地优先的 iOS 开发助手。笔记、代码片段、提示词、对话记录与沙盒文件都保存在设备本地，无需账号，也不会发起网络请求。

- 最低系统版本：iOS 16
- 设备架构：arm64（iPhone / iPad）
- 界面语言：简体中文

## 功能

| 模块 | 说明 |
| --- | --- |
| 助手 | 对话式开发副驾，流式打字动画、快捷提问、本地回应引擎（代码审查、重构、测试、提交信息、发布清单、概念解释） |
| 画布 | 无限画布笔记，支持拖动、缩放、惯性滑动与卡片编辑 |
| 沙盒 | 应用内 Linux 风格虚拟终端，拥有独立的虚拟文件系统，可执行十余种常用命令 |
| 代码库 | 代码片段管理，支持语言、标签检索与一键复制 |
| 提示词 | 提示词实验室，按分类组织，可新建、编辑、复制与删除 |
| 设置 | 外观切换（暖纸 / 墨色 / 跟随系统）、资料库统计、重置初始内容 |

## Linux 沙盒

沙盒是运行在应用内存中的虚拟终端，不加载真实的内核与二进制，也不会读写系统文件。它拥有自己的目录树（`/home/muse`、`/etc`、`/var/log`、`/usr/bin`），命令结果只影响这份虚拟文件系统，重启应用后复位。

支持的常用命令：

| 命令 | 说明 |
| --- | --- |
| `ls [-l|-a] <path>` | 列出目录内容 |
| `cd <path>` | 切换目录，支持 `~`、`..`、绝对路径 |
| `pwd` | 显示当前路径 |
| `cat <file>` | 查看文件内容 |
| `echo <text>` | 输出文本，支持 `>` 与 `>>` 写入文件 |
| `mkdir [-p] <dir>` | 创建目录 |
| `touch <file>` | 创建空文件 |
| `rm [-r] <path>` | 删除文件或目录 |
| `tree [path]` | 以树形显示目录结构 |
| `grep [-i] <pattern> <file>` | 搜索文本并显示行号 |
| `wc <file>` | 统计行数、词数与字符数 |
| `whoami` / `uname` / `date` | 查看用户、内核信息与时间 |
| `uptime` / `env` / `history` | 查看运行时长、环境变量与命令历史 |
| `clear` / `help` | 清空终端 / 显示帮助 |

沙盒会话在应用运行期间保留，切换标签页不会丢失历史。

## 下载与安装

未签名 arm64 IPA（iOS 16+）：

<https://github.com/TOTOLZQ/DevMuse/releases/latest/download/MuseDev-unsigned.ipa>

该安装包未签名，安装前需要用你自己的证书重签：

1. 下载 `MuseDev-unsigned.ipa`
2. 使用签名工具注入证书与描述文件（Sideloadly、AltStore、TrollStore 或自建 p12 工作流均可）
3. 安装到设备，并在“设置 - 通用 - VPN 与设备管理”中信任证书

## 构建

### 自动构建（推荐）

推送到 `main` 分支或打 `v*` 标签后，GitHub Actions 会在 `macos-15` 运行器上执行未签名构建：

- 工作流：[Build unsigned IPA](.github/workflows/build-ipa.yml)
- 构建产物：`muse-dev-unsigned-ipa` Artifact，保留 30 天
- 发布产物：自动发布到 Releases，标签为 `latest`（打标签推送时使用标签名）

也可以在 Actions 页面手动触发 `workflow_dispatch`。

### 本地构建

需要 macOS 与 Xcode 15：

```bash
xcodebuild \
  -project DevMuse.xcodeproj \
  -target DevMuse \
  -configuration Release \
  -sdk iphoneos \
  -arch arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  CONFIGURATION_BUILD_DIR="$PWD/build/Release"

mkdir -p build/Payload
cp -R build/Release/DevMuse.app build/Payload/
cd build && zip -qry MuseDev-unsigned.ipa Payload
```

## 项目结构

```text
DevMuse/
├── .github/workflows/build-ipa.yml     # 未签名 IPA 构建与发布
├── DevMuse.xcodeproj                   # Xcode 工程
└── DevMuse/
    ├── DevMuseApp.swift                # 应用入口
    ├── RootView.swift                  # 自定义底栏与页面切换
    ├── Theme.swift                     # 配色、字体、动效与通用组件
    ├── Models.swift                    # 数据模型与初始内容
    ├── MuseStore.swift                 # 本地持久化与回应引擎
    ├── AgentView.swift                 # 助手对话
    ├── CanvasBoardView.swift           # 无限画布
    ├── CardEditorSheet.swift           # 卡片编辑
    ├── SnippetListView.swift           # 代码库列表
    ├── SnippetDetailView.swift         # 代码片段详情与编辑
    ├── PromptLabView.swift             # 提示词实验室
    ├── SandboxShell.swift              # 虚拟文件系统与命令解释器
    ├── SandboxView.swift               # 沙盒终端界面
    ├── SettingsView.swift              # 设置
    ├── Assets.xcassets                 # 图标与配色资源
    └── Info.plist
```

## 技术说明

- 纯 SwiftUI，无第三方依赖
- 数据以 JSON 写入应用沙盒的 `Documents/muse-store.json`
- 对话回应在设备本地根据关键词生成，不调用云端模型
- 沙盒命令由 Swift 实现的虚拟文件系统解释执行，与真实终端无关

## 隐私

应用不收集数据、不申请网络权限、不含统计 SDK。所有内容仅保存在本机，卸载应用即清除。
