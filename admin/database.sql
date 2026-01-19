-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Dec 25, 2025 at 05:23 PM
-- Server version: 10.11.7-MariaDB
-- PHP Version: 8.1.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `chadnich_vpn_speedo`
--

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Admin', 'admin@gmail.com', NULL, '$2y$12$.bFRgzhKjYDeN6KToV6TMeDKr2NwI7Lf2avW5COk1mXZeFlBais.O', NULL, '2025-02-06 13:13:15', '2025-09-24 22:42:38');

-- --------------------------------------------------------

--
-- Table structure for table `app_settings`
--

CREATE TABLE `app_settings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `key` varchar(255) NOT NULL,
  `value` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `app_settings`
--

INSERT INTO `app_settings` (`id`, `key`, `value`, `created_at`, `updated_at`) VALUES
(1, 'MAIL_HOST', 'smtp.gmail.com', '2024-03-21 15:28:15', '2024-03-21 15:28:15'),
(2, 'MAIL_PORT', '587', '2024-03-21 15:28:15', '2024-03-21 15:28:15'),
(3, 'MAIL_USERNAME', 'itzzrahin', '2024-03-21 15:28:16', '2024-03-21 15:28:16'),
(4, 'MAIL_PASSWORD', 'tdwvfxyjzlhlgasg', '2024-03-21 15:28:16', '2024-03-21 15:28:16'),
(9, 'paginate', '10', '2024-03-21 15:28:16', '2025-09-15 12:34:23'),
(10, 'app_logo', '1762874983904.png', '2024-03-21 15:28:16', '2025-11-11 14:29:43'),
(11, 'short_logo', '1762874983471.png', '2024-03-21 15:28:17', '2025-11-11 14:29:43'),
(13, 'app_version', '1.0.0', '2025-04-29 12:45:51', '2025-12-23 23:40:35'),
(14, 'status', '0', '2025-04-29 12:56:57', '2025-05-01 00:26:20'),
(15, 'free_premium', 'premium', '2025-04-29 13:00:06', '2025-05-01 00:32:37'),
(16, 'ikev2_status', '0', '2025-05-01 05:30:34', '2025-06-19 13:07:47'),
(17, 'openvpn_status', '1', '2025-05-01 05:30:56', '2025-12-24 00:08:49'),
(18, 'sstp_status', '0', '2025-05-01 05:31:16', '2025-06-19 13:07:47'),
(19, 'v2ray_status', '1', '2025-05-01 05:31:42', '2025-12-23 23:36:03'),
(20, 'wireguard_status', '1', '2025-05-01 05:32:11', '2025-11-15 10:05:30'),
(21, 'openconnect_status', '0', '2025-12-23 13:45:11', '2025-12-23 22:30:46'),
(22, 'device_limit', '1', '2025-12-23 22:30:46', '2025-12-23 22:30:46'),
(23, 'default_protocol', 'wireguard', '2025-12-23 22:30:46', '2025-12-23 22:30:46'),
(24, 'ads_click', '1', '2025-12-23 22:30:46', '2025-12-23 22:30:46'),
(25, 'ads_setting', 'disabled', '2025-12-23 22:30:46', '2025-12-23 22:30:46'),
(26, 'force_update', '0', '2025-12-23 23:40:35', '2025-12-23 23:40:35'),
(27, 'popup_title', 'New Update Available!', '2025-12-23 23:40:35', '2025-12-23 23:40:53'),
(28, 'popup_content', 'please update your app', '2025-12-23 23:40:35', '2025-12-23 23:40:53'),
(29, 'app_url', NULL, '2025-12-23 23:40:35', '2025-12-23 23:40:35');

-- --------------------------------------------------------

--
-- Table structure for table `bandwidths`
--

CREATE TABLE `bandwidths` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `server` varchar(255) NOT NULL,
  `duration` varchar(255) NOT NULL,
  `mb` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bandwidths`
--

INSERT INTO `bandwidths` (`id`, `name`, `email`, `server`, `duration`, `mb`, `created_at`, `updated_at`) VALUES
(1, 'demo', 'demo@gmail.com', 'openvpn', '2', '2000', '2025-04-29 05:45:06', '2025-04-29 05:45:06');

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chats`
--

CREATE TABLE `chats` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `admin_id` bigint(20) UNSIGNED NOT NULL,
  `message` text NOT NULL,
  `sender_type` enum('user','admin') NOT NULL,
  `admin_read_view` tinyint(1) NOT NULL DEFAULT 0,
  `user_read_view` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chats`
--

INSERT INTO `chats` (`id`, `user_id`, `admin_id`, `message`, `sender_type`, `admin_read_view`, `user_read_view`, `created_at`, `updated_at`) VALUES
(49, 66, 1, 'Hello', 'user', 1, 1, '2025-12-25 04:20:05', '2025-12-25 04:20:32'),
(50, 66, 1, 'I need help in purchase', 'user', 0, 1, '2025-12-25 04:24:11', '2025-12-25 04:24:11'),
(51, 66, 1, 'how can we help you sir?', 'admin', 1, 0, '2025-12-25 04:24:26', '2025-12-25 04:24:26'),
(52, 66, 1, 'How to purchase?', 'user', 0, 1, '2025-12-25 04:25:33', '2025-12-25 04:25:33'),
(53, 66, 1, 'tell us your username please', 'admin', 1, 0, '2025-12-25 04:25:57', '2025-12-25 04:25:57');

-- --------------------------------------------------------

--
-- Table structure for table `epays`
--

