# EnglishStudy

EnglishStudy 是一款使用 SwiftUI 开发的 iPhone / iPad 英语学习应用。它连接欧路词典 OpenAPI，同步生词本，并提供中文释义测试、标准发音和英语发音识别。

## 主要功能

- 启动时自动同步欧路生词本
- 自动分页读取全部单词
- 为列表中缺少释义的单词补查详情
- 浏览生词本和单词详情
- 中文意思练习与答案匹配
- 播放英语标准发音
- 录音后自动结束并判断发音
- iPhone 和 iPad 自适应界面
- 使用 Keychain 保存欧路 Authorization

## 环境要求

- macOS
- Xcode 16 或更高版本
- iOS / iPadOS 17 或更高版本
- 欧路词典 OpenAPI Authorization

## 运行项目

1. 使用 Xcode 打开 `EnglishStudyApp/EnglishStudy.xcodeproj`。
2. 在 Signing & Capabilities 中选择自己的 Apple Team。
3. 选择 iPhone、iPad 或模拟器。
4. 点击 Run。
5. 首次使用时进入“设置”，填写欧路 OpenAPI Authorization 并保存。

Authorization 可从欧路 OpenAPI 授权页面取得，通常以 `NIS ` 开头。请勿填写欧路登录密码。

## 数据与隐私

- Authorization 保存在设备 Keychain 中，不写入代码仓库。
- 欧路账号仅保存在设备 UserDefaults 中。
- 录音数据交给 Apple Speech 框架识别，不由本项目自行上传或保存。
- 编译产物、安装包和本地开发数据已通过 `.gitignore` 排除。

## 项目结构

```text
EnglishStudyApp/
├── EnglishStudy.xcodeproj
├── EnglishStudy/
│   ├── AppState.swift
│   ├── EudicClient.swift
│   ├── SpeechEvaluator.swift
│   ├── WordbookView.swift
│   ├── MeaningQuizView.swift
│   └── PronunciationQuizView.swift
└── Tools/
    └── GenerateAppIcon.swift
```

## 构建验证

```bash
xcodebuild \
  -project EnglishStudyApp/EnglishStudy.xcodeproj \
  -scheme EnglishStudy \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## 注意事项

- 使用免费 Personal Team 安装到真机时，签名通常需要定期通过 Xcode 续签。
- 同步期间会访问欧路 API；语音识别是否需要网络由设备和系统语言资源决定。
- 本项目不应提交任何真实 Authorization、密码或签名证书。
