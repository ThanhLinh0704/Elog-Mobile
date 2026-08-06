# 🚚 ELog Driver Mobile App

Ứng dụng di động Flutter dành riêng cho **Tài xế (Driver)** thuộc Hệ thống Quản lý Giao vận **ELog Delivery Management System**.

---

## 📌 Giới thiệu (Overview)

**ELog Driver Mobile App** là công cụ làm việc trực tiếp của tài xế trên đường giao hàng. Ứng dụng kết nối trực tiếp với Backend API (Spring Boot) để giúp tài xế xem chuyến hàng được phân công trong ngày, thực thi từng bước giao hàng theo từng đơn, khai báo ngoại lệ/từ chối giao hàng, xem lộ trình trên bản đồ và theo dõi lịch sử ngoại lệ của chính mình.

Ứng dụng hiện có **2 luồng thực thi song song**, phản ánh 2 giai đoạn phát triển của tính năng:

| | Luồng cũ (theo điểm dừng) | Luồng mới — FT-09 (theo đơn hàng) |
| :--- | :--- | :--- |
| Phạm vi | Xem lại **chuyến của bất kỳ ngày nào** qua lịch | Chuyến **đang hoạt động hôm nay** (TripExecution) |
| Đơn vị xử lý | Cả điểm dừng (`TripStop`) | Từng đơn hàng riêng lẻ trong điểm dừng (`Order`) |
| Trang | `TripDetailPage` (+ `TripMapPage`) | Thẻ chuyến hiện tại trong `MyTripsPage` |
| Repository | `TripRepository` | `DriverTripRepository` |
| Kết quả giao | Hoàn thành / Từ chối (1 lý do cho cả điểm) | Đã giao / **Giao một phần** / Thất bại (lý do theo từng đơn) |

Cả 2 luồng cùng ghi nhận vào một bảng `DeliveryException` ở Backend nên đều hiện ra trong màn "Ngoại lệ của tôi".

### 🌟 Tính năng chính (Key Features)

- 🔐 **Đăng nhập & Phân quyền:**
  - Đăng nhập tài khoản tài xế (chỉ role `DRIVER` được vào app), lưu JWT Token bằng `flutter_secure_storage`.
  - Tự động đăng xuất & xoá token khi nhận lỗi `401` từ Backend.

- 📋 **Chuyến hàng hôm nay (Active Trip — FT-09):**
  - Tự tải chuyến đang hoạt động (`GET /driver/trips/active`); nếu không có mà vẫn còn chuyến đã hoàn thành nhưng **chưa xác nhận xe về kho**, tự động rơi về danh sách "chờ về kho" (`pending-return`) để tài xế không bị "kẹt".
  - **Hướng dẫn LIFO**: thứ tự xếp/dỡ hàng lên xe theo nguyên tắc vào sau ra trước.
  - **Lịch giao hàng**: danh sách điểm dừng theo thứ tự, trạng thái tổng hợp từng điểm (Chờ giao / Đã giao / Giao một phần / Thất bại).
  - **Cập nhật kết quả từng đơn**: Đã giao thành công / Giao một phần / Giao thất bại — 2 trạng thái sau bắt buộc chọn lý do (Cửa hàng từ chối, đóng cửa, hàng sai/hỏng, hết chỗ chứa, người nhận vắng mặt, khác) + ghi chú thêm.
  - **Hoàn thành chuyến** khi hết đơn PENDING, và **Xác nhận xe về kho** để giải phóng xe/tài xế cho chuyến sau.

- 🗓️ **Chuyến hàng theo ngày & Lịch sử (luồng cũ):**
  - Chọn ngày qua `TripCalendarDialog` (chấm đỏ/xanh đánh dấu ngày có chuyến).
  - `TripDetailPage`: xem timeline điểm dừng, thông tin cửa hàng/người liên hệ (bấm gọi nhanh), ETA và giờ đến/rời thực tế.
  - Thao tác: **Bắt đầu chuyến**, **Đã đến điểm dừng** (tự phát hiện trễ giờ — BR-09 Time Exception), **Hoàn thành điểm giao**, **Từ chối giao hàng** cả điểm (Bottom Sheet riêng, `delivery_rejection`).
  - `TripMapPage`: bản đồ tuyến đường (kho + các điểm dừng + polyline bám đường), dữ liệu lấy sẵn từ Backend, không cần GPS thời gian thực.

- ⚠️ **Ngoại lệ của tôi (My Exceptions — chỉ xem):**
  - Lọc theo ngày, loại ngoại lệ (Trễ ETA / Từ chối giao hàng), đã xử lý hay chưa.
  - Xem chi tiết: lý do, mức trễ, cửa hàng, người ghi nhận, trạng thái xử lý của dispatcher.