CREATE TABLE `epays` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_no` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `status` enum('pending','paid','failed') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `epays`
--

INSERT INTO `epays` (`id`, `order_no`, `name`, `amount`, `status`, `created_at`, `updated_at`) VALUES
(1, 'ORD_68c19fda782b8', 'Kayem', 10.00, 'pending', '2025-09-10 09:57:14', '2025-09-10 09:57:14'),
(2, 'ORD_68c1a024e2c81', 'Kayem', 10.00, 'pending', '2025-09-10 09:58:28', '2025-09-10 09:58:28'),
(3, 'ORD_68c1a0523a270', 'Kayem', 10.00, 'pending', '2025-09-10 09:59:14', '2025-09-10 09:59:14'),
(4, 'ORD_68c1a157b8951', 'Kayem', 10.00, 'pending', '2025-09-10 10:03:35', '2025-09-10 10:03:35'),
(5, 'ORD_68c2e0161fc22', 'Kayem', 1.00, 'pending', '2025-09-11 08:43:34', '2025-09-11 08:43:34'),
(6, 'ORD_68c2e062bdfc7', 'Kayem', 1.00, 'pending', '2025-09-11 08:44:50', '2025-09-11 08:44:50'),
(7, 'ORD_68c2e1d28213f', 'Kayem', 1.00, 'pending', '2025-09-11 08:50:58', '2025-09-11 08:50:58'),
(8, 'ORD_68c2e347313a3', 'Admin', 1.00, 'pending', '2025-09-11 08:57:11', '2025-09-11 08:57:11'),
(9, 'ORD_68c2e7d5f2ce4', 'Admin', 1.00, 'pending', '2025-09-11 09:16:38', '2025-09-11 09:16:38'),
(10, 'ORD_68c2e8c87d04b', 'Admin', 1.00, 'pending', '2025-09-11 09:20:40', '2025-09-11 09:20:40'),
(11, 'ORD_68c2e947a7b74', 'Admin', 1.00, 'pending', '2025-09-11 09:22:47', '2025-09-11 09:22:47'),
(12, 'ORD_68c2e9b5a2e99', 'Admin', 1.00, 'pending', '2025-09-11 09:24:37', '2025-09-11 09:24:37'),
(13, 'ORD_68c2e9c5be2bf', 'Admin', 1.00, 'pending', '2025-09-11 09:24:53', '2025-09-11 09:24:53'),
(14, 'ORD_68c2eaf734c3d', 'Admin', 1.00, 'pending', '2025-09-11 09:29:59', '2025-09-11 09:29:59'),
(15, 'ORD_68c2ec3f5eee1', 'Admin', 1.00, 'pending', '2025-09-11 09:35:27', '2025-09-11 09:35:27'),
(16, 'ORD_68c2ece2579d7', 'Kayem', 1.00, 'pending', '2025-09-11 09:38:10', '2025-09-11 09:38:10'),
(17, 'ORD_68c2ecf0d5485', 'Kayem', 1.00, 'pending', '2025-09-11 09:38:24', '2025-09-11 09:38:24'),
(18, 'ORD_68c2ed06234f0', 'Kayem', 1.00, 'pending', '2025-09-11 09:38:46', '2025-09-11 09:38:46'),
(19, '2025091123550786690', 'Test', 1.00, 'pending', '2025-09-11 09:55:06', '2025-09-11 09:55:06'),
(20, 'ORD_68c2f30065df8', 'Test', 1.00, 'pending', '2025-09-11 10:04:16', '2025-09-11 10:04:16'),
(21, 'ORD_68c2f3e90d345', 'New User', 1.00, 'pending', '2025-09-11 10:08:09', '2025-09-11 10:08:09'),
(22, 'ORD_68c2f45e5f4b8', 'New User', 1.00, 'pending', '2025-09-11 10:10:06', '2025-09-11 10:10:06'),
(23, 'ORD_68c2f89b54d27', 'Kayem', 1.00, 'pending', '2025-09-11 10:28:11', '2025-09-11 10:28:11'),
(24, 'ORD_68c7dcc8cf37a', 'test', 1.00, 'pending', '2025-09-15 07:30:48', '2025-09-15 07:30:48'),
(25, 'ORD_68c7de6fd3948', 'test', 1.00, 'pending', '2025-09-15 07:37:51', '2025-09-15 07:37:51'),
(26, 'ORD_68c7e5584464d', 'test', 1.00, 'pending', '2025-09-15 08:07:20', '2025-09-15 08:07:20'),
(27, 'ORD_68c7e6e20cc51', 'test', 1.00, 'pending', '2025-09-15 08:13:54', '2025-09-15 08:13:54'),
(28, 'ORD_68c7e6f4f090a', 'test', 1.00, 'pending', '2025-09-15 08:14:12', '2025-09-15 08:14:12'),
(29, 'ORD_68c7e72d8ee28', 'test', 1.00, 'pending', '2025-09-15 08:15:09', '2025-09-15 08:15:09'),
(30, 'ORD_68c7e97e38595', 'test', 1.00, 'pending', '2025-09-15 08:25:02', '2025-09-15 08:25:02'),
(31, 'ORD_68c7eb356b4e2', 'test', 1.00, 'pending', '2025-09-15 08:32:21', '2025-09-15 08:32:21'),
(32, 'ORD_68c7f021a4845', 'test', 1.00, 'pending', '2025-09-15 08:53:21', '2025-09-15 08:53:21'),
(33, 'ORD_68c7f07459f12', 'test', 1.00, 'pending', '2025-09-15 08:54:44', '2025-09-15 08:54:44'),
(34, 'ORD_68c7f0a78a7cc', 'test', 1.00, 'pending', '2025-09-15 08:55:35', '2025-09-15 08:55:35'),
(35, 'ORD_68c8277fbf109', 'test', 1.00, 'pending', '2025-09-15 12:49:35', '2025-09-15 12:49:35'),
(36, 'ORD_68c82a8b33d1d', 'test', 1.00, 'pending', '2025-09-15 13:02:35', '2025-09-15 13:02:35'),
(37, 'ORD_68c82dbcad3e2', 'test', 1.00, 'pending', '2025-09-15 13:16:12', '2025-09-15 13:16:12'),
(38, 'ORD_68c830ba4d0c5', 'test100@gmail.com', 1.00, 'pending', '2025-09-15 13:28:58', '2025-09-15 13:28:58'),
(39, 'ORD_68c830e9523d7', 'test100@gmail.com', 1.00, 'pending', '2025-09-15 13:29:45', '2025-09-15 13:29:45'),
(40, 'ORD_68c8beb817080', 'VPN Payment', 1.00, 'pending', '2025-09-15 23:34:48', '2025-09-15 23:34:48'),
(41, 'ORD_68c8bf1024aaf', 'VPN Payment', 1.00, 'pending', '2025-09-15 23:36:16', '2025-09-15 23:36:16'),
(42, 'ORD_68c8bf45dc5ca', 'VPN Payment', 1.00, 'pending', '2025-09-15 23:37:09', '2025-09-15 23:37:09'),
(43, 'ORD_68c8c03dc79d3', 'VPN Payment', 1.00, 'pending', '2025-09-15 23:41:17', '2025-09-15 23:41:17'),
(44, 'ORD_68c8c059d706d', 'VPN Payment', 1.00, 'pending', '2025-09-15 23:41:45', '2025-09-15 23:41:45'),
(45, 'ORD_68c8c29403c47', 'VPN Payment', 1.00, 'pending', '2025-09-15 23:51:16', '2025-09-15 23:51:16'),
(46, 'ORD_68c8c5b592bdd', 'VPN Payment', 1.00, 'pending', '2025-09-16 00:04:37', '2025-09-16 00:04:37'),
(47, 'ORD_68c8c6c31fd27', 'VPN Payment', 50.00, 'pending', '2025-09-16 00:09:07', '2025-09-16 00:09:07'),
(48, 'ORD_68cbc5024f6f5', 'VPN Payment', 1.00, 'pending', '2025-09-18 06:38:26', '2025-09-18 06:38:26'),
(49, 'ORD_68cbc526c5afa', 'VPN Payment', 1.00, 'pending', '2025-09-18 06:39:02', '2025-09-18 06:39:02'),
(50, 'ORD_68cbd4802f7ff', 'VPN Payment', 1.00, 'pending', '2025-09-18 07:44:32', '2025-09-18 07:44:32'),
(51, 'ORD_68cbd4df863d1', 'VPN Payment', 1.00, 'pending', '2025-09-18 07:46:07', '2025-09-18 07:46:07'),
(52, 'ORD_68cbd4e6b7510', 'VPN Payment', 1.00, 'pending', '2025-09-18 07:46:14', '2025-09-18 07:46:14'),
(53, 'ORD_68cbd567b7b80', 'VPN Payment', 1.00, 'pending', '2025-09-18 07:48:23', '2025-09-18 07:48:23'),
(54, 'ORD_68d21e93d46a7', 'test', 1.00, 'pending', '2025-09-23 02:14:11', '2025-09-23 02:14:11'),
(55, 'ORD_68d21efbcde28', 'test', 1.00, 'pending', '2025-09-23 02:15:55', '2025-09-23 02:15:55'),
(56, 'ORD_68d22047ec4e2', 'VPN Payment', 1.00, 'pending', '2025-09-23 02:21:27', '2025-09-23 02:21:27'),
(57, 'ORD_68d2209ed394c', 'VPN Payment', 1.00, 'pending', '2025-09-23 02:22:54', '2025-09-23 02:22:54');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `help_centers`
--

CREATE TABLE `help_centers` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `question` varchar(255) NOT NULL,
  `answer` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `help_centers`
--

INSERT INTO `help_centers` (`id`, `question`, `answer`, `created_at`, `updated_at`) VALUES
(3, 'What is VPN?', 'A VPN, or virtual private network, creates a secure and encrypted connection over the internet to protect your data and hide your online activity', '2025-11-04 04:57:21', '2025-11-11 14:30:43');

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2025_11_04_075241_create_help_centers_table', 2),
(5, '2025_11_04_124237_create_chats_table', 3);

-- --------------------------------------------------------

--
-- Table structure for table `open_connects`
--

CREATE TABLE `open_connects` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `country_code` varchar(255) NOT NULL,
  `city_name` varchar(255) NOT NULL,
  `active_count` int(11) DEFAULT 0,
  `link` longtext NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `type` tinyint(1) NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `open_vpns`
--

CREATE TABLE `open_vpns` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `country_code` varchar(255) NOT NULL,
  `city_name` varchar(255) NOT NULL,
  `active_count` int(11) DEFAULT 0,
  `link` longtext NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `type` tinyint(1) NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `open_vpns`
--

INSERT INTO `open_vpns` (`id`, `name`, `country_code`, `city_name`, `active_count`, `link`, `username`, `password`, `type`, `status`, `created_at`, `updated_at`) VALUES
(22, 'Germany Pro OVPN', 'de', 'de', 0, 'Y2xpZW50DQpkZXYgdHVuDQpwcm90byB0Y3ANCnJlbW90ZSAyMTcuMTU0LjI0OS4yMTkgNDQzDQpyZXNvbHYtcmV0cnkgaW5maW5pdGUNCm5vYmluZA0KcGVyc2lzdC1rZXkNCnBlcnNpc3QtdHVuDQphdXRoLXVzZXItcGFzcw0KcmVtb3RlLWNlcnQtdGxzIHNlcnZlcg0KY2lwaGVyIEFFUy0yNTYtQ0JDDQphdXRoIFNIQTI1Ng0KdmVyYiAzDQprZXktZGlyZWN0aW9uIDENCjx0bHMtYXV0aD4NCi0tLS0tQkVHSU4gT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0NCjBmYTA1ZTEyZjMxMDE2MDM1MjdiNTYyZDhjNzZiN2U5DQpjOWQ5YjVkZjZiZjRhMjdkZGYxYTUwNWM5ZTYxNTFlOQ0KMGRmZTVkNjBlYWE5ZWI1YzBiNDYwYzRhMTM5NWNmZTgNCjY5MmNkNDkxMDEwOGNhZTEyY2UwYjhkNmVhNzQyOGNlDQo4NTEwNjIzMjQxMmNlODI4NDA1MGZiNThjZDVkYzZkNw0KMjVhNzFiNThkMTMxOTZkODczMjdkNTY5NmM2NGFmNTgNCjRkNjRlMDQ4YTIwYTczOTNmNTY2NDAzMzg2MzE5ODQwDQo5ZDMyZjYxMWIyZjFlNjIzOTM3MGY5MTNhNTA5NGJiYg0KMjU0YWI2ZDQ3ZmU1NDI3Mjc3MzE4NTVkZWU1ZWViYTQNCjlmYTk1OTM0OTczNDI0MTJhNjI4MGY0NWU1NTg1MjQ1DQoyYTc5NTJiNzRjMTAwMGZlZDZjZTJjNDEwODFmMWI4MA0KMmI2NWJiZDJiNjMwZDMyYzJiNjFmYmVhZjk3MDUzNzINCjM4ODYyYzFhY2ZiMDY5ZGU2MzJmN2FmZGNjZDM5MGJjDQpiMTFlNDk5M2ExMmQ3ZTU3ZWVlZDEwODQ2ZmI2ZDc2Mg0KNTU5ZWZiY2NlMTFhNDExNTg2ZDhkNDU3MzM1MmQ5ODkNCmI0NjZjYzRhOGJjZDc5Y2EyNTI1Yjg3MGJlNDA5ZjY2DQotLS0tLUVORCBPcGVuVlBOIFN0YXRpYyBrZXkgVjEtLS0tLQ0KPC90bHMtYXV0aD4NCjxjYT4NCi0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQ0KTUlJRFlEQ0NBa2lnQXdJQkFnSVVJQWxxc3dSZEp4aUE4MkFkaXRDQ25LRXNBejR3RFFZSktvWklodmNOQVFFTA0KQlFBd0hURWJNQmtHQTFVRUF3d1NjelV1Wm5KbFpXSmxjM1IyY0c0dVkyOXRNQjRYRFRJMU1UQXhPREV6TVRReA0KTjFvWERUTTFNVEF4TmpFek1UUXhOMW93SFRFYk1Ca0dBMVVFQXd3U2N6VXVabkpsWldKbGMzUjJjRzR1WTI5dA0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUE2U291UU0xcjdJSDNxSVJxWURWdQ0KL1dFeHZRdk1kbGNmcUhPdXVEcStkL1ZOZk1RNGl1b3dhWlU5RmJCWUZsSVAyTTFxYXhIU2UvTlNmNktVMXpUZg0KQ1huTHpRKzhTL2VHMzFtUkUvNGRFeHFuYkJMY0F1WmVOZGorRERCd2s4NU44bzcwT3huODZQeXp5cFkydHpKZw0KZTlxRU9TT2FTRklkZlRNR1lkYmtMeUdNS0FPTGNiNE5FdXU3UWx5YjhXaFRZbjFQN3RqSmZvUzlmTmdkUDFsNA0KdnN5K01HNGFPRHozazBnSkk3NlQ2Q3JSL3I0WjIvdHRuVXd6VjlWM3VPV2pVU25jMkNIK1ZLQUYySkIyM2FJYw0KaUprbUZKcXdlTGNJK3c4UDBlQ3ExVlZBK2pwYTIrZldDYTJUb0drTk81S2FMOHQ5eEd4MmQrRCtqbUVyeG9BUg0Ka1FJREFRQUJvNEdYTUlHVU1CMEdBMVVkRGdRV0JCUkFNdndPMTlPQ3QzZXFkS0RMblE1MldrVmYxekJZQmdOVg0KSFNNRVVUQlBnQlJBTXZ3TzE5T0N0M2VxZEtETG5RNTJXa1ZmMTZFaHBCOHdIVEViTUJrR0ExVUVBd3dTY3pVdQ0KWm5KbFpXSmxjM1IyY0c0dVkyOXRnaFFnQ1dxekJGMG5HSUR6WUIySzBJS2NvU3dEUGpBTUJnTlZIUk1FQlRBRA0KQVFIL01Bc0dBMVVkRHdRRUF3SUJCakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBY2dJK0sxOGx4alBEUEdYNw0KMFFMQkM1ZUFsdDVYbWRpVXhwYmtrOGlPT1RhcXdiTFBwZjJtQzdqOGVtd082dGl4NGVYeTFjeHZDZ0JQTmlnaA0KRCszZlpXZURTNWtYbS9wZjdtaEpwYkZrZVh2eFpwUmVvNkovdDRpc0djOVQ5Y3MxZ2tkdnJwR1lCSzFURUgwSw0Ka0U4WVpCRVpEbmd6elo2SEk0bmtqNmIxVnlGbFJ1MXJKRHMvQ0Rsa3dkSmswUUhhS2lzRElDbWIrTDFHcEJVTg0KeFA3WDNhR2tWWGk3NEVBeEVhRUFiTkJZendsMWtNYUJaT2tUaUkyMUJkemhuajhDVmRGODhkdHRWZ29iOUJNSg0KNFVhdzYyNmFvb0g2cEVMTXl2R3FrRVlHTTNBd2hLS3AwQVl1WExBSjhuQ0FsVTJiRmlUdVRaanhveGQ0bGt5ZQ0KWm1wQ3lRPT0NCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0NCjwvY2E+', 'fbvpn', 'Pakistan@nt90', 1, 1, '2025-12-24 07:10:46', '2025-12-24 08:18:24'),
(23, 'Germany', 'de', 'de', 0, 'IyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyBPcGVuVlBOIDIuMCBTYW1wbGUgQ29uZmlndXJhdGlvbiBGaWxlDQojIGZvciBQYWNrZXRpWCBWUE4gLyBTb2Z0RXRoZXIgVlBOIFNlcnZlcg0KIyANCiMgISEhIEFVVE8tR0VORVJBVEVEIEJZIFNPRlRFVEhFUiBWUE4gU0VSVkVSIE1BTkFHRU1FTlQgVE9PTCAhISENCiMgDQojICEhISBZT1UgSEFWRSBUTyBSRVZJRVcgSVQgQkVGT1JFIFVTRSBBTkQgTU9ESUZZIElUIEFTIE5FQ0VTU0FSWSAhISENCiMgDQojIFRoaXMgY29uZmlndXJhdGlvbiBmaWxlIGlzIGF1dG8tZ2VuZXJhdGVkLiBZb3UgbWlnaHQgdXNlIHRoaXMgY29uZmlnIGZpbGUNCiMgaW4gb3JkZXIgdG8gY29ubmVjdCB0byB0aGUgUGFja2V0aVggVlBOIC8gU29mdEV0aGVyIFZQTiBTZXJ2ZXIuDQojIEhvd2V2ZXIsIGJlZm9yZSB5b3UgdHJ5IGl0LCB5b3Ugc2hvdWxkIHJldmlldyB0aGUgZGVzY3JpcHRpb25zIG9mIHRoZSBmaWxlDQojIHRvIGRldGVybWluZSB0aGUgbmVjZXNzaXR5IHRvIG1vZGlmeSB0byBzdWl0YWJsZSBmb3IgeW91ciByZWFsIGVudmlyb25tZW50Lg0KIyBJZiBuZWNlc3NhcnksIHlvdSBoYXZlIHRvIG1vZGlmeSBhIGxpdHRsZSBhZGVxdWF0ZWx5IG9uIHRoZSBmaWxlLg0KIyBGb3IgZXhhbXBsZSwgdGhlIElQIGFkZHJlc3Mgb3IgdGhlIGhvc3RuYW1lIGFzIGEgZGVzdGluYXRpb24gVlBOIFNlcnZlcg0KIyBzaG91bGQgYmUgY29uZmlybWVkLg0KIyANCiMgTm90ZSB0aGF0IHRvIHVzZSBPcGVuVlBOIDIuMCwgeW91IGhhdmUgdG8gcHV0IHRoZSBjZXJ0aWZpY2F0aW9uIGZpbGUgb2YNCiMgdGhlIGRlc3RpbmF0aW9uIFZQTiBTZXJ2ZXIgb24gdGhlIE9wZW5WUE4gQ2xpZW50IGNvbXB1dGVyIHdoZW4geW91IHVzZSB0aGlzDQojIGNvbmZpZyBmaWxlLiBQbGVhc2UgcmVmZXIgdGhlIGJlbG93IGRlc2NyaXB0aW9ucyBjYXJlZnVsbHkuDQoNCg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyBTcGVjaWZ5IHRoZSB0eXBlIG9mIHRoZSBsYXllciBvZiB0aGUgVlBOIGNvbm5lY3Rpb24uDQojIA0KIyBUbyBjb25uZWN0IHRvIHRoZSBWUE4gU2VydmVyIGFzIGEgIlJlbW90ZS1BY2Nlc3MgVlBOIENsaWVudCBQQyIsDQojICBzcGVjaWZ5ICdkZXYgdHVuJy4gKExheWVyLTMgSVAgUm91dGluZyBNb2RlKQ0KIw0KIyBUbyBjb25uZWN0IHRvIHRoZSBWUE4gU2VydmVyIGFzIGEgYnJpZGdpbmcgZXF1aXBtZW50IG9mICJTaXRlLXRvLVNpdGUgVlBOIiwNCiMgIHNwZWNpZnkgJ2RldiB0YXAnLiAoTGF5ZXItMiBFdGhlcm5ldCBCcmlkZ2luZSBNb2RlKQ0KDQpkZXYgdHVuDQoNCg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyBTcGVjaWZ5IHRoZSB1bmRlcmx5aW5nIHByb3RvY29sIGJleW9uZCB0aGUgSW50ZXJuZXQuDQojIE5vdGUgdGhhdCB0aGlzIHNldHRpbmcgbXVzdCBiZSBjb3JyZXNwb25kIHdpdGggdGhlIGxpc3RlbmluZyBzZXR0aW5nIG9uDQojIHRoZSBWUE4gU2VydmVyLg0KIyANCiMgU3BlY2lmeSBlaXRoZXIgJ3Byb3RvIHRjcCcgb3IgJ3Byb3RvIHVkcCcuDQoNCnByb3RvIHVkcA0KDQoNCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMNCiMgVGhlIGRlc3RpbmF0aW9uIGhvc3RuYW1lIC8gSVAgYWRkcmVzcywgYW5kIHBvcnQgbnVtYmVyIG9mDQojIHRoZSB0YXJnZXQgVlBOIFNlcnZlci4NCiMgDQojIFlvdSBoYXZlIHRvIHNwZWNpZnkgYXMgJ3JlbW90ZSA8SE9TVE5BTUU+IDxQT1JUPicuIFlvdSBjYW4gYWxzbw0KIyBzcGVjaWZ5IHRoZSBJUCBhZGRyZXNzIGluc3RlYWQgb2YgdGhlIGhvc3RuYW1lLg0KIyANCiMgTm90ZSB0aGF0IHRoZSBhdXRvLWdlbmVyYXRlZCBiZWxvdyBob3N0bmFtZSBhcmUgYSAiYXV0by1kZXRlY3RlZA0KIyBJUCBhZGRyZXNzIiBvZiB0aGUgVlBOIFNlcnZlci4gWW91IGhhdmUgdG8gY29uZmlybSB0aGUgY29ycmVjdG5lc3MNCiMgYmVmb3JlaGFuZC4NCiMgDQojIFdoZW4geW91IHdhbnQgdG8gY29ubmVjdCB0byB0aGUgVlBOIFNlcnZlciBieSB1c2luZyBUQ1AgcHJvdG9jb2wsDQojIHRoZSBwb3J0IG51bWJlciBvZiB0aGUgZGVzdGluYXRpb24gVENQIHBvcnQgc2hvdWxkIGJlIHNhbWUgYXMgb25lIG9mDQojIHRoZSBhdmFpbGFibGUgVENQIGxpc3RlbmVycyBvbiB0aGUgVlBOIFNlcnZlci4NCiMgDQojIFdoZW4geW91IHVzZSBVRFAgcHJvdG9jb2wsIHRoZSBwb3J0IG51bWJlciBtdXN0IHNhbWUgYXMgdGhlIGNvbmZpZ3VyYXRpb24NCiMgc2V0dGluZyBvZiAiT3BlblZQTiBTZXJ2ZXIgQ29tcGF0aWJsZSBGdW5jdGlvbiIgb24gdGhlIFZQTiBTZXJ2ZXIuDQoNCnJlbW90ZSB2cG4yMTE5Njk0NDcub3Blbmd3Lm5ldCAxNzcwDQoNCg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyBUaGUgSFRUUC9IVFRQUyBwcm94eSBzZXR0aW5nLg0KIyANCiMgT25seSBpZiB5b3UgaGF2ZSB0byB1c2UgdGhlIEludGVybmV0IHZpYSBhIHByb3h5LCB1bmNvbW1lbnQgdGhlIGJlbG93DQojIHR3byBsaW5lcyBhbmQgc3BlY2lmeSB0aGUgcHJveHkgYWRkcmVzcyBhbmQgdGhlIHBvcnQgbnVtYmVyLg0KIyBJbiB0aGUgY2FzZSBvZiB1c2luZyBwcm94eS1hdXRoZW50aWNhdGlvbiwgcmVmZXIgdGhlIE9wZW5WUE4gbWFudWFsLg0KDQo7aHR0cC1wcm94eS1yZXRyeQ0KO2h0dHAtcHJveHkgW3Byb3h5IHNlcnZlcl0gW3Byb3h5IHBvcnRdDQoNCg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyBUaGUgZW5jcnlwdGlvbiBhbmQgYXV0aGVudGljYXRpb24gYWxnb3JpdGhtLg0KIyANCiMgRGVmYXVsdCBzZXR0aW5nIGlzIGdvb2QuIE1vZGlmeSBpdCBhcyB5b3UgcHJlZmVyLg0KIyBXaGVuIHlvdSBzcGVjaWZ5IGFuIHVuc3VwcG9ydGVkIGFsZ29yaXRobSwgdGhlIGVycm9yIHdpbGwgb2NjdXIuDQojIA0KIyBUaGUgc3VwcG9ydGVkIGFsZ29yaXRobXMgYXJlIGFzIGZvbGxvd3M6DQojICBjaXBoZXI6IFtOVUxMLUNJUEhFUl0gTlVMTCBBRVMtMTI4LUNCQyBBRVMtMTkyLUNCQyBBRVMtMjU2LUNCQyBCRi1DQkMNCiMgICAgICAgICAgQ0FTVC1DQkMgQ0FTVDUtQ0JDIERFUy1DQkMgREVTLUVERS1DQkMgREVTLUVERTMtQ0JDIERFU1gtQ0JDDQojICAgICAgICAgIFJDMi00MC1DQkMgUkMyLTY0LUNCQyBSQzItQ0JDDQojICBhdXRoOiAgIFNIQSBTSEExIE1ENSBNRDQgUk1EMTYwDQoNCmNpcGhlciBBRVMtMTI4LUNCQw0KYXV0aCBTSEExDQoNCg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyBPdGhlciBwYXJhbWV0ZXJzIG5lY2Vzc2FyeSB0byBjb25uZWN0IHRvIHRoZSBWUE4gU2VydmVyLg0KIyANCiMgSXQgaXMgbm90IHJlY29tbWVuZGVkIHRvIG1vZGlmeSBpdCB1bmxlc3MgeW91IGhhdmUgYSBwYXJ0aWN1bGFyIG5lZWQuDQoNCnJlc29sdi1yZXRyeSBpbmZpbml0ZQ0Kbm9iaW5kDQpwZXJzaXN0LWtleQ0KcGVyc2lzdC10dW4NCmNsaWVudA0KdmVyYiAzDQojYXV0aC11c2VyLXBhc3MNCg0KDQojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjDQojIFRoZSBjZXJ0aWZpY2F0ZSBmaWxlIG9mIHRoZSBkZXN0aW5hdGlvbiBWUE4gU2VydmVyLg0KIyANCiMgVGhlIENBIGNlcnRpZmljYXRlIGZpbGUgaXMgZW1iZWRkZWQgaW4gdGhlIGlubGluZSBmb3JtYXQuDQojIFlvdSBjYW4gcmVwbGFjZSB0aGlzIENBIGNvbnRlbnRzIGlmIG5lY2Vzc2FyeS4NCiMgUGxlYXNlIG5vdGUgdGhhdCBpZiB0aGUgc2VydmVyIGNlcnRpZmljYXRlIGlzIG5vdCBhIHNlbGYtc2lnbmVkLCB5b3UgaGF2ZSB0bw0KIyBzcGVjaWZ5IHRoZSBzaWduZXIncyByb290IGNlcnRpZmljYXRlIChDQSkgaGVyZS4NCg0KPGNhPg0KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlGYXpDQ0ExT2dBd0lCQWdJUkFJSVF6N0RTUU9OWlJHUGd1Mk9DaXdBd0RRWUpLb1pJaHZjTkFRRUxCUUF3DQpUekVMTUFrR0ExVUVCaE1DVlZNeEtUQW5CZ05WQkFvVElFbHVkR1Z5Ym1WMElGTmxZM1Z5YVhSNUlGSmxjMlZoDQpjbU5vSUVkeWIzVndNUlV3RXdZRFZRUURFd3hKVTFKSElGSnZiM1FnV0RFd0hoY05NVFV3TmpBME1URXdORE00DQpXaGNOTXpVd05qQTBNVEV3TkRNNFdqQlBNUXN3Q1FZRFZRUUdFd0pWVXpFcE1DY0dBMVVFQ2hNZ1NXNTBaWEp1DQpaWFFnVTJWamRYSnBkSGtnVW1WelpXRnlZMmdnUjNKdmRYQXhGVEFUQmdOVkJBTVRERWxUVWtjZ1VtOXZkQ0JZDQpNVENDQWlJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dJUEFEQ0NBZ29DZ2dJQkFLM29KSFAwRkRmem01NHJWeWdjDQpoNzdjdDk4NGtJeHVQT1pYb0hqM2RjS2kvdlZxYnZZQVR5amIzbWlHYkVTVHRyRmovUlFTYTc4ZjB1b3hteUYrDQowVE04dWtqMTNYbmZzN2ovRXZFaG1rdkJpb1p4YVVwbVpteVBmanh3djYwcElnYno1TURtZ0s3aVM0KzNtWDZVDQpBNS9UUjVkOG1VZ2pVK2c0cms4S2I0TXUwVWxYaklCMHR0b3YwRGlOZXdOd0lSdDE4akE4K28rdTNkcGpxK3NXDQpUOEtPRVV0K3p3dm8vN1YzTHZTeWUwcmdUQklsREhDTkF5bWc0Vk1rN0JQWjdobS9FTE5LakQrSm8yRlIzcXlIDQpCNVQwWTNIc0x1SnZXNWlCNFlsY05IbHNkdTg3a0dKNTV0dWttaThteGRBUTRRN2UyUkNPRnZ1Mzk2ajN4K1VDDQpCNWlQTmdpVjUrSTNsZzAyZFo3N0RuS3hIWnU4QS9sSkJkaUIzUVcwS3RaQjZhd0JkcFVLRDlqZjFiMFNIelV2DQpLQmRzMHBqQnFBbGtkMjVITjdyT3JGbGVhSjEvY3RhSnhRWkJLVDVaUHQwbTlTVEpFYWRhbzB4QUgwYWhtYlduDQpPbEZ1aGp1ZWZYS25FZ1Y0V2UwK1VYZ1ZDd09QamRBdkJiSStlMG9jUzNNRkV2ekc2dUJRRTN4RGszU3p5blRuDQpqaDhCQ05BdzFGdHhOclFIdXNFd01GeEl0NEk3bUtaOVlJcWlveW1DekxxOWd3UWJvb01EUWFIV0JmRWJ3cmJ3DQpxSHlHTzBhb1NDcUkzSGFhZHI4ZmFxVTlHWS9yT1BOazNzZ3JEUW9vLy9mYjRoVkMxQ0xRSjEzaGVmNFk1M0NJDQpyVTdtMllzNnh0MG5VVzcvdkdUMU0wTlBBZ01CQUFHalFqQkFNQTRHQTFVZER3RUIvd1FFQXdJQkJqQVBCZ05WDQpIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSNXRGbm1lN2JsNUFGemdBaUl5QnBZOXVtYmJqQU5CZ2txDQpoa2lHOXcwQkFRc0ZBQU9DQWdFQVZSOVlxYnl5cUZEUURMSFlHbWtnSnlrSXJHRjFYSXB1K0lMbGFTL1Y5bFpMDQp1Ymh6RUZuVElaZCs1MHh4KzdMU1lLMDVxQXZxRnlGV2hmRlFEbG5yenVCWjZickpGZStHblkrRWdQYms2WkdRDQozQmViWWh0RjhHYVYwbnh2d3VvNzd4L1B5OWF1Si9HcHNNaXUvWDErbXZvaUJPdi8yWC9xa1NzaXNSY09qL0tLDQpORnRZMlB3QnlWUzV1Q2JNaW9nemlVd3RoRHlDMys2V1Z3VzZMTHYzeExmSFRqdUN2akhJSW5Oemt0SENnS1E1DQpPUkF6STRKTVBKK0dzbFdZSGI0cGhvd2ltNTdpYXp0WE9vSndUZHdKeDRuTENnZE5iT2hkanNudnpxdkh1N1VyDQpUa1hXU3RBbXpPVnl5Z2hxcFpYakZhSDNwTzNKTEYrbCsvK3NLQUl1dnRkN3UrTnhlNUFXMHdkZVJsTjhOd2RDDQpqTlBFbHB6Vm1iVXE0SlVhZ0VpdVREa0h6c3hIcEZLVks3cTQrNjNTTTFOOTVSMU5iZFdoc2NkQ2IrWkFKelZjDQpveWkzQjQzbmpUT1E1eU9mKzFDY2VXeEcxYlFWczVadWZwc01sanE0VWkwLzFsdmgrd2pDaFA0a3FLT0oycXhxDQo0Umdxc2FoRFlWdlRIOXc3alhieUxlaU5kZDhYTTJ3OVUvdDd5MEZmLzl5aTBHRTQ0WmE0ckYyTE45ZDExVFBBDQptUkd1blVIQmNuV0V2Z0pCUWw5bkpFaVUwWnNudmdjL3ViaFBnWFJSNFhxMzdaMGo0cjdnMVNnRUV6d3hBNTdkDQplbXlQeGdjWXhuL2VSNDQvS0o0RUJzK2xWRFIzdmV5Sm0ra1hROTliMjEvK2poNVhvczFBblg1aUl0cmVHQ2M9DQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tDQoNCjwvY2E+DQoNCg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyBUaGUgY2xpZW50IGNlcnRpZmljYXRlIGZpbGUgKGR1bW15KS4NCiMgDQojIEluIHNvbWUgaW1wbGVtZW50YXRpb25zIG9mIE9wZW5WUE4gQ2xpZW50IHNvZnR3YXJlDQojIChmb3IgZXhhbXBsZTogT3BlblZQTiBDbGllbnQgZm9yIGlPUyksDQojIGEgcGFpciBvZiBjbGllbnQgY2VydGlmaWNhdGUgYW5kIHByaXZhdGUga2V5IG11c3QgYmUgaW5jbHVkZWQgb24gdGhlDQojIGNvbmZpZ3VyYXRpb24gZmlsZSBkdWUgdG8gdGhlIGxpbWl0YXRpb24gb2YgdGhlIGNsaWVudC4NCiMgU28gdGhpcyBzYW1wbGUgY29uZmlndXJhdGlvbiBmaWxlIGhhcyBhIGR1bW15IHBhaXIgb2YgY2xpZW50IGNlcnRpZmljYXRlDQojIGFuZCBwcml2YXRlIGtleSBhcyBmb2xsb3dzLg0KDQo8Y2VydD4NCi0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQ0KTUlJQ3hqQ0NBYTRDQVFBd0RRWUpLb1pJaHZjTkFRRUZCUUF3S1RFYU1CZ0dBMVVFQXhNUlZsQk9SMkYwWlVOcw0KYVdWdWRFTmxjblF4Q3pBSkJnTlZCQVlUQWtwUU1CNFhEVEV6TURJeE1UQXpORGswT1ZvWERUTTNNREV4T1RBeg0KTVRRd04xb3dLVEVhTUJnR0ExVUVBeE1SVmxCT1IyRjBaVU5zYVdWdWRFTmxjblF4Q3pBSkJnTlZCQVlUQWtwUQ0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUE1aDJsZ1FRWVVqd29LWUpielZaQQ0KNVZjSUdkNW90UGMvcVpSTXQwS0l0Q0ZBMHM5UndSZU5WYTlmRFJGTFJCaGNJVE9sdjNGQmNXM0U4aDFVczdSRA0KNFc4R21KZTh6YXBKbkxzRDM5T1NNUkN6WkpuY3pXNE9DSDFQWlJaV0txRHRqbE5jYTlBRjhhNjVqVG1sRHhDUQ0KQ2pudExJV2s1T0xMVmtGdDkvdFNjYzFHRHRjaTU1b2ZoYU5BWU1QaUg3VjgrMWc2NnBHSFhBb1dLNkFRVkg2Nw0KWENLSm5HQjVubFErSHNNWVBWL080OUxkOTFaTi8ydEhrY2FMTHlOdHl3eFZQUlNzUmg0ODBqanUwZmNDc3Y2aA0KcC8weVhuVEIvL21XdXRCR3BkVWxJYndpSVRiQW1yc2JZbmppZ1J2blBxWDFSTkpVYmk5RnA2QzJjL0hJRkpHRA0KeXdJREFRQUJNQTBHQ1NxR1NJYjNEUUVCQlFVQUE0SUJBUUNoTzVoZ2N3LzRvV2ZvRUZMdTlrQmExQi8va3hIOA0KaFFrQ2hWTm44QlJDN1kwVVJRaXRQbDNES0VlZDlVUkJEZGcyS09Bejc3YmI2RU5QaWxpRCthMzhVSkhJUk1xZQ0KVUJIaGxsT0hJenZEaEhGYmFvdkFMQlFjZWVCemRrUXhzS1FFU0ttUW1SODMyOTUwVUNvdm95UkI2MVV5QVY3aA0KK21aaFlQR1JLWEtTSkk2czBFZ2cvQ3JpK0N3azRiakpmcmI1aFZzZTExeWg0RDlNSGh3U2ZDT0grMHo0aFBVVA0KRmt1N2RHYXZVUk81U1Z4TW4vc0w2RW41RCtvU2VYa2FkSHBEcytBaXJ5bTJZSGgxNWgwK2pQU09vUjZ5aVZwLw0KNnpaZVprck40M2t1UzczS3BLREZqZkZQaDh0NHIxZ09JanR0a05jUXFCY2N1c25wbFE3SEpwc2sNCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0NCg0KPC9jZXJ0Pg0KDQo8a2V5Pg0KLS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQ0KTUlJRXBBSUJBQUtDQVFFQTVoMmxnUVFZVWp3b0tZSmJ6VlpBNVZjSUdkNW90UGMvcVpSTXQwS0l0Q0ZBMHM5Ug0Kd1JlTlZhOWZEUkZMUkJoY0lUT2x2M0ZCY1czRThoMVVzN1JENFc4R21KZTh6YXBKbkxzRDM5T1NNUkN6WkpuYw0Kelc0T0NIMVBaUlpXS3FEdGpsTmNhOUFGOGE2NWpUbWxEeENRQ2pudExJV2s1T0xMVmtGdDkvdFNjYzFHRHRjaQ0KNTVvZmhhTkFZTVBpSDdWOCsxZzY2cEdIWEFvV0s2QVFWSDY3WENLSm5HQjVubFErSHNNWVBWL080OUxkOTFaTg0KLzJ0SGtjYUxMeU50eXd4VlBSU3NSaDQ4MGpqdTBmY0NzdjZocC8weVhuVEIvL21XdXRCR3BkVWxJYndpSVRiQQ0KbXJzYlluamlnUnZuUHFYMVJOSlViaTlGcDZDMmMvSElGSkdEeXdJREFRQUJBb0lCQUVSVjdYNUF2eEE4dVJpSw0KazhTSXBzRDBkWDFwSk9NSXdha1VWeXZjNEVmTjBEaEtSTmI0cllvU2lFR1RMeXpMcHlCYy9BMjhEbGttNWVPWQ0KZmp6WGZZa0d0WWkvRnR4a2czTzl2Y3JNUTQrNmkrdUdIYUlMMnJMK3M0TXJmTzh2MXh2NitXa3kzM0VFR0NvdQ0KUWl3VkdSRlFYblJvUTYyTkJDRmJVTkxobVh3ZGoxYWtaekxVNHA1UjR6QTNRaGR4d0VJYXRWTHQwKzdvd0xRMw0KbFA4c2ZYaHBwUE9YalRxTUQ0UWtZd3pQQWE4L3pGN2FjbjRrcnlyVVA3UTZQQWZkMHpFVnFOeTlaQ1o5ZmZobw0KelhlZEZqNDg2SUZvYzVnblRwMk42anNuVmo0TENHSWhsVkhsWUdvektLRnFKY1FWR3NIQ3FxMW96MnpqVzZMUw0Kb1JZSUhnRUNnWUVBOHpacmtDd05ZU1hKdU9ESjNtL2hPTFZ4Y3hnSnV3WG9pRXJXZDBFNDJ2UGFuampWTWhudA0KS1k1bDhxR01KNkZoSzlMWXgycUNyZi9FMFh0VUFaMndWcTNPUlR5R25zTVdyZTl0TFlzNTVYK1pOMTBUYzc1eg0KNGhhY2JVMGhxS04xSGlEbXNNUlkzLzJOYVpIb3k3TUtud0pKQmFHNDhsOUNDVGxWd01Ib2NJRUNnWUVBOGpieQ0KZEdqeFRIKzZYSFdOaXpiNVNSYlp4QW55RWVKZVJ3VE1oMGdHendHUHBIL3NaWUd6eXUwU3lTWFdDblpoM1JncQ0KNXVMbE54dHJYcmxqWmx5aTJuUWRRZ3NxMllyV1VzMCt6Z1UrMjJ1UXNacFNBZnRtaFZydHZldDZNalZqYkJ5WQ0KREFEY2lFVlVkSllJWGsrcW5GVUp5ZXJvTElrVGo3V1lLWjZSamtzQ2dZQm9DRkl3UkRlZzQyb0s4OVJGbW5Pcg0KTHltTkFxNCsyb01oc1dsVmI0ZWpXSVdlQWs5bmMrR1hVZnJYc3pSaFMwMW1VblU1cjV5Z1V2UmNhclYvVDNVNw0KVG5NWitJN1k0RGdXUklEZDUxem5oeElCdFlWNWovQy90ODVIanFPa0grOGI2UlRrYmNoYVgzbWF1N2ZwVWZkcw0KRnEwbmhJcTQyZmhFTzhzcmZZWXdnUUtCZ1FDeWhpMU4vOHRhUndwayszL0lERXpRd2piZmR6VWtXV1NEazlYcw0KSC9wa3VSSFdmVE1QM2ZsV3FFWWdXL0xXNDBwZVcySERxNWltZFY4K0FnWnhlL1hNYmFqaTlMZ3dmMVJZMDA1bg0KS3hhWlF6N3lxSHVwV2xMR0Y2OERQSHhrWlZWU2FnRG5WL3N6dFdYNlNGc0NxRlZueElYaWZYR0M0Y1c1Tm05Zw0KdmE4cTRRS0JnUUNFaExWZVVmZHdLdmtaOTRnL0dGejczMVoyaHJkVmhnTVphVS91NnQwVjk1K1llelBOQ1FaQg0Kd21FOU1tbGJxMWVtRGVST2l2akNmb0doUjNrWlhXMXBUS2xMaDZaTVVRVU9wcHRkWHZhOFh4Zm9xUXdhM2VuQQ0KTTdtdUJiRjBYTjdWTzgwaUpQditQbUlaZEVJQWtwd0tmaTIwMVlCK0JhZkNJdUd4SUY1MFZnPT0NCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tDQoNCjwva2V5Pg==', 'vpn', 'vpn', 0, 1, '2025-12-24 07:11:13', '2025-12-25 04:15:39');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `pakage_name` varchar(255) DEFAULT NULL,
  `price` varchar(255) DEFAULT NULL,
  `validity` varchar(255) DEFAULT NULL,
  `expired_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `user_id`, `name`, `email`, `pakage_name`, `price`, `validity`, `expired_date`, `status`, `created_at`, `updated_at`) VALUES
