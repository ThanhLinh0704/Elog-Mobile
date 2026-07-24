# 🚚 ELog Driver Mobile App

Ứng dụng di động Flutter dành riêng cho **Tài xế (Driver)** thuộc Hệ thống Quản lý Giao vận Điện máy **ELog Delivery Management System**.

---

## 📌 Giới thiệu (Overview)

**ELog Driver Mobile App** là công cụ làm việc trực tiếp của tài xế trên đường giao hàng. Ứng dụng kết nối trực tiếp với Backend API để giúp tài xế xem danh sách chuyến hàng được phân công, theo dõi lộ trình điểm dừng, check-in thời gian thực và ghi nhận ngoại lệ/từ chối giao hàng ngay tại điểm giao.

### 🌟 Tính năng chính (Key Features)

- 🔐 **Đăng nhập & Phân quyền (Auth & Security):**
  - Đăng nhập tài khoản tài xế, tự động lưu trữ mã xác thực JWT Token bằng `flutter_secure_storage`.
  - Tự động bảo vệ route, điều hướng và tự động đăng xuất khi hết hạn session.

- 📋 **Quản lý Chuyến hàng (My Trips):**
  - Xem danh sách các chuyến hàng được điều phối theo ngày.
  - Chọn ngày giao hàng linh hoạt.
  - Thống kê tổng số điểm dừng, trạng thái chuyến (*Chờ xuất phát*, *Đang giao*, *Hoàn thành*).

- 📍 **Chi tiết Chuyến & Lộ trình Điểm dừng (Trip Timeline):**
  - Xem danh sách các mốc giao hàng theo thứ tự tối ưu.
  - Xem thông tin cửa hàng: Tên, Mã cửa hàng, Địa chỉ chi tiết, Người liên hệ & SĐT (bấm gọi nhanh).
  - Hiển thị ETA dự kiến, giờ đến thực tế và giờ rời thực tế.

- ⚡ **Thao tác Thực thi Chuyến hàng (Driver Actions):**
  - 🚀 **Bắt đầu chuyến (Start Trip):** Chuyển chuyến từ `DISPATCHED` $\rightarrow$ `IN_PROGRESS`.
  - 📍 **Đã đến điểm dừng (Arrive Stop):** Ghi nhận giờ đến thực tế, tự động phát hiện trễ giờ (BR-09 Time Exception).
  - ✅ **Hoàn thành điểm giao (Complete Stop):** Ghi nhận rời điểm dừng, tự động hoàn thành chuyến khi xong điểm cuối.
  - ⚠️ **Khai báo Ngoại lệ (Delivery Rejection):** Mở Bottom Sheet khai báo từ chối nhận hàng hoặc sự cố tại điểm giao.

---

## 🛠️ Công nghệ Sử dụng (Tech Stack)

| Hạng mục | Thư viện / Công nghệ | Mô tả |
| :--- | :--- | :--- |
| **Framework** | **Flutter** (Dart `>=3.0.0 <4.0.0`) | Nền tảng phát triển ứng dụng di động đa nền tảng |
| **State Management** | `flutter_riverpod` (v2.5) | Quản lý trạng thái ứng dụng phản kháng (Reactive) |
| **Navigation** | `go_router` (v14.2) | Điều hướng và bảo vệ tuyến đường (Route Guard) |
| **HTTP Client** | `dio` (v5.4) | Gửi yêu cầu HTTP RESTful + Bearer Token Interceptor |
| **Secure Storage** | `flutter_secure_storage` | Lưu trữ Token mã hóa an toàn trên thiết bị (KeyStore/Keychain) |
| **Formatting** | `intl` (v0.19) | Định dạng ngày tháng, giờ giấc chuẩn Việt Nam |
| **UI Design** | **Material Design 3** | Giao diện hiện đại, tối ưu trải nghiệm cho tài xế |

---

## 📁 Cấu trúc Dự án (Project Structure)

