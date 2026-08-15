#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const inputPath = path.resolve(process.argv[2]);
const outputPath = path.resolve(process.argv[3]);
const input = JSON.parse(fs.readFileSync(inputPath, "utf8"));

const fileMeta = {
  "lib/core/theme/app_theme.dart": {
    summary: "Tập trung Material 3 theme, bảng màu thương hiệu và helper ánh xạ trạng thái chuyến/điểm giao sang màu, nhãn và icon dùng nhất quán toàn ứng dụng.",
    tags: ["theme", "design-system", "status-mapping", "flutter"],
    languageNotes: "Dart static getters và methods gom toàn bộ design tokens vào một namespace không thể khởi tạo."
  },
  "lib/core/utils/date_time_utils.dart": {
    summary: "Cung cấp các formatter ngày giờ tiếng Việt, nhãn độ trễ và ngày hiện tại theo định dạng API, với fallback an toàn cho dữ liệu backend không hợp lệ.",
    tags: ["utility", "date-time", "formatting", "localization"]
  },
  "lib/core/utils/polyline_decoder.dart": {
    summary: "Giải mã Google/Goong encoded polyline precision 5 thành LatLng và ghép tuần tự nhiều chặng được phân tách bằng dấu chấm phẩy.",
    tags: ["utility", "polyline", "map", "route"]
  },
  "lib/features/auth/data/auth_service.dart": {
    summary: "Thực hiện login/logout qua Dio, phân tích token response và lưu session tài xế vào secure storage; lỗi HTTP được chuẩn hóa qua parseDioError.",
    tags: ["service", "authentication", "api-client", "secure-storage"]
  },
  "lib/features/auth/presentation/login_page.dart": {
    summary: "Màn hình đăng nhập Driver dùng Riverpod, validate credential, hiển thị lỗi nghiệp vụ/mạng và từ chối tài khoản không có role DRIVER trước khi router chuyển trang.",
    tags: ["page", "authentication", "riverpod", "form-validation"]
  },
  "lib/features/delivery_rejection/presentation/rejection_bottom_sheet.dart": {
    summary: "Bottom sheet thu thập loại từ chối và ghi chú giao hàng, bắt buộc mô tả cho OTHER và yêu cầu xác nhận rằng hàng sẽ được giữ lại để trả kho.",
    tags: ["component", "delivery-rejection", "form-validation", "bottom-sheet"]
  },
  "lib/features/driver_trips/data/models/action_results.dart": {
    summary: "Tập hợp DTO kết quả cho các action legacy start trip, arrive stop, complete stop và reject delivery, bao gồm thông tin điểm tiếp theo và ngoại lệ thời gian.",
    tags: ["data-model", "api-response", "trip-actions", "serialization"]
  },
  "lib/features/driver_trips/data/models/driver_trip_model.dart": {
    summary: "Mô hình domain đầy đủ cho FT-09 order-level execution: trạng thái chuyến/đơn/điểm, nested orders và items, hướng dẫn xếp hàng LIFO cùng thống kê tiến độ.",
    tags: ["data-model", "driver-trip", "order-delivery", "serialization"],
    languageNotes: "Enums Dart chuẩn hóa chuỗi trạng thái backend và cung cấp nhãn tiếng Việt, trong khi nested factory constructors dựng toàn bộ cây DTO."
  },
  "lib/features/driver_trips/data/models/trip_model.dart": {
    summary: "Mô hình chuyến legacy ánh xạ TripResponse, thông tin xe/tài xế, danh sách trip stops và dữ liệu calendar theo ngày.",
    tags: ["data-model", "legacy-flow", "trip", "serialization"]
  },
  "lib/features/driver_trips/data/models/trip_outcome_model.dart": {
    summary: "Mô hình báo cáo kết quả sau khi hoàn tất FT-09 execution, theo dõi số đơn giao thành công/thất bại/một phần và trạng thái nghiệm thu.",
    tags: ["data-model", "trip-outcome", "order-delivery", "serialization"]
  },
  "lib/features/driver_trips/data/models/trip_progress_model.dart": {
    summary: "Mô hình tiến độ tuyến đường gồm route polyline, khoảng cách và các điểm giao có tọa độ/trạng thái để hiển thị bản đồ.",
    tags: ["data-model", "trip-progress", "map", "serialization"]
  },
  "lib/features/driver_trips/data/models/trip_stop_model.dart": {
    summary: "Mô hình điểm giao legacy kết hợp dữ liệu TripStopResponse với trạng thái cục bộ sau arrive/complete, độ trễ và cờ ngoại lệ.",
    tags: ["data-model", "trip-stop", "legacy-flow", "serialization"]
  },
  "lib/features/driver_trips/data/models/update_order_result_request.dart": {
    summary: "Tạo request body cập nhật kết quả một đơn FT-09, chỉ gửi reasonCode/exceptionText khi được cung cấp và chuyển enum sang giá trị API.",
    tags: ["data-model", "api-request", "order-delivery", "serialization"]
  },
  "lib/features/driver_trips/data/repositories/trip_repository.dart": {
    summary: "Chứa hai repository gọi Spring Boot API: TripRepository cho legacy stop-level flow và DriverTripRepository cho FT-09 order-level execution, hoàn tất chuyến và trả xe.",
    tags: ["repository", "api-client", "trip-execution", "data-access"],
    languageNotes: "Hai API flow được giữ song song để hỗ trợ màn hình legacy và quy trình FT-09 mới trong cùng ứng dụng."
  },
  "lib/features/driver_trips/presentation/pages/my_trips_page.dart": {
    summary: "Dashboard chính của tài xế: ngày hiện tại ưu tiên active FT-09 trip với LIFO/order result/return-to-warehouse, còn ngày lịch sử dùng danh sách chuyến legacy và điều hướng chi tiết.",
    tags: ["page", "driver-dashboard", "trip-execution", "riverpod"],
    languageNotes: "Widget kết hợp hai Riverpod state machines để chuyển ngữ cảnh giữa active execution hôm nay và lịch sử theo ngày."
  },
  "lib/features/driver_trips/presentation/pages/trip_detail_page.dart": {
    summary: "Màn hình chi tiết legacy stop-level flow, hiển thị timeline điểm giao và điều phối start, arrive, complete, reject cùng xác nhận trả xe và cảnh báo trễ ETA.",
    tags: ["page", "trip-detail", "legacy-flow", "driver-actions"]
  },
  "lib/features/driver_trips/presentation/pages/trip_map_page.dart": {
    summary: "Hiển thị tuyến đường backend trên FlutterMap/OpenStreetMap, fit camera theo polyline và tọa độ điểm giao, gắn marker kho và bottom sheet trạng thái điểm.",
    tags: ["page", "map", "route-visualization", "flutter-map"]
  },
  "lib/features/driver_trips/presentation/state/trip_state.dart": {
    summary: "Định nghĩa Riverpod states/notifiers cho danh sách chuyến, calendar, legacy trip detail và active FT-09 execution, bao gồm loading flags, error mapping và optimistic/local updates.",
    tags: ["state-management", "riverpod", "trip-execution", "orchestration"],
    languageNotes: "Immutable copyWith state kết hợp StateNotifier giúp cô lập loading flags theo từng action và khôi phục pending-return trip sau app restart."
  },
  "lib/features/driver_trips/presentation/widgets/order_result_bottom_sheet.dart": {
    summary: "Bottom sheet cập nhật kết quả từng order FT-09, yêu cầu reason code cho giao một phần/thất bại và chuyển form thành UpdateOrderResultRequest.",
    tags: ["component", "order-result", "bottom-sheet", "form-validation"]
  },
  "lib/features/driver_trips/presentation/widgets/shared_widgets.dart": {
    summary: "Cung cấp widget dùng chung cho badge trạng thái, dòng thông tin, error/time/goods banners, confirmation dialog và snackbar trên các màn hình chuyến.",
    tags: ["component", "shared-widget", "status-ui", "feedback"]
  },
  "lib/features/driver_trips/presentation/widgets/trip_calendar_dialog.dart": {
    summary: "Calendar dialog chọn ngày giao, tải summary theo tháng bằng Riverpod và đánh dấu ngày có chuyến bằng chấm đỏ hoặc xanh theo trạng thái hoàn tất.",
    tags: ["component", "calendar", "riverpod", "trip-history"]
  },
  "lib/features/exceptions/data/models/exception_item_model.dart": {
    summary: "Mô hình danh sách ngoại lệ tài xế, phân loại trễ ETA hoặc từ chối giao, theo dõi thông tin chuyến/điểm và dữ liệu xử lý ngoại lệ.",
    tags: ["data-model", "driver-exception", "serialization", "status-mapping"]
  },
  "lib/features/exceptions/data/repositories/exception_repository.dart": {
    summary: "Repository read-only tải ngoại lệ của tài xế theo ngày, loại và trạng thái resolved từ endpoint /api/v1/exceptions.",
    tags: ["repository", "api-client", "driver-exception", "data-access"]
  },
  "lib/features/exceptions/presentation/pages/my_exceptions_page.dart": {
    summary: "Màn hình lịch sử ngoại lệ cho phép chuyển ngày, lọc loại/trạng thái xử lý, xem thống kê và chi tiết thời gian hoặc lý do từ chối trên từng card.",
    tags: ["page", "driver-exception", "filtering", "riverpod"]
  },
  "lib/features/exceptions/presentation/state/exception_state.dart": {
    summary: "Riverpod state/notifier quản lý bộ lọc ngoại lệ, ngày truy vấn, thống kê resolved và thông báo lỗi khi tải dữ liệu tài xế.",
    tags: ["state-management", "riverpod", "driver-exception", "filtering"]
  }
};

