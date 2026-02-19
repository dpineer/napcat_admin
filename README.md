# NapCat Admin - AI助手管理后台

一个基于Flutter的跨平台管理后台，用于配置和管理NapCat AI助手系统。

该项目仅支持项目
https://github.com/dpineer/napcat_backend
进行前端的管理,其他后端均未作适配

## 🚀 功能特性

- **系统概览**: 实时显示后端连接状态、LLM模型信息和知识库统计
- **配置管理**: 可视化配置数据库连接、LLM API设置等系统参数
- **提示词管理**: 管理和编辑不同场景的AI提示词模板
- **知识库管理**: 搜索、添加和管理知识库内容
- **跨平台支持**: 支持Web、Linux、Windows、macOS等多平台

## 🛠️ 技术栈

- **前端框架**: Flutter 3.38.9
- **UI库**: Material Design 3
- **状态管理**: Provider
- **HTTP客户端**: http
- **图标库**: Phosphor Flutter
- **字体**: Google Fonts (Noto Sans)

## 📋 环境要求

### 基础环境
- Flutter SDK ^3.10.8
- Dart SDK

### Linux构建依赖
```bash
# 安装必要的构建工具
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev lld
```

## 🔧 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd napcat_admin
```

### 2. 安装依赖
```bash
flutter pub get
```

### 3. 运行应用

#### Web平台
```bash
flutter run -d chrome
```

#### Linux平台
```bash
flutter run -d linux
```

#### 构建发布版本
```bash
# Linux
flutter build linux

# Web
flutter build web
```

## 📁 项目结构

```
napcat_admin/
├── lib/
│   └── main.dart              # 主应用入口和完整实现
├── linux/                     # Linux平台相关文件
├── web/                       # Web平台相关文件
├── pubspec.yaml              # 项目依赖配置
└── README.md                 # 项目文档
```

## 🔌 API配置

应用默认连接地址: `http://127.0.0.1:8082`

可在应用界面中配置以下参数：
- **后端地址**: Flutter应用连接的后端API地址
- **LLM Base URL**: 大语言模型API地址（如DeepSeek）
- **API Key**: 大语言模型API密钥
- **Model Name**: 使用的模型名称
- **PostgreSQL URL**: 数据库连接字符串

## 🎨 界面预览

### 主界面
- 左侧导航栏包含四个主要功能模块
- 采用深色主题，适合开发者使用
- 响应式设计，支持不同屏幕尺寸

### 功能模块
1. **概览**: 显示系统运行状态和关键指标
2. **配置**: 管理系统配置参数
3. **提示词**: 编辑和管理AI提示词模板
4. **知识库**: 管理知识库内容

## 🐛 常见问题

### Linux构建错误
如果遇到构建错误，请确保已安装所有必需的依赖：
```bash
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev lld
```

### 字体加载问题
如果遇到字体加载问题，尝试清理构建缓存：
```bash
flutter clean
flutter pub get
```

## 🔧 开发说明

### 状态管理
使用Provider进行状态管理，主要状态包括：
- 系统配置
- 加载状态
- 错误信息
- 知识库数据
- 提示词模板

### API调用
所有API调用都通过统一的`_get`和`_post`方法，自动处理：
- 加载状态管理
- 错误处理
- JSON序列化

### 主题配置
使用Material Design 3，配置包括：
- 深色主题
- 紫色主色调
- Noto Sans字体

## 📱 支持的平台

- ✅ Web (Chrome, Firefox, Safari)
- ✅ Linux (Ubuntu, Debian等)
- 🔄 Windows (需要相应构建环境)
- 🔄 macOS (需要相应构建环境)

## 🤝 贡献指南

1. Fork项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 📝 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 支持

如遇到问题，请在GitHub Issues中提交问题描述，包括：
- 错误信息
- 复现步骤
- 环境信息（操作系统、Flutter版本等）

---

**注意**: 确保后端服务已启动并运行在配置的地址上，否则部分功能可能无法正常使用。