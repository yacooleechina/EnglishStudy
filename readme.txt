English Study 项目说明
=====================

一、项目简介
------------
English Study 是一个使用 SwiftUI 开发的英语单词学习 App，可运行在 iPhone 和 iPad。
App 通过欧路词典 OpenAPI 同步生词本，用于浏览单词、练习中文意思和检查英语发音。

应用名称：English Study
Bundle Identifier：com.yacoolee.EnglishStudy
当前版本：1.0（Build 1）
最低系统版本：iOS 17.0
支持设备：iPhone、iPad
开发工具：Xcode
主要语言：Swift、SwiftUI

二、主要功能
------------
1. 欧路生词本
   - 通过欧路词典 OpenAPI Authorization 同步生词本分组和单词。
   - 支持按分组筛选。
   - 支持上下滚动浏览单词。
   - 点击单词可进入详情页。

2. 单词详情
   - 显示英文单词、中文释义、上下文、加入时间和分组信息。
   - 支持播放英语标准发音。
   - 可进入发音练习。

3. 中文意思练习
   - 显示英文单词并输入中文释义。
   - 将答案与欧路词典同步的中文释义进行匹配。
   - 支持播放当前单词发音。

4. 发音练习
   - 播放标准英语发音。
   - 使用 Apple Speech 进行英语语音识别。
   - 根据识别结果判断发音是否接近目标单词。
   - 发音不正确时自动播放标准读音。
   - 可显示或隐藏中文意思。

5. 设置与安全
   - 欧路账号名称保存在 UserDefaults。
   - 欧路 OpenAPI Authorization 保存在 iOS Keychain。
   - App 不需要保存欧路词典登录密码。

三、项目目录
------------
EnglishStudyApp/EnglishStudy.xcodeproj
    Xcode 项目文件。

EnglishStudyApp/EnglishStudy/
    App 的 Swift 源代码和图片资源。

EnglishStudyApp/EnglishStudy/AppState.swift
    全局状态、同步状态和当前学习单词管理。

EnglishStudyApp/EnglishStudy/EudicClient.swift
    欧路词典 OpenAPI 网络请求。

EnglishStudyApp/EnglishStudy/SpeechEvaluator.swift
    英语发音播放、录音和语音识别。

EnglishStudyApp/EnglishStudy/WordbookView.swift
    生词本列表和分组浏览。

EnglishStudyApp/EnglishStudy/MeaningQuizView.swift
    中文意思练习。

EnglishStudyApp/EnglishStudy/PronunciationQuizView.swift
    发音练习。

EnglishStudyApp/EnglishStudy/Assets.xcassets
    App 图标等资源。

四、欧路词典设置
----------------
1. 登录欧路词典 OpenAPI 页面：
   https://my.eudic.net/OpenAPI/Authorization

2. 获取 Authorization，通常以“NIS ”开头。

3. 打开 App 的“设置”页面。

4. 输入欧路账号和 Authorization。

5. 点击保存，然后点击同步。

安全提醒：
- 不要把欧路登录密码写入源代码。
- 不要把 Authorization 发布到 GitHub 或发送给无关人员。
- Authorization 泄露后，应在欧路词典网站重新生成。

五、在 Xcode 中运行
------------------
1. 使用 Xcode 打开：
   EnglishStudyApp/EnglishStudy.xcodeproj

2. 在顶部 Scheme 中选择 EnglishStudy。

3. 选择 iPhone 或 iPad 模拟器。

4. 点击 Run，或按 Command + R。

5. 第一次使用发音练习时，允许麦克风和语音识别权限。

六、安装包说明
--------------
1. 模拟器版本
   模拟器编译生成的 EnglishStudy.app 只能安装到 iOS Simulator，
   不能直接安装到真实 iPhone 或 iPad。

2. 真机版本
   真实 iPhone/iPad 安装包必须使用 Apple Developer 账号、开发证书和
   Provisioning Profile 进行签名。未签名的 .ipa 不能安装到普通设备。

3. Xcode 真机安装
   - 使用数据线连接 iPhone 或 iPad。
   - 在 Xcode 的 Signing & Capabilities 中选择 Team。
   - 选择已连接设备。
   - 点击 Run，Xcode 会完成签名和安装。

4. 导出 IPA
   - 在 Xcode 中选择 Product > Archive。
   - 在 Organizer 中选择 Distribute App。
   - 根据用途选择 Development、Ad Hoc 或 App Store Connect。

七、当前限制
------------
- 发音评分目前基于 Apple Speech 识别结果和文本相似度，不是音素级评分。
- 网络同步依赖欧路词典 OpenAPI 和有效 Authorization。
- 模拟器的音频系统可能在 Xcode 控制台输出 AudioHardware 或 LoudnessManager
  日志，这通常是模拟器行为，真机表现可能不同。
- 当前没有离线数据库、学习历史和间隔复习算法。

八、隐私权限
------------
发音练习需要：
- 麦克风权限：用于录制用户朗读。
- 语音识别权限：用于将朗读转换为文字。

欧路授权信息保存在设备 Keychain 中，不应显示在日志或提交到代码仓库。