const C = (name, start, end, exported = !name.startsWith("_")) => ({ type: "class", name, start, end, exported });
const F = (name, start, end, exported = false) => ({ type: "function", name, start, end, exported });

const structures = {
  "lib/core/theme/app_theme.dart": [
    C("AppTheme", 3, 210),
    F("AppTheme.light", 33, 132), F("AppTheme.tripStatusColor", 136, 149),
    F("AppTheme.tripStatusLabel", 151, 164), F("AppTheme.tripStatusIcon", 166, 179),
    F("AppTheme.stopStatusColor", 181, 194), F("AppTheme.stopStatusLabel", 196, 209)
  ],
  "lib/core/utils/date_time_utils.dart": [
    F("formatDateTime", 4, 12, true), F("formatTime", 15, 23, true),
    F("formatDate", 26, 34, true), F("formatDelay", 37, 41, true), F("todayForApi", 44, 46, true)
  ],
  "lib/core/utils/polyline_decoder.dart": [
    F("decodePolyline", 6, 39, true), F("decodeMultiLegPolyline", 43, 52, true)
  ],
  "lib/features/auth/data/auth_service.dart": [
    C("AuthService", 5, 69), F("AuthService.login", 13, 53), F("AuthService.logout", 56, 68)
  ],
  "lib/features/auth/presentation/login_page.dart": [
    C("LoginPage", 8, 13), C("_LoginPageState", 15, 280),
    F("_LoginPageState._submit", 31, 64), F("_LoginPageState.build", 67, 279)
  ],
  "lib/features/delivery_rejection/presentation/rejection_bottom_sheet.dart": [
    C("RejectionTypeOption", 6, 11), C("RejectionFormResult", 23, 31),
    F("showRejectionBottomSheet", 35, 52, true), C("_RejectionBottomSheetState", 67, 234),
    F("_RejectionBottomSheetState._submit", 81, 110), F("_RejectionBottomSheetState.build", 113, 233),
    C("_RejectionOption", 236, 289), F("_RejectionOption.build", 248, 288)
  ],
  "lib/features/driver_trips/data/models/action_results.dart": [
    C("StartTripResult", 2, 28), C("ArriveStopResult", 31, 66),
    F("ArriveStopResult.fromJson", 54, 65), C("CompleteStopResult", 69, 103),
    F("CompleteStopResult.fromJson", 90, 102), C("NextStopSummary", 105, 125),
    C("RejectDeliveryResult", 128, 169), F("RejectDeliveryResult.fromJson", 155, 168)
  ],
  "lib/features/driver_trips/data/models/driver_trip_model.dart": [
    F("ExecutionStatus.fromJson", 13, 26), F("ExecutionStatus.label", 28, 39),
    F("OrderDeliveryStatus.fromJson", 50, 65), F("OrderDeliveryStatus.toApiString", 67, 80),
    F("OrderDeliveryStatus.label", 82, 95), F("StopAggregatedStatus.fromJson", 110, 123),
    F("StopAggregatedStatus.label", 125, 136), C("ReasonCodeOption", 141, 145),
    C("DriverOrderItemModel", 160, 183), C("DriverOrderModel", 186, 226),
    F("DriverOrderModel.fromJson", 209, 225), C("DriverStopModel", 229, 269),
    F("DriverStopModel.fromJson", 252, 268), C("LifoLoadingItemModel", 272, 304),
    F("LifoLoadingItemModel.fromJson", 293, 303), C("DriverTripModel", 309, 402),
    F("DriverTripModel.copyWith", 349, 374), F("DriverTripModel.fromJson", 376, 401)
  ],
  "lib/features/driver_trips/data/models/trip_model.dart": [
    C("TripModel", 4, 82), F("TripModel.fromJson", 45, 73), C("VehicleInfo", 84, 96),
    C("DriverInfoModel", 98, 109), C("TripCalendarDayModel", 113, 124)
  ],
  "lib/features/driver_trips/data/models/trip_outcome_model.dart": [
    F("TripOutcomeStatus.fromJson", 8, 19), F("TripOutcomeStatus.label", 21, 30),
    C("TripOutcomeModel", 33, 90), F("TripOutcomeModel.fromJson", 70, 89)
  ],
  "lib/features/driver_trips/data/models/trip_progress_model.dart": [
    C("TripProgressModel", 4, 37), F("TripProgressModel.fromJson", 23, 36),
    C("StopProgressModel", 39, 73), F("StopProgressModel.fromJson", 62, 72)
  ],
  "lib/features/driver_trips/data/models/trip_stop_model.dart": [
    C("TripStopModel", 6, 95), F("TripStopModel.fromJson", 43, 59), F("TripStopModel.copyWith", 70, 94)
  ],
  "lib/features/driver_trips/data/models/update_order_result_request.dart": [
    C("UpdateOrderResultRequest", 5, 26), F("UpdateOrderResultRequest.toJson", 16, 25)
  ],
  "lib/features/driver_trips/data/repositories/trip_repository.dart": [
    C("RejectDeliveryRequest", 12, 26), C("TripRepository", 30, 155),
    F("TripRepository.getMyTrips", 37, 57), F("TripRepository.getMyTripsCalendar", 75, 89),
    F("TripRepository.rejectDelivery", 139, 154), C("DriverTripRepository", 159, 258),
    F("DriverTripRepository.getActiveTrip", 167, 180), F("DriverTripRepository.getPendingReturnTrips", 187, 198),
    F("DriverTripRepository.updateOrderResult", 215, 230), F("DriverTripRepository.completeExecution", 235, 244),
    F("DriverTripRepository.returnToWarehouse", 248, 258)
  ],
  "lib/features/driver_trips/presentation/pages/my_trips_page.dart": [
    C("MyTripsPage", 16, 21), C("_MyTripsPageState", 23, 1123),
    F("_MyTripsPageState._onDateChanged", 44, 54), F("_MyTripsPageState.build", 67, 222),
    F("_MyTripsPageState._buildTodayContent", 224, 364), F("_MyTripsPageState._buildHistoricalContent", 366, 447),
    F("_MyTripsPageState._buildTripListView", 449, 546), F("_MyTripsPageState._buildActiveTripView", 548, 830),
    F("_MyTripsPageState._buildLifoTab", 832, 861), F("_MyTripsPageState._buildScheduleTab", 863, 1000),
    F("_MyTripsPageState._startTrip", 1004, 1022), F("_MyTripsPageState._completeTrip", 1024, 1040),
    F("_MyTripsPageState._returnToWarehouse", 1042, 1061), F("_MyTripsPageState._statusColor", 1066, 1077),
    F("_MyTripsPageState._getOrderBgColor", 1081, 1092), F("_MyTripsPageState._getOrderBorderColor", 1094, 1109),
    F("_MyTripsPageState._stopStatusColor", 1111, 1122), C("_StatusPill", 1127, 1151),
    F("_StatusPill.build", 1134, 1150), C("_OutlinePill", 1155, 1186), F("_OutlinePill.build", 1167, 1185)
  ],
  "lib/features/driver_trips/presentation/pages/trip_detail_page.dart": [
    C("TripDetailPage", 12, 19), C("_TripDetailPageState", 21, 521),
    F("_TripDetailPageState.build", 31, 113), F("_TripDetailPageState._buildBody", 115, 351),
    F("_TripDetailPageState._startTrip", 355, 380), F("_TripDetailPageState._returnToWarehouse", 382, 406),
    F("_TripDetailPageState._arriveAtStop", 408, 434), F("_TripDetailPageState._completeStop", 436, 473),
    F("_TripDetailPageState._rejectDelivery", 475, 506), C("_StopTimelineItem", 527, 816),
    F("_StopTimelineItem.build", 559, 619), F("_StopTimelineItem._buildStopCard", 621, 746),
    F("_StopTimelineItem._buildActions", 748, 815), C("_TimeRow", 818, 856), F("_TimeRow.build", 832, 855)
  ],
  "lib/features/driver_trips/presentation/pages/trip_map_page.dart": [
    C("TripMapPage", 15, 22), C("_TripMapPageState", 24, 205),
    F("_TripMapPageState._fitBounds", 39, 54), F("_TripMapPageState.build", 57, 85),
    F("_TripMapPageState._buildMap", 87, 165), F("_TripMapPageState._buildLegend", 167, 188),
    F("_TripMapPageState._legendDot", 190, 204), C("_StopMarker", 207, 267),
    F("_StopMarker.build", 213, 237), F("_StopMarker._showStopInfo", 239, 266),
    C("_WarehouseMarker", 269, 299), F("_WarehouseMarker.build", 271, 298)
  ],
  "lib/features/driver_trips/presentation/state/trip_state.dart": [
    C("MyTripsState", 21, 48), F("MyTripsState.copyWith", 34, 47), C("MyTripsNotifier", 50, 86),
    F("MyTripsNotifier.loadTrips", 57, 81), C("TripCalendarState", 95, 118),
    F("TripCalendarState.copyWith", 106, 117), C("TripCalendarNotifier", 120, 137),
    F("TripCalendarNotifier.loadMonth", 125, 136), C("TripDetailState", 146, 201),
    F("TripDetailState.copyWith", 173, 200), C("TripDetailNotifier", 203, 408),
    F("TripDetailNotifier.loadTrip", 213, 250), F("TripDetailNotifier.startTrip", 254, 268),
    F("TripDetailNotifier.arriveAtStop", 272, 295), F("TripDetailNotifier.completeStop", 299, 319),
    F("TripDetailNotifier.rejectDelivery", 323, 351), F("TripDetailNotifier.returnToWarehouse", 355, 371),
    F("TripDetailNotifier._updateStop", 376, 407), C("ActiveTripState", 421, 470),
    F("ActiveTripState.copyWith", 442, 469), C("ActiveTripNotifier", 472, 592),
    F("ActiveTripNotifier.loadActiveTrip", 479, 505), F("ActiveTripNotifier.startTrip", 507, 521),
    F("ActiveTripNotifier.updateOrderResult", 523, 539), F("ActiveTripNotifier.completeTrip", 541, 570),
    F("ActiveTripNotifier.returnToWarehouse", 572, 589)
  ],
  "lib/features/driver_trips/presentation/widgets/order_result_bottom_sheet.dart": [
    C("OrderResultBottomSheet", 5, 47), F("OrderResultBottomSheet.show", 21, 43),
    C("_OrderResultBottomSheetState", 49, 311), F("_OrderResultBottomSheetState._handleSubmit", 66, 99),
    F("_OrderResultBottomSheetState.build", 102, 267), F("_OrderResultBottomSheetState._buildStatusTile", 269, 310)
  ],
  "lib/features/driver_trips/presentation/widgets/shared_widgets.dart": [
    C("StatusBadge", 4, 40), F("StatusBadge.build", 15, 39), C("InfoRow", 42, 85),
    F("InfoRow.build", 55, 84), C("ErrorBanner", 87, 137), F("ErrorBanner.build", 94, 136),
    C("TimeExceptionBanner", 139, 195), F("TimeExceptionBanner.build", 146, 194),
    C("GoodsRetainedBanner", 197, 227), F("GoodsRetainedBanner.build", 201, 226),
    F("showConfirmDialog", 230, 261, true), F("showSnackBar", 263, 275, true)
  ],
  "lib/features/driver_trips/presentation/widgets/trip_calendar_dialog.dart": [
    C("TripCalendarDialog", 8, 16), C("_TripCalendarDialogState", 18, 221),
    F("_TripCalendarDialogState.build", 57, 205), F("_TripCalendarDialogState._legendDot", 207, 220)
  ],
  "lib/features/exceptions/data/models/exception_item_model.dart": [
    F("ExceptionTypeX.fromRaw", 4, 13), F("ExceptionTypeX.label", 15, 24),
    C("ExceptionItemModel", 27, 97), F("ExceptionItemModel.fromJson", 75, 96),
    C("ExceptionListModel", 99, 123), F("ExceptionListModel.fromJson", 112, 122)
  ],
  "lib/features/exceptions/data/repositories/exception_repository.dart": [
    C("ExceptionRepository", 7, 35), F("ExceptionRepository.getExceptions", 15, 34)
  ],
  "lib/features/exceptions/presentation/pages/my_exceptions_page.dart": [
    C("MyExceptionsPage", 9, 14), C("_MyExceptionsPageState", 16, 260),
    F("_MyExceptionsPageState._pickDate", 38, 48), F("_MyExceptionsPageState.build", 51, 203),
    F("_MyExceptionsPageState._buildBody", 205, 259), C("_FilterDropdown", 262, 302),
    F("_FilterDropdown.build", 276, 301), C("_ExceptionCard", 304, 468),
    F("_ExceptionCard._typeColor", 309, 318), F("_ExceptionCard._typeIcon", 320, 329),
    F("_ExceptionCard.build", 332, 467), C("_StatusPill", 470, 492), F("_StatusPill.build", 476, 491)
  ],
  "lib/features/exceptions/presentation/state/exception_state.dart": [
    C("ExceptionsState", 14, 57), F("ExceptionsState.copyWith", 35, 56),
    C("ExceptionsNotifier", 59, 99), F("ExceptionsNotifier.load", 66, 83)
  ]
};