(75, 66, 'test', 'test@gmail.com', '30 days', '30', '30', '2026-01-23 08:18:46', 'success', '2025-12-24 01:58:49', '2025-12-24 08:18:46');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `device_id` varchar(255) DEFAULT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `device_id`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(40, 'App\\Models\\User', 11, 'user_token', NULL, '687757b2db849bdf4c932b9b1cb9f7923b381217ae5f1ecbe2ba3ec9d1abf9c2', '[\"*\"]', NULL, NULL, '2025-05-20 11:46:32', '2025-05-20 11:46:32'),
(41, 'App\\Models\\User', 11, 'device_token', 'last', '4537c0f12cd2a2699091279506ee65c71b6fb2abebf4c185f9e6f7857625c1bd', '[\"*\"]', NULL, NULL, '2025-05-20 11:54:27', '2025-05-20 11:54:27'),
(42, 'App\\Models\\User', 12, 'user_token', NULL, '8e6cdd3d2a8d1a57a86e1d9abaac9841d14f20360df467eff6e1be306e1ca9ea', '[\"*\"]', NULL, NULL, '2025-05-20 11:56:01', '2025-05-20 11:56:01'),
(43, 'App\\Models\\User', 12, 'device_token', 'laster', 'd7c556f1d4973c9e5743942c42af08319396f58434c6d1c782ae08c663d53541', '[\"*\"]', NULL, NULL, '2025-05-20 11:56:33', '2025-05-20 11:56:33'),
(44, 'App\\Models\\User', 12, 'device_token', 'lasteru', '70a8cbb1be91caf01642bb4648a456c4314274fb7c4573049f7cb0596277c93d', '[\"*\"]', NULL, NULL, '2025-05-20 11:57:44', '2025-05-20 11:57:44'),
(45, 'App\\Models\\User', 9, 'device_token', 'lasteru', '2ffb06621f26ceffe7c4385a9c5a47656e786b25b1304feea12ffb9578929f1a', '[\"*\"]', NULL, NULL, '2025-05-20 11:58:12', '2025-05-20 11:58:12'),
(46, 'App\\Models\\User', 13, 'user_token', NULL, 'c78b99e66131bc1811d3e7e1c744a48ee578b503a3060a94f03bf5981d3e7238', '[\"*\"]', NULL, NULL, '2025-05-20 12:00:23', '2025-05-20 12:00:23'),
(48, 'App\\Models\\User', 13, 'device_token', 'lasteru', '8ef33c92668eeb186b73de2ada50b0882e8db02540f95e2365195bfb6b9e1bf7', '[\"*\"]', NULL, NULL, '2025-05-20 12:01:52', '2025-05-20 12:01:52'),
(51, 'App\\Models\\User', 13, 'device_token', '1', 'db97f848b275d3abd0d03278a607cbe7fa0061048db6ffd8d399e8e8a97170c5', '[\"*\"]', NULL, NULL, '2025-05-20 16:15:19', '2025-05-20 16:15:19'),
(53, 'App\\Models\\User', 13, 'device_token', '2', '6865d1c2b7abb36c024717861e310b3161a25ecf1026574a5ab2cb4e12247b7e', '[\"*\"]', NULL, NULL, '2025-05-20 16:15:55', '2025-05-20 16:15:55'),
(54, 'App\\Models\\User', 14, 'user_token', NULL, 'd0ef3ab4f017c86fef9554bb8937b03ad21955905952ed1bb4e1a3a3345475d8', '[\"*\"]', NULL, NULL, '2025-05-20 16:16:14', '2025-05-20 16:16:14'),
(56, 'App\\Models\\User', 14, 'device_token', '2', 'cf812c7aa42570fce7e08d1da5ef2151a940e90e2ca11afd9cca42f5eff62aa9', '[\"*\"]', NULL, NULL, '2025-05-20 16:16:44', '2025-05-20 16:16:45'),
(57, 'App\\Models\\User', 15, 'user_token', NULL, 'db307af5b76718f627028e5fa3a37006df4d7e6527afdddabd6e41994443735b', '[\"*\"]', '2025-05-23 07:07:14', NULL, '2025-05-23 07:06:58', '2025-05-23 07:07:14'),
(58, 'App\\Models\\User', 16, 'user_token', NULL, '5221d1d521b6b343685315391285992ef09698f68dad1e24960a46c84dc100df', '[\"*\"]', NULL, NULL, '2025-06-18 02:32:41', '2025-06-18 02:32:41'),
(59, 'App\\Models\\User', 16, 'device_token', 'lasteru', 'a386580d85d1ed23fe9d4d5d7493e5e64a23ac3a867155c1ff4efc71b1c3afa4', '[\"*\"]', '2025-06-18 02:34:40', NULL, '2025-06-18 02:32:54', '2025-06-18 02:34:40'),
(60, 'App\\Models\\User', 17, 'user_token', NULL, 'cc2cba403d0f148865c4e643a75cb0cd9bd76dee9e75c380c6711f9ee3d9f89e', '[\"*\"]', NULL, NULL, '2025-06-19 13:14:56', '2025-06-19 13:14:56'),
(61, 'App\\Models\\User', 17, 'device_token', 'ca32f4708438ea77', '614d50c40eefb0dbeabe75d8d8189925935deee3169a8c6a67f86cc3902baa7d', '[\"*\"]', '2025-06-22 11:40:00', NULL, '2025-06-19 14:14:44', '2025-06-22 11:40:00'),
(64, 'App\\Models\\User', 4, 'device_token', 'e74acd0661a0ad3d', 'c2aacee22f7d8314714434f30d01b9669edb0191fcf872fc8fba3753b7c9e329', '[\"*\"]', '2025-06-21 09:33:54', NULL, '2025-06-21 09:30:40', '2025-06-21 09:33:54'),
(66, 'App\\Models\\User', 4, 'device_token', 'test', 'b6b90d689dae656a0b742e1844b6b08d156b5e65e5b21c17a757a9ab64a87ab1', '[\"*\"]', '2025-06-23 15:06:18', NULL, '2025-06-23 14:57:26', '2025-06-23 15:06:18'),
(67, 'App\\Models\\User', 17, 'device_token', 'fa0c8561c09eddf5', '9ba67f32cf0262ccf50bb70ccc1f43df14d35baa82049beda40994e9220919a5', '[\"*\"]', '2025-06-25 09:46:48', NULL, '2025-06-25 09:46:48', '2025-06-25 09:46:48'),
(68, 'App\\Models\\User', 18, 'user_token', NULL, '6fca38df48603a13394f4ee0599c1ca5162fa2734670184680b368afc331201d', '[\"*\"]', NULL, NULL, '2025-06-25 09:47:48', '2025-06-25 09:47:48'),
(69, 'App\\Models\\User', 18, 'device_token', 'd9372f45ecb4b7b9', 'ae7af095da3eee149315376357a60d7470d359cfe62b579f518a30fbced5e672', '[\"*\"]', '2025-09-23 05:33:25', NULL, '2025-06-25 09:48:23', '2025-09-23 05:33:25'),
(70, 'App\\Models\\User', 19, 'user_token', NULL, 'adc5376bc5ebd1463673d2fadacc290038f9e2af1e6af2d5f29d15173e56ce61', '[\"*\"]', '2025-07-11 10:56:35', NULL, '2025-07-02 20:09:22', '2025-07-11 10:56:35'),
(71, 'App\\Models\\User', 19, 'device_token', '8f8b1af889250906', 'ee335b15b1ab2da2864dc102d65716cdfd166cc04b7ba3a8475e441f57294f62', '[\"*\"]', '2025-07-03 05:01:50', NULL, '2025-07-03 02:11:49', '2025-07-03 05:01:50'),
(73, 'App\\Models\\User', 19, 'device_token', '0a49ffc5a66a1e8a', 'd7333872b660b698b10ac6f7eae2fcc878e2cbe94e57d6b86ed660b8d75a8379', '[\"*\"]', '2025-07-04 02:48:06', NULL, '2025-07-04 02:06:29', '2025-07-04 02:48:06'),
(74, 'App\\Models\\User', 19, 'device_token', '34b9f444c6eeec3d', 'f0fb2c52a33055a4aff0ef731ba34b5166d150258aee5e466bffb79b6c3e0c06', '[\"*\"]', '2025-07-05 13:46:04', NULL, '2025-07-05 10:35:51', '2025-07-05 13:46:04'),
(75, 'App\\Models\\User', 20, 'user_token', NULL, 'e0186fb6169734a65cc5341eadfd2236ba663de8bd08a69a642e2748d16baba9', '[\"*\"]', '2025-07-05 14:27:59', NULL, '2025-07-05 14:22:26', '2025-07-05 14:27:59'),
(76, 'App\\Models\\User', 21, 'user_token', NULL, 'ad1e87fd7800e3102dcb05b25f65a3112c56cb3559b639970d2d65e2b953a90e', '[\"*\"]', '2025-07-12 07:25:31', NULL, '2025-07-12 05:01:38', '2025-07-12 07:25:31'),
(77, 'App\\Models\\User', 22, 'user_token', NULL, '8b334621fccccb7d7ea4dc3a1e904d389e07ca8874a90595b4001d71963dd7de', '[\"*\"]', '2025-07-16 14:33:58', NULL, '2025-07-16 14:33:58', '2025-07-16 14:33:58'),
(79, 'App\\Models\\User', 22, 'device_token', 'e74acd0661a0ad3d', 'd25f3a9a4eb238ff40b7b220b69db2852503e4b566a34a1380d8b8ed3c716de8', '[\"*\"]', '2025-07-16 16:28:45', NULL, '2025-07-16 14:42:46', '2025-07-16 16:28:45'),
(80, 'App\\Models\\User', 23, 'user_token', NULL, '9e2834a5f0a4bada3d9f7a4dafd4100040cc60efc15990583f81b6e07193efef', '[\"*\"]', NULL, NULL, '2025-09-06 03:43:09', '2025-09-06 03:43:09'),
(81, 'App\\Models\\User', 24, 'user_token', NULL, '0184f361f2b34ee7353d8c3e2b2240eb3356d6d3dd8f79abf16e39f068201a25', '[\"*\"]', '2025-09-11 10:10:27', NULL, '2025-09-06 10:11:33', '2025-09-11 10:10:27'),
(82, 'App\\Models\\User', 24, 'device_token', '1', '3b852dbb726fe3b47453caedccf648e4ccf58db238b4c8a45ecee3d52e506ddd', '[\"*\"]', NULL, NULL, '2025-09-06 10:31:21', '2025-09-06 10:31:21'),
(83, 'App\\Models\\User', 25, 'user_token', NULL, '81b836881017db7ebe9813ff91d4aae7b4adc35a969cee15c235dcd4578b24ed', '[\"*\"]', NULL, NULL, '2025-09-06 21:56:36', '2025-09-06 21:56:36'),
(84, 'App\\Models\\User', 26, 'user_token', NULL, '3e6ffdba1192fcb29734952f3d4b9ac5263d7e6e20d61907ade8aeac41d64bb6', '[\"*\"]', NULL, NULL, '2025-09-06 23:24:11', '2025-09-06 23:24:11'),
(85, 'App\\Models\\User', 27, 'user_token', NULL, '6d351bc7fe865d50450020b04ec3b3269e759c9abfca0cc7a70c9d279ff6e889', '[\"*\"]', NULL, NULL, '2025-09-06 23:36:51', '2025-09-06 23:36:51'),
(87, 'App\\Models\\User', 28, 'user_token', NULL, '6cdf85ea83239f1d8414f1d15016a37610aafb4b4ce3de334d3b0abf4376b81d', '[\"*\"]', NULL, NULL, '2025-09-08 21:46:38', '2025-09-08 21:46:38'),
(88, 'App\\Models\\User', 29, 'user_token', NULL, '1c301e496f5a619a03051ee7dda60b1e9d0e2428c39938caec9aabb39c21cc45', '[\"*\"]', NULL, NULL, '2025-09-10 09:50:03', '2025-09-10 09:50:03'),
(90, 'App\\Models\\User', 29, 'device_token', '1', 'e2521fe6bbc0e3e6b54639a7357c1db12d237d55517a4493741d39d6854c08da', '[\"*\"]', '2025-09-11 10:28:11', NULL, '2025-09-11 08:44:27', '2025-09-11 10:28:11'),
(92, 'App\\Models\\User', 19, 'device_token', 'efd1a8c86e8b15e3', '09b6d98a7ec6771b2895baee1c1c09cd5d80d545b1b9a588b8b3ff4a2c67090d', '[\"*\"]', '2025-09-15 08:56:16', NULL, '2025-09-15 07:37:09', '2025-09-15 08:56:16'),
(95, 'App\\Models\\User', 19, 'device_token', '4ac2608d1db8cd77', '351d0898e931a711c334ae8645a4f6dd8b96f31fdc4423e53ead7e56afeadafb', '[\"*\"]', '2025-09-16 00:09:23', NULL, '2025-09-15 23:29:14', '2025-09-16 00:09:23'),
(97, 'App\\Models\\User', 30, 'user_token', NULL, 'c08722895851bc6ea5ed55f33f6ed73d07a64f80ad1f68f9f2b6e0c053c63a1d', '[\"*\"]', NULL, NULL, '2025-09-16 04:43:31', '2025-09-16 04:43:31'),
(98, 'App\\Models\\User', 30, 'device_token', 'cdc7f5c820be929b', 'b77d91f5ea524c01ed8a71a261ffcc73bf3822283b7faefa374c6c745ddf2422', '[\"*\"]', '2025-09-16 04:44:18', NULL, '2025-09-16 04:43:40', '2025-09-16 04:44:18'),
(99, 'App\\Models\\User', 31, 'user_token', NULL, '41b55d02f56d30e430a74c1fd47257c9f97bf1d0222f25c2245a6fe69b699473', '[\"*\"]', NULL, NULL, '2025-09-18 04:57:47', '2025-09-18 04:57:47'),
(100, 'App\\Models\\User', 32, 'user_token', NULL, 'bb6f32332520e95a72af54c21ed5d00a32a18b6af4e864b85c8a89a74ba25294', '[\"*\"]', NULL, NULL, '2025-09-18 05:00:43', '2025-09-18 05:00:43'),
(102, 'App\\Models\\User', 19, 'device_token', '12', 'd35b0140aee09fb5e20f91436fc6b665bc05c093c32838b58594b14f5fe65089', '[\"*\"]', '2025-09-18 05:01:56', NULL, '2025-09-18 05:01:42', '2025-09-18 05:01:56'),
(103, 'App\\Models\\User', 33, 'user_token', NULL, 'd0fdde107af2b3d3457a252866d10e30488c7324d0c5ff93246772f2f685dcd8', '[\"*\"]', NULL, NULL, '2025-09-18 06:37:45', '2025-09-18 06:37:45'),
(104, 'App\\Models\\User', 33, 'device_token', 'b53f91f13ab6b04e', '1a37da8b2b3c2743d4e53689adf1f0e29dca60a440cbc3375f209389eed142dc', '[\"*\"]', '2025-09-18 06:39:46', NULL, '2025-09-18 06:37:58', '2025-09-18 06:39:46'),
(105, 'App\\Models\\User', 34, 'user_token', NULL, '80b501288ce8717077a89736fd919f3bcf78218d0f6e35d3ef6664b45dd01e2e', '[\"*\"]', NULL, NULL, '2025-09-18 07:43:55', '2025-09-18 07:43:55'),
(106, 'App\\Models\\User', 34, 'device_token', '8229eee31aa9f0ce', 'a77c4454cb2e2b64cb9a332426669c68a96825149a77cf884b31c5b26975b3cb', '[\"*\"]', '2025-09-18 10:51:02', NULL, '2025-09-18 07:44:16', '2025-09-18 10:51:02'),
(107, 'App\\Models\\User', 35, 'user_token', NULL, 'c924c1a304d898084682bdcd8bfb4de839c773872be2973eb831a372dfbc825e', '[\"*\"]', NULL, NULL, '2025-09-18 22:27:32', '2025-09-18 22:27:32'),
(108, 'App\\Models\\User', 35, 'device_token', '51ee573556af45c5', 'cac33ceb3fe9afcb37a7727e0e53e5c5acd75a92e460af091f7f6f9a9079fbe5', '[\"*\"]', '2025-09-18 22:34:23', NULL, '2025-09-18 22:27:47', '2025-09-18 22:34:23'),
(109, 'App\\Models\\User', 32, 'device_token', '0a49ffc5a66a1e8a', '743139aea5fa508874714570c95237aede52e5ad44e7f130b3300bf5681ce187', '[\"*\"]', '2025-09-19 04:43:56', NULL, '2025-09-19 03:46:35', '2025-09-19 04:43:56'),
(110, 'App\\Models\\User', 32, 'device_token', '4ac2608d1db8cd77', '0fbac9757ec8386e3698994ef283d29f9b914345d2206e2e3e21e1d309785458', '[\"*\"]', '2025-09-21 15:08:41', NULL, '2025-09-19 13:21:47', '2025-09-21 15:08:41'),
(111, 'App\\Models\\User', 36, 'user_token', NULL, 'f39dd31b6f4d71fcf4d44a3d45c6b5f1157700a35f3e8874a622bdbcf4236da1', '[\"*\"]', NULL, NULL, '2025-09-20 13:58:59', '2025-09-20 13:58:59'),
(112, 'App\\Models\\User', 36, 'device_token', '64d86a166521aed2', '1e18c7ae5ddfbdeb4b596fe2281dd005cf0e3b5ef9a945582dbb5fbdf1d2f565', '[\"*\"]', '2025-09-20 13:59:36', NULL, '2025-09-20 13:59:09', '2025-09-20 13:59:36'),
(113, 'App\\Models\\User', 37, 'user_token', NULL, '35a7e4ade8f464d62da7455c2f92df8c6486f540164646190d7a88b0657e32a5', '[\"*\"]', '2025-09-23 02:15:55', NULL, '2025-09-23 02:13:52', '2025-09-23 02:15:55'),
(114, 'App\\Models\\User', 19, 'device_token', 'df55c80ef18ecfa3', 'a32cc8db21c1552db422a76b68129761bcd15392e2a02f66af4bfd7616658e29', '[\"*\"]', '2025-09-23 02:23:03', NULL, '2025-09-23 02:20:58', '2025-09-23 02:23:03'),
(115, 'App\\Models\\User', 41, 'user_token', NULL, '4c6ce9180ca762a2bddcf5185acfb28026a87a6a4261589b416ef04fe5b18dff', '[\"*\"]', NULL, NULL, '2025-09-23 09:45:44', '2025-09-23 09:45:44'),
(116, 'App\\Models\\User', 41, 'device_token', '1', 'a31cb42ae9008676042d9dc32dc437274af2d77f416be13ba0687103eb3a7aec', '[\"*\"]', '2025-09-23 09:53:02', NULL, '2025-09-23 09:46:10', '2025-09-23 09:53:02'),
(117, 'App\\Models\\Admin', 1, 'API TOKEN', NULL, '50907f526ecf7e2140d1fc4252f37ae15134fa7108fd9d7e0d49a1d06dcad5a0', '[\"*\"]', NULL, NULL, '2025-09-23 09:57:00', '2025-09-23 09:57:00'),
(118, 'App\\Models\\Admin', 1, 'API TOKEN', NULL, '258bab2cc071d3fd90fb19b74cad152d4f459238e66ef0dc8ddd839a7c64600d', '[\"*\"]', NULL, NULL, '2025-09-23 09:57:16', '2025-09-23 09:57:16'),
(119, 'App\\Models\\Admin', 1, 'API TOKEN', NULL, '810cd94bf51a8d977cb4f0900c2f53076a0ea41880db70576f906bdd2f29d8ff', '[\"*\"]', NULL, NULL, '2025-09-23 10:02:06', '2025-09-23 10:02:06'),
(120, 'App\\Models\\User', 42, 'user_token', NULL, 'badfe90a2ca76ffc0f23f66e2a4365c70de488599276678ce3393535fde92397', '[\"*\"]', NULL, NULL, '2025-09-23 18:08:02', '2025-09-23 18:08:02'),
(122, 'App\\Models\\User', 42, 'device_token', '1', '32238a37d9ad6afa4bea807a71ab37212adcb52a5cfc9a1cd433bb0def5e9df6', '[\"*\"]', '2025-09-23 18:40:42', NULL, '2025-09-23 18:13:47', '2025-09-23 18:40:42'),
(123, 'App\\Models\\User', 43, 'user_token', NULL, 'afcf2142e31506c40c33d6c442a17b73a6a1136868fcf295e716bc3aab33ac90', '[\"*\"]', NULL, NULL, '2025-09-24 22:39:13', '2025-09-24 22:39:13'),
(124, 'App\\Models\\User', 44, 'user_token', NULL, 'bae5f8f8465f950cb7d942df5b56e01270d4bc478f971aeca16ac4c8b5025ca4', '[\"*\"]', NULL, NULL, '2025-11-04 08:51:56', '2025-11-04 08:51:56'),
(125, 'App\\Models\\User', 44, 'device_token', '1', 'f9733d8c0b43eea54b95a88e475908bbbbfd1d38a4f45ed33927c07022b9d6e6', '[\"*\"]', '2025-11-04 09:47:59', NULL, '2025-11-04 08:52:08', '2025-11-04 09:47:59'),
(126, 'App\\Models\\User', 27, 'device_token', '1', '18ba45aa18d4b4b799b67e4abe8ce9e9712d8e117a305e5e845bc0474889deb5', '[\"*\"]', NULL, NULL, '2025-11-04 09:50:42', '2025-11-04 09:50:42'),
(127, 'App\\Models\\User', 45, 'user_token', NULL, 'd04ca443da8f8a7aba03e7d02b242eb2b5c92f4a0a4a3ee7a44fd4fe67c34226', '[\"*\"]', NULL, NULL, '2025-11-04 09:51:12', '2025-11-04 09:51:12'),
(129, 'App\\Models\\User', 45, 'device_token', '1', '70b5df560701ca17556f562edb931af6e466d0a5b1a34dd35ac4010cf9d61842', '[\"*\"]', NULL, NULL, '2025-11-06 06:08:12', '2025-11-06 06:08:13'),
(130, 'App\\Models\\User', 46, 'user_token', NULL, '8a768adb99442089be86fa85845925418f043be6b902bcf33dc6d7aececa2c54', '[\"*\"]', '2025-11-06 06:13:04', NULL, '2025-11-06 06:09:07', '2025-11-06 06:13:04'),
(131, 'App\\Models\\User', 47, 'user_token', NULL, '7482b0ceba8e09dc972214e74b03784bef2ce70ea2b17d716c06c6bed3a95f39', '[\"*\"]', '2025-11-11 02:05:24', NULL, '2025-11-11 00:44:57', '2025-11-11 02:05:24'),
(132, 'App\\Models\\User', 48, 'user_token', NULL, '43915f8efee39b3eaa78a50e01e0320a6f8e63fd2aea90fc2a3fa93db9296214', '[\"*\"]', NULL, NULL, '2025-11-11 09:53:56', '2025-11-11 09:53:56'),
(133, 'App\\Models\\User', 48, 'device_token', '89c87f6a13146163', '26f95596174d9e974ddfa9e880a7818513e9cdd264bc70829c9b43b2628b9758', '[\"*\"]', '2025-11-11 11:01:22', NULL, '2025-11-11 09:53:57', '2025-11-11 11:01:22'),
(134, 'App\\Models\\User', 49, 'user_token', NULL, '1910b143f7ebd879ba0768e77ec5e78ab0fd511e25bc950a71f6a502bdddfb5b', '[\"*\"]', NULL, NULL, '2025-11-11 14:24:25', '2025-11-11 14:24:25'),
(135, 'App\\Models\\User', 49, 'device_token', '4ac2608d1db8cd77', 'edcd111efd501dc7ed8711cd4e94749c938e37158c59933c37059d880a65f92e', '[\"*\"]', '2025-11-12 02:18:16', NULL, '2025-11-11 14:24:26', '2025-11-12 02:18:16'),
(136, 'App\\Models\\User', 50, 'user_token', NULL, '86412a8e1dbbae35c478b042b39a0f74706ef87e111c4e1473378df9912a3265', '[\"*\"]', NULL, NULL, '2025-11-13 07:07:03', '2025-11-13 07:07:03'),
(137, 'App\\Models\\User', 50, 'device_token', '59107a30228d9e9b', '12615eb42e3a866e268aceb3d831e5106000235e7a025520b841e6262b3a5f70', '[\"*\"]', '2025-11-21 16:24:33', NULL, '2025-11-13 07:07:04', '2025-11-21 16:24:33'),
(138, 'App\\Models\\User', 51, 'user_token', NULL, '54291b9c192ab5e6f64bbed1fce8f85b7463d61bcc3124171dc3579b5492612d', '[\"*\"]', NULL, NULL, '2025-11-13 08:35:52', '2025-11-13 08:35:52'),
(139, 'App\\Models\\User', 51, 'device_token', 'eaac2eb9bce8ca58', '5067caf91c3c3cf0277a9354e7870bc86cfbcfef5612452d65be2445ac0f5dd5', '[\"*\"]', '2025-11-13 08:36:46', NULL, '2025-11-13 08:35:53', '2025-11-13 08:36:46'),
(140, 'App\\Models\\User', 52, 'user_token', NULL, '891e209d3763e6b07a37afa6f155d832ec06c01ce12feb4abfe44ad7f85f0625', '[\"*\"]', NULL, NULL, '2025-11-13 16:29:26', '2025-11-13 16:29:26'),
(141, 'App\\Models\\User', 52, 'device_token', '64d86a166521aed2', 'eda71a629a14c8c9f3e1645fe33f1c530d13a2cebee31bf3f8b81dd5f25d8449', '[\"*\"]', '2025-11-13 17:19:30', NULL, '2025-11-13 16:29:27', '2025-11-13 17:19:30'),
(142, 'App\\Models\\User', 53, 'user_token', NULL, '8255984805687fedcb34c056b55e5028eb092e87b80088ee6148d5a772871da5', '[\"*\"]', NULL, NULL, '2025-11-17 08:43:44', '2025-11-17 08:43:44'),
(143, 'App\\Models\\User', 53, 'device_token', '3c2e56242af160fc', '9036db9c9b339dfb6373b22d5fc5ae3890d997ecd3aba06f8c151f9373c303e9', '[\"*\"]', '2025-11-17 08:46:18', NULL, '2025-11-17 08:43:44', '2025-11-17 08:46:18'),
(144, 'App\\Models\\User', 54, 'user_token', NULL, '443705d206acf35dbee1231ec9f00dfc674a8b38926994094133597c7a0b7b26', '[\"*\"]', NULL, NULL, '2025-11-17 12:10:22', '2025-11-17 12:10:22'),
(145, 'App\\Models\\User', 55, 'user_token', NULL, '0fb2cdc81dd9ac7d76b351f2725eb34406e0ca95d16035de0afad27403c6deea', '[\"*\"]', NULL, NULL, '2025-11-18 10:26:56', '2025-11-18 10:26:56'),
(146, 'App\\Models\\User', 55, 'device_token', 'da204f0713345918', 'c21ea4be0b3d8c406ff501a57b80eff47083c04d6bf4e5d07db1a73534ec8347', '[\"*\"]', '2025-11-19 18:48:31', NULL, '2025-11-18 10:26:57', '2025-11-19 18:48:31'),
(147, 'App\\Models\\User', 56, 'user_token', NULL, '4a1c91f3bef8ac0bd34362880a3fd89cd85b83ab248de4d19f7742dcf2de12c0', '[\"*\"]', NULL, NULL, '2025-11-18 18:56:05', '2025-11-18 18:56:05'),
(148, 'App\\Models\\User', 56, 'device_token', '53601ea64690c1cd', 'f501f991205f556d423fe712dc6ff9adcfd2a924d02c4cf194046ecebe4a8bbb', '[\"*\"]', '2025-11-18 18:58:41', NULL, '2025-11-18 18:56:05', '2025-11-18 18:58:41'),
(149, 'App\\Models\\User', 57, 'user_token', NULL, '54ccf93f6347b36d35d9491add32565356a384dc0ab89c6e77c83b03c05502f0', '[\"*\"]', NULL, NULL, '2025-11-19 06:41:06', '2025-11-19 06:41:06'),
(150, 'App\\Models\\User', 57, 'device_token', '53601ea64690c1cd', 'a91ad3892cd46edfa5ed72ea390fae9e38c6e2f0498d6823dafc846f57362f38', '[\"*\"]', '2025-11-19 06:44:56', NULL, '2025-11-19 06:41:07', '2025-11-19 06:44:56'),
(151, 'App\\Models\\User', 49, 'device_token', 'de65831a0eee391c', '311a5e3bec9b43bb3c624d7992875412fbbd359a64ac39efd595eec1ef945289', '[\"*\"]', '2025-11-19 12:20:11', NULL, '2025-11-19 12:19:13', '2025-11-19 12:20:11'),
(152, 'App\\Models\\User', 58, 'user_token', NULL, 'b3d2166b2e1484564ce79cfd6454075a5917df78441ee56b6c51962718cdaf59', '[\"*\"]', NULL, NULL, '2025-11-20 13:07:14', '2025-11-20 13:07:14'),
(153, 'App\\Models\\User', 58, 'device_token', 'd0eda5b846dacd9a', 'e18a2f7b5c5657f1ecb2271d9b69811207ef63ef519397c8382d524c170aa43a', '[\"*\"]', '2025-11-20 13:08:24', NULL, '2025-11-20 13:07:15', '2025-11-20 13:08:24'),
(154, 'App\\Models\\User', 59, 'user_token', NULL, '257b0d13ec3f24e3cfdcf011b7cd5d343defbf306948b234e1b409b46f306a4a', '[\"*\"]', NULL, NULL, '2025-11-20 19:49:51', '2025-11-20 19:49:51'),
(155, 'App\\Models\\User', 59, 'device_token', '4ac2608d1db8cd77', '886e0dc2ef859b008d2cad1425b8958b2f9c15312c8e79f1715d32c4bc681159', '[\"*\"]', '2025-11-20 20:10:26', NULL, '2025-11-20 19:49:52', '2025-11-20 20:10:26'),
(156, 'App\\Models\\User', 60, 'user_token', NULL, '76aa95030cc8bfcadd876af583edc506bbc1c4ed136b38d495c5b15f69aaf5e7', '[\"*\"]', NULL, NULL, '2025-11-21 04:52:29', '2025-11-21 04:52:29'),
(157, 'App\\Models\\User', 60, 'device_token', 'cf33f29e0293c345', '09cf46ad96e401bdb40d0170f5845398b1170db333a580dc6dcc3cfc3541ab1d', '[\"*\"]', '2025-11-22 04:20:21', NULL, '2025-11-21 04:52:30', '2025-11-22 04:20:21'),
(158, 'App\\Models\\User', 61, 'user_token', NULL, '0defd1a87e875b585e60b4fa4f2559322f7c029f6b9053384dbe201fb4f1076e', '[\"*\"]', NULL, NULL, '2025-11-23 03:26:16', '2025-11-23 03:26:16'),
(159, 'App\\Models\\User', 61, 'device_token', '770d66c072477a9f', '0be4e5f7d7476769dcbc2d16c42d5d29493e1e3e0726431ad5005a6c31cf94a0', '[\"*\"]', '2025-11-23 03:33:16', NULL, '2025-11-23 03:26:17', '2025-11-23 03:33:16'),
(160, 'App\\Models\\User', 62, 'user_token', NULL, '135a05910e2b5d0c2502c83e263f0995f35157a7fd1a543ff537a75c67481267', '[\"*\"]', NULL, NULL, '2025-11-24 17:09:39', '2025-11-24 17:09:39'),
(161, 'App\\Models\\User', 62, 'device_token', 'f4831af9fa6be831', '334ecfd976c85d7ec380503d184cfe156377f1e42b56c5379397336b313d5eb9', '[\"*\"]', '2025-11-28 00:06:43', NULL, '2025-11-24 17:09:40', '2025-11-28 00:06:43'),
(162, 'App\\Models\\User', 63, 'user_token', NULL, '1711be95f1c9e57b33a8959b3b1c899e0b7985d20fe3dab37d85f9c2edfd91df', '[\"*\"]', NULL, NULL, '2025-11-27 02:43:39', '2025-11-27 02:43:39'),
(163, 'App\\Models\\User', 63, 'device_token', '58025b477190fbc0', '286f48625e1fee00193ed60e088275de58bebcc8e3fd86f89a59bbe7580e4ed7', '[\"*\"]', '2025-11-27 08:01:55', NULL, '2025-11-27 02:43:39', '2025-11-27 08:01:55'),
(164, 'App\\Models\\User', 64, 'user_token', NULL, '24c5b716b87ffb1756af4098d46c5eb88cff36d74b2ba6818e0d9d36faeac27a', '[\"*\"]', NULL, NULL, '2025-11-29 17:35:10', '2025-11-29 17:35:10'),
(168, 'App\\Models\\User', 64, 'device_token', '2c2c20c2f75844c5', '116769d0aaf35d272879e83e6b33a4bb81ece79df216da60ef73c16ef6408eea', '[\"*\"]', '2025-12-01 09:17:08', NULL, '2025-11-30 17:27:26', '2025-12-01 09:17:08'),
(169, 'App\\Models\\User', 65, 'user_token', NULL, '012d4c4209eea8a3da6cf121ac2b88c1b4d5c3028be0c54e9d9d6dffa03384b6', '[\"*\"]', '2025-12-23 22:38:38', NULL, '2025-12-23 22:34:44', '2025-12-23 22:38:38'),
(171, 'App\\Models\\User', 65, 'device_token', 'nahid-device', 'e47fb4557b80c360cd2f79bc7caf9a7259af964b1ae18c3ba2ca30633f142f49', '[\"*\"]', '2025-12-23 23:41:14', NULL, '2025-12-23 23:40:01', '2025-12-23 23:41:14'),
(172, 'App\\Models\\User', 66, 'user_token', NULL, '4d887bced508f82b4b1ad99c82023b91bdff06d3f52c9fea9ca20e150fef763c', '[\"*\"]', NULL, NULL, '2025-12-24 01:56:56', '2025-12-24 01:56:56'),
(176, 'App\\Models\\User', 66, 'device_token', 'test', '794f3fdd727b930f1aa273cbdbd7254a3cb1cbb239a60a07ea86511c2ad25e86', '[\"*\"]', '2025-12-25 00:06:51', NULL, '2025-12-24 22:16:04', '2025-12-25 00:06:51'),
(180, 'App\\Models\\User', 66, 'device_token', '142ad0f2c7d3d537', '0af6c8e58801a1653615448cbe05d97bfb5a52bd62358599cdd04803c894b0c0', '[\"*\"]', '2025-12-25 04:26:01', NULL, '2025-12-25 04:19:33', '2025-12-25 04:26:01');

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('WorvuR7DTCemfZIiYO9clPFC2nV3nro19zz950ix', NULL, '103.92.154.146', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', 'YTo2OntzOjY6Il90b2tlbiI7czo0MDoiNHMxRXFKMGl5TE9VMHVYaG5aRHlBS3oySk05dVZaRVl4d3JPdjNYUiI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly92cG4uY2hhZG5pY2hvay5jb20vYWRtaW4vZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czoxMDoic2hvcnRfbG9nbyI7czoxNzoiMTc2Mjg3NDk4MzQ3MS5wbmciO3M6ODoiYXBwX2xvZ28iO3M6MTc6IjE3NjI4NzQ5ODM5MDQucG5nIjtzOjUzOiJsb2dpbl9hZG1pbnNfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aToxO30=', 1766658387),
('XjjJsgfj5dfxhMj8wVRSxwuiuDKin2nZx7WnXgDK', NULL, '149.57.180.132', 'Mozilla/5.0 (X11; Linux i686; rv:109.0) Gecko/20100101 Firefox/120.0', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiSVdhNFhuZ0UybVpFY1psZWF2dFpJRU92cU1jMjZPQ1Z6WkN2U0trSiI7czoxMDoic2hvcnRfbG9nbyI7czoxNzoiMTc2Mjg3NDk4MzQ3MS5wbmciO3M6ODoiYXBwX2xvZ28iO3M6MTc6IjE3NjI4NzQ5ODM5MDQucG5nIjtzOjk6Il9wcmV2aW91cyI7YToxOntzOjM6InVybCI7czoyNjoiaHR0cHM6Ly92cG4uY2hhZG5pY2hvay5jb20iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1766657772);

-- --------------------------------------------------------

--
-- Table structure for table `subscription_plans`
--

CREATE TABLE `subscription_plans` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pakage_name` varchar(255) NOT NULL,
  `validity` int(11) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `start_date` timestamp NULL DEFAULT NULL,
  `expired_date` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `subscription_plans`
--

INSERT INTO `subscription_plans` (`id`, `pakage_name`, `validity`, `price`, `start_date`, `expired_date`, `created_at`, `updated_at`) VALUES
(5, '365 Days Plan', 365, 50.00, '2025-09-16 00:01:29', '2026-09-16 00:01:29', '2025-09-08 22:08:05', '2025-09-16 00:01:29'),
(6, '180 Days Plan', 180, 2.00, '2025-09-15 07:34:40', '2026-03-14 08:34:40', '2025-09-09 09:55:25', '2025-09-15 07:34:40'),
(7, '30 Days Plan', 30, 1.00, '2025-09-19 23:10:15', '2025-10-19 23:10:15', '2025-09-09 09:56:09', '2025-09-19 23:10:15');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `admin_password` varchar(255) DEFAULT NULL,
  `subscription_id` int(11) DEFAULT NULL,
  `isPremium` tinyint(1) NOT NULL DEFAULT 0,
  `isSuspended` tinyint(1) NOT NULL DEFAULT 0,
  `last_seen` timestamp NULL DEFAULT NULL,
  `pakage_name` varchar(255) DEFAULT NULL,
  `price` int(255) DEFAULT NULL,
  `validity` varchar(255) DEFAULT NULL,
  `start_date` timestamp NULL DEFAULT NULL,
  `expired_date` timestamp NULL DEFAULT NULL,
  `device` int(11) NOT NULL DEFAULT 1,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `admin_password`, `subscription_id`, `isPremium`, `isSuspended`, `last_seen`, `pakage_name`, `price`, `validity`, `start_date`, `expired_date`, `device`, `remember_token`, `created_at`, `updated_at`) VALUES
(66, 'test', 'test@gmail.com', NULL, '$2y$12$FN8Hi3.nxjsn0g5NcGZ2lebazU9C26u.BlzWq.twzEuwLSwsMe58C', 'Apass@#123', 75, 1, 0, NULL, '30 days', 30, '30', '2025-12-24 08:18:46', '2026-01-23 08:18:46', 5, NULL, '2025-12-24 01:56:56', '2025-12-24 22:15:59');

-- --------------------------------------------------------

--
-- Table structure for table `v2rays`
--

CREATE TABLE `v2rays` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `country_code` varchar(255) NOT NULL,
  `city_name` varchar(255) NOT NULL,
  `active_count` int(11) DEFAULT 0,
  `link` longtext NOT NULL,
  `type` tinyint(1) NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `v2rays`
--

INSERT INTO `v2rays` (`id`, `name`, `country_code`, `city_name`, `active_count`, `link`, `type`, `status`, `created_at`, `updated_at`) VALUES
(5, 'Singapore Pro V2ray', 'sg', 'Jurong Town', 0, 'vless://6e3efb6e-4522-4d85-b358-fffd526c8268@46.250.226.102:59076?type=tcp&encryption=none&security=none#Singapore-iffwpwe1', 1, 1, '2025-06-02 16:46:33', '2025-12-24 08:18:10'),
(23, 'Singapore', 'sg', 'sg', 0, 'vless://6e3efb6e-4522-4d85-b358-fffd526c8268@46.250.226.102:59076?type=tcp&encryption=none&security=none#Singapore-iffwpwe1', 0, 1, '2025-12-24 07:12:03', '2025-12-25 02:00:57');

-- --------------------------------------------------------

--
-- Table structure for table `wireguards`
--

CREATE TABLE `wireguards` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `country_code` varchar(255) NOT NULL,
  `city_name` varchar(255) NOT NULL,
  `active_count` int(11) DEFAULT 0,
  `link` longtext DEFAULT NULL,
  `address` text DEFAULT NULL,
  `type` tinyint(1) NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `host` varchar(255) DEFAULT NULL,
  `port` int(11) DEFAULT NULL,
  `vps_username` varchar(255) DEFAULT NULL,
  `vps_password` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `wireguards`
--

INSERT INTO `wireguards` (`id`, `name`, `country_code`, `city_name`, `active_count`, `link`, `address`, `type`, `status`, `host`, `port`, `vps_username`, `vps_password`, `created_at`, `updated_at`) VALUES
(12, 'Singapore Pro WG', 'sg', 'Lion City', 0, NULL, NULL, 1, 1, '46.250.226.102', 22, 'root', '156kXN6KKEFPl', '2025-12-23 22:31:44', '2025-12-24 08:17:58'),
(13, 'Singapore', 'sg', 'sg', 0, NULL, NULL, 0, 1, '46.250.226.102', 22, 'root', '156kXN6KKEFPl', '2025-12-24 07:12:50', '2025-12-24 22:17:49');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `admins_email_unique` (`email`);

--
-- Indexes for table `app_settings`
--
ALTER TABLE `app_settings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `bandwidths`
--
ALTER TABLE `bandwidths`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`);

--
-- Indexes for table `chats`
--
ALTER TABLE `chats`
  ADD PRIMARY KEY (`id`),
  ADD KEY `chats_user_id_foreign` (`user_id`),
  ADD KEY `chats_admin_id_foreign` (`admin_id`);

--
-- Indexes for table `epays`
--
ALTER TABLE `epays`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `epays_order_no_unique` (`order_no`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `help_centers`
--
ALTER TABLE `help_centers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `open_connects`
--
ALTER TABLE `open_connects`
  ADD PRIMARY KEY (`id`),
  ADD KEY `active_count` (`active_count`);

--
-- Indexes for table `open_vpns`
--
ALTER TABLE `open_vpns`
  ADD PRIMARY KEY (`id`),
  ADD KEY `active_count` (`active_count`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `subscription_plans`
--
ALTER TABLE `subscription_plans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- Indexes for table `v2rays`
--
ALTER TABLE `v2rays`
  ADD PRIMARY KEY (`id`),
  ADD KEY `active_count` (`active_count`);

--
-- Indexes for table `wireguards`
--
ALTER TABLE `wireguards`
  ADD PRIMARY KEY (`id`),
  ADD KEY `active_count` (`active_count`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `app_settings`
--
ALTER TABLE `app_settings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `bandwidths`
--
ALTER TABLE `bandwidths`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `chats`
--
ALTER TABLE `chats`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- AUTO_INCREMENT for table `epays`
--
ALTER TABLE `epays`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `help_centers`
--
ALTER TABLE `help_centers`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `open_connects`
--
ALTER TABLE `open_connects`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `open_vpns`
--
ALTER TABLE `open_vpns`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=76;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=181;

--
-- AUTO_INCREMENT for table `subscription_plans`
--
ALTER TABLE `subscription_plans`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=67;

--
-- AUTO_INCREMENT for table `v2rays`
--
ALTER TABLE `v2rays`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `wireguards`
--
ALTER TABLE `wireguards`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `chats`
--
ALTER TABLE `chats`
  ADD CONSTRAINT `chats_admin_id_foreign` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `chats_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- Table structure for table `redeem_requests`
CREATE TABLE `redeem_requests` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `code` varchar(255) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `approved_by` bigint(20) unsigned DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `rejected_by` bigint(20) unsigned DEFAULT NULL,
  `rejected_at` timestamp NULL DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `redeem_requests_user_id_status_index` (`user_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
