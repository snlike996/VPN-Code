# Pixi VPN Code

Pixi VPN allows you to build your own VPN application for Android, iOS, and macOS, complete with a powerful Laravel-based admin panel.

## Key Features

- **Multi-Protocol Support**: OpenVPN, V2ray, and WireGuard.
- **Cross-Platform**: Android 15+ Support, iOS, macOS.
- **Monetization**: Google Mobile Ads, In-App Purchases (Google).
- **User Management**: Authentication, Protocol Switching, Live Chat.
- **Admin Panel**: Manage servers, ads, users, and settings.

## Project Structure

- `admin/`: Laravel-based Admin Panel.
- `app/pixi_vpn/`: Flutter Application (Android, iOS, macOS).

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.32.8+
- **Java JDK**: 21.0.2+
- **Xcode**: 15.0+ (for iOS/macOS)
- **Android Studio**: Narwhal recommended.
- **PHP/Composer**: For the Admin Panel.

### Installation

#### Flutter App

1.  Navigate to `app/pixi_vpn`:
    ```bash
    cd app/pixi_vpn
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```
    (Ensure you have a simulator or device connected).

#### Admin Panel

1.  Navigate to `admin/admin`:
    ```bash
    cd admin/admin
    ```
2.  Install dependencies:
    ```bash
    composer install
    npm install
    ```
3.  Configure Environment:
    - Copy `.env.example` to `.env`:
      ```bash
      cp .env.example .env
      ```
    - Update database credentials and other settings in `.env`.
4.  Run Migrations (if applicable) or Import Database:
    - Import `admin/database.sql` into your MySQL database.
5.  Serve:
    ```bash
    php artisan serve
    ```

## API Routes

**GET**
- `/api/general-setting`
- `/api/admob-setting`
- `/api/facebook-ads-setting`
- `/api/contact-setting`
- `/api/popup-setting`

**POST**
- `/api/server-connect` (Payload: `{server_id: number, protocol: string}`)
- `/api/server-disconnect` (Payload: `{server_id: number, protocol: string}`)

## License

See [LICENSE](LICENSE) file.