function humanize(value) {
  return value.replace(/^_/, "").replace(/([a-z0-9])([A-Z])/g, "$1 $2").replaceAll("_", " ").toLowerCase();
}

function ownerAndShort(name) {
  const parts = name.split(".");
  return { owner: parts.length > 1 ? parts.slice(0, -1).join(".") : "module", short: parts.at(-1) };
}

function classSummary(file, name) {
  const clean = name.replace(/^_/, "");
  if (clean.endsWith("Notifier")) return `Riverpod StateNotifier điều phối ${humanize(clean.replace(/Notifier$/, ""))}, gọi repository và cập nhật immutable state theo kết quả async.`;
  if (clean.endsWith("State") && name.startsWith("_")) return `Quản lý widget state, event handlers và quá trình dựng giao diện cho ${path.basename(file, ".dart")}.`;
  if (clean.endsWith("State")) return `Biểu diễn immutable state của ${humanize(clean.replace(/State$/, ""))}, bao gồm dữ liệu, loading flags, filters và lỗi hiển thị.`;
  if (clean.endsWith("Repository")) return `Đóng gói các API operations và chuyển response thành domain models cho ${humanize(clean.replace(/Repository$/, ""))}.`;
  if (clean.endsWith("Page")) return `Widget trang Flutter cho ${humanize(clean.replace(/Page$/, ""))}, cung cấp entry point công khai cho luồng giao diện này.`;
  if (clean.includes("BottomSheet")) return `Widget bottom sheet quản lý form và tương tác người dùng cho ${humanize(clean.replace(/BottomSheet/g, ""))}.`;
  if (clean.endsWith("Model") || clean.endsWith("Result") || clean.endsWith("Request") || clean.endsWith("Info") || clean.endsWith("Summary")) return `Mô hình dữ liệu ${clean} dùng để trao đổi dữ liệu có kiểu giữa API, state và presentation layer.`;
  if (clean === "AppTheme") return "Namespace design system chứa Material theme, brand colors và status presentation helpers của ứng dụng.";
  if (clean === "AuthService") return "Service xác thực quản lý login/logout API và vòng đời credential lưu trong secure storage.";
  if (clean.includes("Banner") || clean.includes("Badge") || clean.includes("Row") || clean.includes("Pill") || clean.includes("Card") || clean.includes("Marker") || clean.includes("Dropdown") || clean.includes("Option") || clean.includes("Timeline")) return `Widget hoặc value object ${clean} đóng gói một thành phần giao diện/tùy chọn tái sử dụng trong luồng tài xế.`;
  return `Định nghĩa ${clean} và trách nhiệm domain/UI tương ứng trong ${path.basename(file)}.`;
}

