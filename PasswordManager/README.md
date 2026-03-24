# PasswordManager

一个简洁的 macOS 菜单栏密码管理器，使用 Swift 和 SwiftUI 开发。

## 功能特性

- 🔐 **AES-256-GCM 加密** - 使用军用级别加密保护你的密码
- 🔑 **PBKDF2 密钥派生** - 100,000 次迭代，防止暴力破解
- 👆 **Touch ID 支持** - 快速生物识别解锁（带密码备用）
- 🔍 **快速搜索** - 按名称、用户名、网址搜索（带防抖优化）
- 📋 **一键复制** - 点击即可复制密码到剪贴板（30秒后自动清除）
- 📁 **JSON 导入/导出** - 轻松备份和迁移数据
- 🎨 **菜单栏应用** - 轻量级设计，随时可用

## 技术架构

- **语言**: Swift 5
- **框架**: SwiftUI, CryptoKit
- **架构**: MVVM
- **加密**:
  - AES-256-GCM 用于数据加密
  - PBKDF2-SHA256 用于密钥派生
  - DEK (Data Encryption Key) 架构

## 系统要求

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本（用于构建）

## 安装

1. 克隆仓库：
```bash
git clone https://github.com/youshigay/PasswordManager.git
```

2. 在 Xcode 中打开 `PasswordManager.xcodeproj`

3. 构建并运行 (⌘R)

## 使用方法

### 首次使用

1. 点击菜单栏的 🔒 图标
2. 设置主密码（至少 8 个字符）
3. 确认主密码

### 添加密码

1. 点击 **新增** 按钮
2. 填写名称、用户名、密码（必填）
3. 可选填写网址、备注、图标
4. 点击 **保存**

### 搜索密码

在搜索框输入关键词，系统会在名称、用户名、网址中搜索匹配项。

### 编辑/删除密码

点击密码条目右侧的编辑图标进行修改或删除。

## 安全设计

### 加密架构

```
用户密码 → PBKDF2 (100,000次迭代) → 主密钥 (MK)
                                     ↓
随机生成 → DEK (数据加密密钥) → 加密 → 存储到 Keychain
                                     ↓
密码数据 → JSON → AES-GCM 加密 → 存储到文件
```

### 安全特性

- **主密码从不存储** - 只用于派生解密密钥
- **DEK 架构** - 更换密码无需重新加密所有数据
- **Keychain 存储** - 加密的 DEK 和盐值存储在系统 Keychain
- **剪贴板自动清除** - 复制的密码 30 秒后自动清除
- **防暴力破解** - 连续失败后增加延迟和锁定

## 项目结构

```
PasswordManager/
├── Config/
│   └── Constants.swift          # 应用常量配置
├── Models/
│   ├── PasswordEntry.swift      # 密码条目模型
│   ├── Vault.swift              # 保险库模型
│   └── ImportFormat.swift       # 导入/导出格式
├── Services/
│   ├── CryptoService.swift      # 加密服务
│   ├── KeychainService.swift    # Keychain 服务
│   ├── BiometricService.swift   # 生物识别服务
│   └── VaultService.swift       # 保险库服务
├── ViewModels/
│   └── VaultViewModel.swift     # 主视图模型
├── Views/
│   ├── MenuBarView.swift        # 菜单栏主视图
│   ├── SetupView.swift          # 初始设置视图
│   ├── UnlockView.swift         # 解锁视图
│   ├── AddEntryView.swift       # 添加密码视图
│   ├── EditEntryView.swift      # 编辑密码视图
│   ├── SettingsView.swift       # 设置视图
│   ├── EntryListView.swift      # 密码列表视图
│   ├── EntryRowView.swift       # 密码行视图
│   ├── SearchBarView.swift      # 搜索栏视图
│   ├── EmptyStateView.swift     # 空状态视图
│   └── NoResultsView.swift      # 无结果视图
├── AppDelegate.swift            # 应用代理
└── PasswordManagerApp.swift     # 应用入口
```

## 运行测试

在 Xcode 中按 ⌘U 运行单元测试。

测试覆盖：
- CryptoService: 密钥派生、加密/解密
- Vault: 增删改查、搜索
- PasswordEntry: 模型操作

## License

MIT License
