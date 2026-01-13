# Pixi VPN - 多平台 VPN 系统 + 管理后台

Pixi VPN 是一套功能强大的 VPN 解决方案，包含基于 Laravel 的管理后台和基于 Flutter 的移动端/桌面端应用（支持 Android, iOS, macOS）。
本项目开源并包含所有必须文件，开箱即用。

## ✨ 主要功能

- **多协议支持**: OpenVPN, V2ray, WireGuard。
- **跨平台**: 支持 Android 15+, iOS, macOS。
- **商业化**: 集成 Google AdMob 广告和应用内支付 (In-App Purchases)。
- **用户管理**: 完整的用户认证、协议切换、在线客服系统。
- **管理后台**: 轻松管理服务器、广告配置、用户和系统设置。

## 📂 项目结构

- `admin/`: 管理后台源码 (Laravel 框架)
    - `admin/database.sql`: 数据库初始化文件
- `app/pixi_vpn/`: 客户端源码 (Flutter)

## 🚀 快速开始

### 1. 管理后台 (Admin Panel)

**环境要求**: PHP, Composer, MySQL

1.  **进入目录**:
    ```bash
    cd admin/admin
    ```
2.  **安装依赖** (如果未包含):
    ```bash
    composer install
    npm install
    ```
3.  **配置环境**:
    - 本项目已包含 `.env` 配置文件，您可以直接修改其中的数据库连接信息：
      ```ini
      DB_HOST=127.0.0.1
      DB_PORT=3306
      DB_DATABASE=vpn_admin
      DB_USERNAME=root
      DB_PASSWORD=your_password
      ```
4.  **导入数据库**:
    - 将 `admin/database.sql` 文件导入到您的 MySQL 数据库中。
5.  **启动服务**:
    ```bash
    php artisan serve
    ```
    访问: `http://localhost:8000`

### 2. 客户端 (Flutter App)

**环境要求**: Flutter SDK 3.32.8+, Android Studio / Xcode

1.  **进入目录**:
    ```bash
    cd app/pixi_vpn
    ```
2.  **安装依赖**:
    ```bash
    flutter pub get
    ```
3.  **运行应用**:
    ```bash
    flutter run
    ```

## 🔗 API 接口

- **GET** `/api/general-setting`: 获取通用配置
- **GET** `/api/admob-setting`: 获取广告配置
- **POST** `/api/server-connect`: 服务器连接
- **POST** `/api/server-disconnect`: 服务器断开

## 📄 许可证

本项目遵循开源协议，详情请查看 `LICENSE` 文件。