const exactFunctionSummaries = {
  "formatDateTime": "Định dạng ISO datetime thành HH:mm dd/MM/yyyy và trả raw/fallback khi dữ liệu không parse được.",
  "formatTime": "Định dạng ISO datetime thành HH:mm với fallback an toàn.",
  "formatDate": "Định dạng ISO datetime thành dd/MM/yyyy với fallback an toàn.",
  "formatDelay": "Chuyển số phút trễ thành nhãn đúng giờ hoặc trễ bằng tiếng Việt.",
  "todayForApi": "Tạo ngày hiện tại theo yyyy-MM-dd để gửi API.",
  "decodePolyline": "Giải mã từng cặp delta latitude/longitude trong encoded polyline precision 5 thành LatLng.",
  "decodeMultiLegPolyline": "Tách route polyline nhiều chặng và ghép các điểm đã giải mã theo đúng thứ tự.",
  "login": "Gọi API login, đọc token/roles/user identity, lưu secure session và trả thông tin đăng nhập đã chuẩn hóa.",
  "logout": "Gửi refresh token tới API logout khi có thể và luôn xóa local secure storage trong finally.",
  "showRejectionBottomSheet": "Mở modal bottom sheet nhập lý do từ chối và trả RejectionFormResult khi tài xế xác nhận.",
  "showConfirmDialog": "Hiển thị confirmation dialog có nhãn/màu tùy chỉnh và trả boolean theo lựa chọn người dùng.",
  "showSnackBar": "Hiển thị floating snackbar thành công hoặc lỗi nếu BuildContext vẫn mounted."
};