- 👤 **Hồ sơ cá nhân (Profile):**
  - Xem username, họ tên, mã người dùng, vai trò.
  - Đăng xuất.

---

## 🛠️ Công nghệ Sử dụng (Tech Stack)

| Hạng mục | Thư viện / Công nghệ | Mô tả |
| :--- | :--- | :--- |
| **Framework** | **Flutter** (Dart `>=3.0.0 <4.0.0`) | Nền tảng phát triển ứng dụng di động |
| **State Management** | `flutter_riverpod` (v2.5) + `riverpod_annotation` | Quản lý trạng thái phản ứng (Reactive) |
| **Navigation** | `go_router` (v14.2) | Điều hướng + Route Guard theo trạng thái đăng nhập/role |
| **HTTP Client** | `dio` (v5.4) | Gửi request RESTful + Bearer Token Interceptor + parse lỗi chuẩn |
| **Secure Storage** | `flutter_secure_storage` (v9.2) | Lưu JWT token mã hoá (Android EncryptedSharedPreferences) |
| **Bản đồ** | `flutter_map` (v7.0) + `latlong2` | Vẽ tuyến đường & điểm dừng (OpenStreetMap tile, không cần API key) |
| **Formatting** | `intl` (v0.19) | Định dạng ngày giờ theo `vi_VN` |
| **Value objects** | `equatable` (v2.0) | So sánh state/model theo giá trị |
| **Codegen (dev)** | `build_runner`, `riverpod_generator` | Sinh mã cho Riverpod (khi dùng annotation) |
| **UI Design** | Material Design 3 | Giao diện tối ưu cho tài xế, dùng trên đường |

> ⚠️ Dự án hiện **chỉ có cấu hình nền tảng Android** (không có thư mục `ios/`, `web/`, `windows/`). Muốn chạy trên iOS/Web cần tự thêm nền tảng bằng `flutter create --platforms=ios,web .` trước.

---

## 📁 Cấu trúc Dự án (Project Structure)

```text
ELOG_Mobile/
├── android/                            # Cấu hình dự án Android (nền tảng duy nhất hiện có)
├── test/                                # Unit/widget test (widget_test.dart)
├── lib/
│   ├── main.dart                       # Điểm khởi chạy (ProviderScope + GoRouter + locale vi_VN)
│   ├── providers.dart                  # Riverpod Providers toàn cục (Dio, Storage, Repos, AuthSession)
│   ├── core/
│   │   ├── constants.dart              # kBaseUrl (tự nhận diện platform) + storage keys
│   │   ├── error/exceptions.dart       # ApiBusinessException (map error code → tiếng Việt), NetworkException
│   │   ├── network/dio_client.dart     # Dio + Bearer interceptor + auto-clear token khi 401
│   │   ├── storage/secure_storage_service.dart # Đọc/ghi/xoá JWT token & thông tin user
│   │   ├── theme/app_theme.dart        # Màu sắc & Material 3 Theme
│   │   └── utils/
│   │       ├── date_time_utils.dart    # Helper định dạng giờ/ngày
│   │       └── polyline_decoder.dart   # Decode polyline route từ Backend cho bản đồ
│   ├── routes/router.dart              # GoRouter: /login, /my-trips, /trips/:tripId, /profile, /exceptions
│   └── features/                       # Feature-first modules
│       ├── auth/
│       │   ├── data/auth_service.dart          # POST /auth/login, /auth/logout
│       │   └── presentation/login_page.dart
│       ├── driver_trips/               # Cả 2 luồng (cũ + FT-09) nằm chung module này
│       │   ├── data/
│       │   │   ├── models/             # TripModel, TripStopModel, DriverTripModel, TripProgressModel,
│       │   │   │                       # TripOutcomeModel, ActionResults, UpdateOrderResultRequest
│       │   │   └── repositories/
│       │   │       └── trip_repository.dart    # TripRepository (cũ) + DriverTripRepository (FT-09)
│       │   └── presentation/
│       │       ├── pages/              # MyTripsPage, TripDetailPage, TripMapPage
│       │       ├── state/trip_state.dart       # MyTripsNotifier, ActiveTripNotifier, TripDetailNotifier...
│       │       └── widgets/            # OrderResultBottomSheet, TripCalendarDialog, shared_widgets
│       ├── delivery_rejection/
│       │   └── presentation/rejection_bottom_sheet.dart  # Từ chối cả điểm dừng (luồng cũ)
│       ├── exceptions/                 # "Ngoại lệ của tôi" — chỉ xem
│       │   ├── data/{models,repositories}/exception_item_model.dart, exception_repository.dart
│       │   └── presentation/{pages,state}/my_exceptions_page.dart, exception_state.dart
│       └── profile/
│           └── presentation/pages/profile_page.dart
├── pubspec.yaml
└── README.md
```