```text
ELOG_Mobile/
├── android/                           # Cấu hình dự án Android
├── ios/                               # Cấu hình dự án iOS
├── lib/
│   ├── main.dart                      # Điểm khởi chạy ứng dụng (ProviderScope + GoRouter)
│   ├── providers.dart                 # Khai báo các Riverpod Providers toàn cục
│   ├── core/                          # Thư viện dùng chung (Core Modules)
│   │   ├── constants.dart             # Cấu hình Base URL, Storage Keys
│   │   ├── error/
│   │   │   └── exceptions.dart        # Xử lý lỗi API (Business & Network Exception)
│   │   ├── network/
│   │   │   └── dio_client.dart        # Khởi tạo Dio Client + Bearer Interceptor
│   │   ├── storage/
│   │   │   └── secure_storage_service.dart # Quản lý JWT Token bảo mật
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Cấu hình màu sắc & Material 3 Theme
│   │   └── utils/
│   │       └── date_time_utils.dart   # Utility định dạng giờ giấc
│   ├── routes/
│   │   └── router.dart                # Cấu hình điều hướng GoRouter + Driver Gate
│   └── features/                      # Các tính năng theo Module (Feature-First)
│       ├── auth/                      # Đăng nhập & Xác thực
│       │   ├── data/auth_service.dart
│       │   └── presentation/login_page.dart
│       ├── driver_trips/              # Quản lý & Thực thi chuyến hàng
│       │   ├── data/
│       │   │   ├── models/            # DTO Models (Trip, TripStop, ActionResults)
│       │   │   └── repositories/      # Gọi API lấy chuyến & thực thi thao tác
│       │   └── presentation/
│       │       ├── pages/             # Trang MyTripsPage & TripDetailPage
│       │       ├── state/             # Riverpod Notifiers quản lý state
│       │       └── widgets/           # Widgets tái sử dụng (StatusBadge, Timeline...)
│       └── delivery_rejection/        # Ngoại lệ & Từ chối giao hàng
│           └── presentation/rejection_bottom_sheet.dart
├── pubspec.yaml                       # Quản lý dependencies & tài nguyên
└── README.md                          # Tài liệu hướng dẫn dự án
```

---

## 🔗 Danh sách API Kết nối (API Endpoints)

| Tính năng | Phương thức | Endpoint | Mô tả |
| :--- | :--- | :--- | :--- |
| **Đăng nhập** | `POST` | `/api/auth/login` | Đăng nhập tài xế & nhận JWT Token |
| **Danh sách chuyến** | `GET` | `/api/trips/my-trips?date=yyyy-MM-dd` | Lấy các chuyến được phân công trong ngày |
| **Chi tiết chuyến** | `GET` | `/api/trips/{id}` | Lấy chi tiết lộ trình và các điểm dừng |
| **Bắt đầu chuyến** | `POST` | `/api/trips/{id}/start` | Tài xế bấm xuất phát |
| **Đến điểm dừng** | `POST` | `/api/trip-stops/{id}/arrive` | Tài xế bấm check-in tại cửa hàng |
| **Hoàn thành điểm** | `POST` | `/api/trip-stops/{id}/complete` | Tài xế bấm hoàn thành giao hàng |
| **Từ chối / Sự cố** | `POST` | `/api/trip-stops/{id}/reject` | Báo cáo ngoại lệ từ chối nhận hàng |

---

## 🚀 Hướng dẫn Cài đặt & Khởi chạy (Getting Started)

### 1. Yêu cầu môi trường (Prerequisites)
- **Flutter SDK**: `>=3.0.0`
- **Dart SDK**: `>=3.0.0 <4.0.0`
- **Android Studio** hoặc **VS Code** (đã cài Flutter & Dart Extension)
- **Android Emulator** hoặc **Thiết bị thật** (Android / iOS)
- Backend **ELog Spring Boot** đang khởi chạy (cổng mặc định `8080`)

### 2. Cài đặt Dependencies
Mở terminal tại thư mục `ELOG_Mobile` và chạy lệnh:
```bash
flutter pub get
```

### 3. Cấu hình IP máy chủ Backend
Chỉnh sửa file `lib/core/constants.dart` để trỏ tới Backend API của bạn:

```dart
// Nếu chạy trên Android Emulator:
const String kBaseUrl = 'http://10.0.2.2:8080';

// Nếu chạy trên Thiết bị thật (chúng cùng mạng Wi-Fi với máy tính chạy BE):
// const String kBaseUrl = 'http://192.168.x.x:8080';
```

### 4. Khởi chạy Ứng dụng
```bash
# Chạy ứng dụng trên máy ảo/thiết bị đang kết nối:
flutter run
```

---

## 📝 Tài khoản Thử nghiệm (Test Account)

- **Username**: `driver1` (hoặc tài khoản có quyền `ROLE_DRIVER`)
- **Password**: `password` (hoặc mật khẩu mặc định hệ thống)

---

*SEP490_G104 · ELog Delivery Management System · 2026*