const apiFunctionSummaries = {
  "getMyTrips": "Tải các chuyến legacy của tài xế theo ngày, tùy chọn status và parse danh sách TripModel.",
  "getMyTripsCalendar": "Tải summary theo tháng để đánh dấu ngày có chuyến và trạng thái hoàn tất trên calendar.",
  "getActiveTrip": "Tải FT-09 execution đang ASSIGNED/IN_PROGRESS và trả null khi backend không có active trip.",
  "getPendingReturnTrips": "Tải các execution đã hoàn tất nhưng tài xế chưa xác nhận xe về kho.",
  "updateOrderResult": "Gửi kết quả giao cho một order và parse lại DriverTripModel đầy đủ từ server.",
  "completeExecution": "Hoàn tất FT-09 execution khi không còn pending order và parse TripOutcomeModel.",
  "getExceptions": "Tải danh sách ngoại lệ tài xế theo ngày, loại và trạng thái resolved.",
  "rejectDelivery": "Gửi yêu cầu từ chối điểm giao legacy, parse response và bảo toàn error mapping.",
  "returnToWarehouse": "Xác nhận xe đã về kho và đồng bộ execution/trip state mới từ backend."
};

function functionSummary(file, name) {
  const { owner, short } = ownerAndShort(name);
  const cleanShort = short.replace(/^_/, "");
  if (exactFunctionSummaries[cleanShort]) return exactFunctionSummaries[cleanShort];
  if (apiFunctionSummaries[cleanShort]) return apiFunctionSummaries[cleanShort];
  if (short === "fromJson") return `Chuyển JSON backend thành ${owner}, áp dụng default values và parse nested fields an toàn.`;
  if (short === "copyWith") return `Tạo bản sao ${owner} với các trường được cập nhật mà không thay đổi state/model hiện tại.`;
  if (short === "toJson") return `Tuần tự hóa ${owner} thành request map phù hợp contract backend.`;
  if (short === "toApiString") return `Chuyển ${owner} enum sang chuỗi trạng thái backend yêu cầu.`;
  if (short === "label") return `Ánh xạ ${owner} sang nhãn tiếng Việt dùng trong giao diện tài xế.`;
  if (short === "build") return `Dựng widget tree của ${owner} từ state và dữ liệu đầu vào hiện tại.`;
  if (cleanShort.startsWith("build")) return `Dựng phần giao diện ${humanize(cleanShort.replace(/^build/, ""))} cho ${owner}.`;
  if (cleanShort.includes("StatusColor") || cleanShort.includes("OrderBgColor") || cleanShort.includes("OrderBorderColor") || cleanShort === "typeColor" || cleanShort === "typeIcon") return `Ánh xạ trạng thái domain sang thuộc tính trình bày nhất quán cho ${owner}.`;
  if (cleanShort === "submit" || cleanShort === "handleSubmit") return `Validate form, thực thi action bất đồng bộ và phản ánh kết quả/lỗi vào state của ${owner}.`;
  if (cleanShort.startsWith("load")) return `Tải ${humanize(cleanShort.replace(/^load/, "")) || "dữ liệu"} qua repository và cập nhật loading/error state của ${owner}.`;
  if (["startTrip", "completeTrip", "arriveAtStop", "completeStop", "rejectDelivery", "returnToWarehouse", "updateOrderResult"].includes(cleanShort)) return `Điều phối action ${humanize(cleanShort)} qua repository, quản lý loading flag và đồng bộ state sau phản hồi.`;
  if (["startTrip", "completeTrip", "returnToWarehouse", "arriveAtStop", "completeStop", "rejectDelivery"].includes(short.replace(/^_/, ""))) return `Yêu cầu xác nhận, gọi notifier cho action ${humanize(cleanShort)} và hiển thị feedback phù hợp.`;
  if (cleanShort === "fitBounds") return "Tính camera bounds từ các tọa độ tuyến đường sau frame hiện tại và điều khiển MapController an toàn.";
  if (cleanShort === "showStopInfo") return "Mở bottom sheet trình bày mã, tên và trạng thái của điểm giao được chọn trên bản đồ.";
  if (cleanShort === "onDateChanged" || cleanShort === "pickDate") return `Cập nhật ngày đang chọn và kích hoạt tải lại dữ liệu phù hợp trong ${owner}.`;
  return `Thực thi logic ${humanize(cleanShort)} của ${owner} trong ${path.basename(file)}.`;
}