---

## 🔗 Danh sách API Kết nối (API Endpoints)

Tất cả endpoint đều có prefix `/api/v1` (đã migrate từ `/api` cũ).

### Auth
| Phương thức | Endpoint | Mô tả |
| :--- | :--- | :--- |
| `POST` | `/api/v1/auth/login` | Đăng nhập, nhận `accessToken`/`refreshToken`/`roles` |
| `POST` | `/api/v1/auth/logout` | Đăng xuất, thu hồi refresh token |

### Chuyến hàng theo ngày — luồng cũ (`TripRepository`)
| Phương thức | Endpoint | Mô tả |
| :--- | :--- | :--- |
| `GET` | `/api/v1/trips/my-trips?date=` | Danh sách chuyến của tài xế theo ngày |
| `GET` | `/api/v1/trips/my-trips/calendar?month=` | Ngày nào trong tháng có chuyến (chấm trên lịch) |
| `GET` | `/api/v1/trips/{tripId}` | Chi tiết chuyến + danh sách điểm dừng |
| `GET` | `/api/v1/trips/{tripId}/progress` | Dữ liệu bản đồ: toạ độ điểm dừng + polyline tuyến đường |
| `POST` | `/api/v1/trips/{tripId}/start` | Bắt đầu chuyến |
| `POST` | `/api/v1/trip-stops/{id}/arrive` | Check-in đến điểm dừng (tự phát hiện trễ ETA) |
| `POST` | `/api/v1/trip-stops/{id}/complete` | Hoàn thành điểm dừng |
| `POST` | `/api/v1/trip-stops/{id}/reject` | Từ chối giao hàng cho cả điểm dừng |

### Chuyến hoạt động hôm nay — FT-09 (`DriverTripRepository`)
| Phương thức | Endpoint | Mô tả |
| :--- | :--- | :--- |
| `GET` | `/api/v1/driver/trips/active` | Chuyến đang thực thi (ASSIGNED/IN_PROGRESS) của tài xế |
| `GET` | `/api/v1/driver/trips/pending-return` | Chuyến đã hoàn thành nhưng chưa xác nhận xe về kho |
| `POST` | `/api/v1/driver/trips/{executionId}/start` | Chuyển ASSIGNED → IN_PROGRESS |
| `PUT` | `/api/v1/driver/trips/{executionId}/orders/{orderId}/result` | Cập nhật kết quả giao **từng đơn** (delivered/partial/failed + lý do) |
| `POST` | `/api/v1/driver/trips/{executionId}/complete` | Hoàn thành chuyến khi hết đơn PENDING |
| `POST` | `/api/v1/driver/trips/{executionId}/return-to-warehouse` | Xác nhận xe đã về kho |

### Ngoại lệ
| Phương thức | Endpoint | Mô tả |
| :--- | :--- | :--- |
| `GET` | `/api/v1/exceptions?date=&type=&resolved=` | Danh sách ngoại lệ của tài xế (chỉ xem, không resolve được) |

---

## 🚀 Hướng dẫn Cài đặt & Khởi chạy (Getting Started)

### 1. Yêu cầu môi trường
- **Flutter SDK** `>=3.0.0`, **Dart SDK** `>=3.0.0 <4.0.0`
- Android Studio hoặc VS Code (Flutter & Dart extension)
- Android Emulator hoặc thiết bị Android thật (dự án chưa cấu hình iOS/Web)
- Backend ELog Spring Boot đang chạy ở cổng `8080`

### 2. Cài đặt Dependencies
```bash
flutter pub get
```

### 3. Base URL Backend
`lib/core/constants.dart` đã **tự nhận diện platform** — không cần sửa gì khi chạy trên Android Emulator hoặc Web/Desktop:

```dart
String get kBaseUrl {
  if (kIsWeb) return 'http://localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}
```

Chỉ cần sửa tay khi chạy trên **thiết bị Android thật** (điện thoại không thể gọi `10.0.2.2`) — đổi tạm thành IP LAN của máy chạy Backend, ví dụ:
```dart
return 'http://192.168.1.10:8080';
```

### 4. Khởi chạy
```bash
flutter run
```

---

## 📝 Tài khoản Thử nghiệm (Test Account)

- **Username**: tài khoản bất kỳ có quyền `ROLE_DRIVER` trong hệ thống (ví dụ `driver05`)
- **Password**: theo cấu hình dữ liệu mẫu của Backend hiện tại

Đăng nhập bằng tài khoản không có role `DRIVER` sẽ bị chặn ngay ở màn đăng nhập (router redirect về `/login` kèm thông báo lỗi).

---

*SEP490_G104 · ELog Delivery Management System · 2026*