function classTags(name) {
  const clean = name.replace(/^_/, "");
  if (clean.endsWith("Notifier")) return ["state-management", "riverpod", "orchestration"];
  if (clean.endsWith("State")) return name.startsWith("_") ? ["widget-state", "ui", "flutter"] : ["state-management", "immutable-state", "riverpod"];
  if (clean.endsWith("Repository")) return ["repository", "api-client", "data-access"];
  if (clean.endsWith("Page")) return ["page", "ui", "flutter"];
  if (clean.endsWith("Model") || clean.endsWith("Result") || clean.endsWith("Request") || clean.endsWith("Info") || clean.endsWith("Summary")) return ["data-model", "domain", "serialization"];
  if (clean.includes("BottomSheet")) return ["component", "bottom-sheet", "form"];
  return ["component", "flutter", "domain"];
}

function functionTags(name) {
  const { short } = ownerAndShort(name);
  const clean = short.replace(/^_/, "");
  if (short === "fromJson" || short === "toJson" || short === "toApiString") return ["serialization", "data-model", "mapping"];
  if (short === "copyWith") return ["immutability", "state-management", "data-model"];
  if (short === "build" || clean.startsWith("build")) return ["ui", "widget", "rendering"];
  if (clean.startsWith("get") || Object.hasOwn(apiFunctionSummaries, clean)) return ["repository", "api-client", "async"];
  if (clean.startsWith("format") || clean === "todayForApi") return ["utility", "formatting", "localization"];
  if (clean.startsWith("decode")) return ["utility", "map", "polyline"];
  if (clean.includes("Status") || clean === "label" || clean === "typeColor" || clean === "typeIcon") return ["status-mapping", "domain", "presentation"];
  if (clean.startsWith("load") || clean.includes("Trip") || clean.includes("Stop") || clean.includes("Order")) return ["state-management", "async", "orchestration"];
  return ["event-handler", "business-logic", "flutter"];
}

function complexity(start, end) {
  const lines = end - start + 1;
  return lines > 200 ? "complex" : lines >= 50 ? "moderate" : "simple";
}

const nodes = [];
const edges = [];
const fileId = (file) => `file:${file}`;

for (const file of input.batchFiles) {
  const meta = fileMeta[file.path];
  if (!meta) throw new Error(`Thiếu semantic metadata cho ${file.path}`);
  nodes.push({
    id: fileId(file.path),
    type: "file",
    name: path.posix.basename(file.path),
    filePath: file.path,
    summary: meta.summary,
    tags: meta.tags,
    complexity: file.sizeLines > 200 ? "complex" : file.sizeLines >= 50 ? "moderate" : "simple",
    languageNotes: meta.languageNotes
      ?? "Mã Dart áp dụng null safety và named parameters; cấu trúc tuân theo conventions của Flutter, Riverpod và immutable models tùy vai trò từng file."
  });

  for (const item of structures[file.path] || []) {
    const id = `${item.type}:${file.path}:${item.name}`;
    nodes.push({
      id,
      type: item.type,
      name: item.name.split(".").at(-1),
      filePath: file.path,
      lineRange: [item.start, item.end],
      summary: item.type === "class" ? classSummary(file.path, item.name) : functionSummary(file.path, item.name),
      tags: item.type === "class" ? classTags(item.name) : functionTags(item.name),
      complexity: complexity(item.start, item.end)
    });
    edges.push({ source: fileId(file.path), target: id, type: "contains", direction: "forward", weight: 1.0 });
    if (item.exported) edges.push({ source: fileId(file.path), target: id, type: "exports", direction: "forward", weight: 0.8 });
  }
}

for (const file of input.batchFiles) {
  for (const target of input.batchImportData[file.path] || []) {
    edges.push({ source: fileId(file.path), target: fileId(target), type: "imports", direction: "forward", weight: 0.7 });
  }
}

const calls = [
  ["function:lib/features/delivery_rejection/presentation/rejection_bottom_sheet.dart:_RejectionBottomSheetState._submit", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showConfirmDialog"],
  ["function:lib/features/driver_trips/presentation/pages/my_trips_page.dart:_MyTripsPageState._startTrip", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showConfirmDialog"],
  ["function:lib/features/driver_trips/presentation/pages/my_trips_page.dart:_MyTripsPageState._startTrip", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showSnackBar"],
  ["function:lib/features/driver_trips/presentation/pages/my_trips_page.dart:_MyTripsPageState._completeTrip", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showConfirmDialog"],
  ["function:lib/features/driver_trips/presentation/pages/my_trips_page.dart:_MyTripsPageState._returnToWarehouse", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showConfirmDialog"],
  ["function:lib/features/driver_trips/presentation/pages/my_trips_page.dart:_MyTripsPageState._returnToWarehouse", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showSnackBar"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._startTrip", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showConfirmDialog"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._startTrip", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showSnackBar"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._returnToWarehouse", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showConfirmDialog"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._returnToWarehouse", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showSnackBar"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._arriveAtStop", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showConfirmDialog"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._arriveAtStop", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showSnackBar"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._completeStop", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showConfirmDialog"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._completeStop", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showSnackBar"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._rejectDelivery", "function:lib/features/delivery_rejection/presentation/rejection_bottom_sheet.dart:showRejectionBottomSheet"],
  ["function:lib/features/driver_trips/presentation/pages/trip_detail_page.dart:_TripDetailPageState._rejectDelivery", "function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:showSnackBar"],
  ["function:lib/features/driver_trips/presentation/pages/trip_map_page.dart:_TripMapPageState._buildMap", "function:lib/core/utils/polyline_decoder.dart:decodeMultiLegPolyline"],
  ["function:lib/features/driver_trips/presentation/state/trip_state.dart:MyTripsNotifier.loadTrips", "function:lib/features/driver_trips/data/repositories/trip_repository.dart:TripRepository.getMyTrips"],
  ["function:lib/features/driver_trips/presentation/state/trip_state.dart:TripCalendarNotifier.loadMonth", "function:lib/features/driver_trips/data/repositories/trip_repository.dart:TripRepository.getMyTripsCalendar"],
  ["function:lib/features/driver_trips/presentation/state/trip_state.dart:TripDetailNotifier.rejectDelivery", "function:lib/features/driver_trips/data/repositories/trip_repository.dart:TripRepository.rejectDelivery"],
  ["function:lib/features/driver_trips/presentation/state/trip_state.dart:ActiveTripNotifier.loadActiveTrip", "function:lib/features/driver_trips/data/repositories/trip_repository.dart:DriverTripRepository.getActiveTrip"],
  ["function:lib/features/driver_trips/presentation/state/trip_state.dart:ActiveTripNotifier.loadActiveTrip", "function:lib/features/driver_trips/data/repositories/trip_repository.dart:DriverTripRepository.getPendingReturnTrips"],
  ["function:lib/features/driver_trips/presentation/state/trip_state.dart:ActiveTripNotifier.updateOrderResult", "function:lib/features/driver_trips/data/repositories/trip_repository.dart:DriverTripRepository.updateOrderResult"],
  ["function:lib/features/driver_trips/presentation/state/trip_state.dart:ActiveTripNotifier.completeTrip", "function:lib/features/driver_trips/data/repositories/trip_repository.dart:DriverTripRepository.completeExecution"],
  ["function:lib/features/driver_trips/presentation/state/trip_state.dart:ActiveTripNotifier.returnToWarehouse", "function:lib/features/driver_trips/data/repositories/trip_repository.dart:DriverTripRepository.returnToWarehouse"],
  ["function:lib/features/exceptions/presentation/state/exception_state.dart:ExceptionsNotifier.load", "function:lib/features/exceptions/data/repositories/exception_repository.dart:ExceptionRepository.getExceptions"],
  ["function:lib/features/exceptions/presentation/pages/my_exceptions_page.dart:_ExceptionCard.build", "function:lib/core/utils/date_time_utils.dart:formatTime"],
  ["function:lib/features/exceptions/presentation/pages/my_exceptions_page.dart:_ExceptionCard.build", "function:lib/core/utils/date_time_utils.dart:formatDelay"],
  ["function:lib/features/exceptions/presentation/pages/my_exceptions_page.dart:_ExceptionCard.build", "function:lib/core/utils/date_time_utils.dart:formatDateTime"],
  ["function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:StatusBadge.build", "function:lib/core/theme/app_theme.dart:AppTheme.tripStatusColor"],
  ["function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:StatusBadge.build", "function:lib/core/theme/app_theme.dart:AppTheme.stopStatusColor"],
  ["function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:StatusBadge.build", "function:lib/core/theme/app_theme.dart:AppTheme.tripStatusLabel"],
  ["function:lib/features/driver_trips/presentation/widgets/shared_widgets.dart:StatusBadge.build", "function:lib/core/theme/app_theme.dart:AppTheme.stopStatusLabel"]
];
for (const [source, target] of calls) edges.push({ source, target, type: "calls", direction: "forward", weight: 0.8 });

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify({ nodes, edges }, null, 2)}\n`, "utf8");
const counts = (items, key) => items.reduce((acc, item) => (acc[item[key]] = (acc[item[key]] || 0) + 1, acc), {});
process.stdout.write(`${JSON.stringify({ nodes: nodes.length, nodeTypes: counts(nodes, "type"), edges: edges.length, edgeTypes: counts(edges, "type") })}\n`);
