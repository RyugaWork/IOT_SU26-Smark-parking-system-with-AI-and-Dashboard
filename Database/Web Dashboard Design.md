Chủ nhân, dưới đây là kế hoạch thiết kế Web Dashboard chi tiết từ đầu cho hệ thống Smart Parking System with AI, bám sát backend FastAPI mà mình đang thiết kế trước đó.

Kế hoạch thiết kế Web Dashboard — Smart Parking System with AI
1. Mục tiêu của Web Dashboard

Web Dashboard dùng để demo cho giảng viên thấy hệ thống có đủ các phần:

1. Theo dõi số xe trong bãi.
2. Xem lịch sử xe vào / ra.
3. Xem ảnh chụp từ ESP32-CAM.
4. Xem kết quả AI YOLO.
5. Điều khiển cổng mở / đóng từ web.
6. Kiểm tra trạng thái camera, sensor, gate.

Web Dashboard không xử lý AI trực tiếp và không kết nối trực tiếp SQL Server.

Luồng đúng là:

React Web Dashboard
        ↓ gọi REST API
FastAPI Backend
        ↓ xử lý logic
SQL Server + uploads folder
        ↓
Dữ liệu trả về dashboard
2. Công nghệ đề xuất
2.1 Frontend

Nên dùng:

React + Vite
React Router DOM
Axios
Bootstrap 5

Lý do:

React + Vite       → nhẹ, dễ chạy, dễ demo
React Router DOM   → chia nhiều trang dashboard
Axios              → gọi API FastAPI dễ
Bootstrap 5        → làm giao diện nhanh, đẹp vừa đủ

Không nên dùng Next.js cho bài này vì hơi dư. Không nên dùng HTML/CSS/JS thuần nếu muốn chia page và component rõ ràng.

2.2 Backend tương thích

Backend hiện tại của Chủ nhân dùng FastAPI là hợp lý:

smart-parking-backend/
├── app/
│   ├── api/v1/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   └── database.py
├── uploads/
└── main.py

Dashboard chỉ cần backend cung cấp API ổn định.

3. Kiến trúc tổng thể Web Dashboard
ESP32-CAM / Arduino / Sensor
            ↓
        FastAPI Backend
            ↓
 SQL Server + uploads/images
            ↓
     React Web Dashboard

Frontend sẽ làm 5 trang chính:

1. Overview
2. Parking Logs
3. Live Feed
4. Gate Control
5. AI Detection

Layout tổng thể:

+------------------------------------------------------+
| Topbar: Smart Parking System with AI                 |
+----------------------+-------------------------------+
| Sidebar              | Main Content                  |
|                      |                               |
| - Overview           | Page content                  |
| - Parking Logs       |                               |
| - Live Feed          |                               |
| - Gate Control       |                               |
| - AI Detection       |                               |
+----------------------+-------------------------------+
4. Cấu trúc project frontend đề xuất

Nên tạo project riêng, không để chung vào backend.

smart-parking-system/
│
├── smart-parking-backend/
│   └── FastAPI backend
│
└── smart-parking-dashboard/
    └── React frontend

Cấu trúc frontend:

smart-parking-dashboard/
│
├── src/
│   ├── api/
│   │   ├── axiosClient.js
│   │   ├── dashboardApi.js
│   │   ├── vehicleEventApi.js
│   │   ├── imageApi.js
│   │   ├── gateApi.js
│   │   └── detectionApi.js
│   │
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.jsx
│   │   │   ├── Topbar.jsx
│   │   │   └── MainLayout.jsx
│   │   │
│   │   ├── common/
│   │   │   ├── StatCard.jsx
│   │   │   ├── StatusBadge.jsx
│   │   │   ├── Loading.jsx
│   │   │   ├── ErrorBox.jsx
│   │   │   └── ImagePreviewModal.jsx
│   │   │
│   │   ├── overview/
│   │   │   ├── OverviewStats.jsx
│   │   │   ├── CameraStatusPanel.jsx
│   │   │   └── RecentLogsTable.jsx
│   │   │
│   │   ├── logs/
│   │   │   ├── ParkingLogTable.jsx
│   │   │   └── ParkingLogFilter.jsx
│   │   │
│   │   ├── live/
│   │   │   └── CameraFeedCard.jsx
│   │   │
│   │   ├── gate/
│   │   │   ├── GateStatusPanel.jsx
│   │   │   ├── GateControlButtons.jsx
│   │   │   └── GateCommandTable.jsx
│   │   │
│   │   └── detection/
│   │       ├── LatestDetectionCard.jsx
│   │       └── DetectionHistoryTable.jsx
│   │
│   ├── pages/
│   │   ├── OverviewPage.jsx
│   │   ├── ParkingLogsPage.jsx
│   │   ├── LiveFeedPage.jsx
│   │   ├── GateControlPage.jsx
│   │   └── AiDetectionPage.jsx
│   │
│   ├── config.js
│   ├── App.jsx
│   └── main.jsx
│
├── .env
├── package.json
└── vite.config.js
5. Trang 1 — Overview Page
5.1 Mục tiêu

Trang Overview là trang quan trọng nhất để demo. Khi mở dashboard lên, giảng viên phải thấy ngay:

- Trong bãi đang có bao nhiêu xe.
- Hôm nay có bao nhiêu xe vào.
- Hôm nay có bao nhiêu xe ra.
- Cổng đang mở hay đóng.
- Camera entry / exit đang online hay offline.
- Một vài log gần nhất.
5.2 Layout đề xuất
Overview Page

[Total Vehicles Inside] [Entries Today] [Exits Today] [Gate Status]

[Entry Camera Status] [Exit Camera Status] [Entry Sensor] [Exit Sensor]

[Latest Entry Image]  [Latest Exit Image]

Recent Parking Logs
---------------------------------------------------------
| Plate | Direction | Entry Time | Exit Time | Confidence |
---------------------------------------------------------
5.3 Component cần dùng
OverviewPage.jsx
OverviewStats.jsx
StatCard.jsx
StatusBadge.jsx
CameraStatusPanel.jsx
RecentLogsTable.jsx
5.4 API cần gọi
GET /api/v1/dashboard/overview

Response mẫu:

{
  "total_vehicles_inside": 12,
  "entries_today": 25,
  "exits_today": 13,
  "gate_status": "CLOSE",
  "entry_camera_status": "ONLINE",
  "exit_camera_status": "ONLINE",
  "entry_sensor_status": "ACTIVE",
  "exit_sensor_status": "ACTIVE",
  "last_updated": "2026-06-08T15:30:00"
}

API log gần nhất:

GET /api/v1/vehicle-events/recent?limit=5

Response mẫu:

[
  {
    "event_id": 101,
    "plate_number": "59A-12345",
    "direction": "ENTRY",
    "entry_time": "2026-06-08T15:20:00",
    "exit_time": null,
    "image_url": "/uploads/entry/entry_101.jpg",
    "confidence_score": 0.91
  }
]
5.5 Ghi chú thiết kế

Trang Overview nên dùng polling mỗi 5 giây:

Cứ 5 giây gọi lại API để cập nhật số liệu.

Không cần WebSocket ngay từ đầu. Polling dễ demo và dễ debug hơn.

6. Trang 2 — Parking Logs Page
6.1 Mục tiêu

Trang này dùng để xem lịch sử xe vào / ra.

Cần hiển thị:

- Biển số xe nếu nhận dạng được.
- Hướng di chuyển: ENTRY hoặc EXIT.
- Thời gian vào.
- Thời gian ra.
- Ảnh chụp.
- Confidence score.
- Kết quả nhận dạng xe / biển số.
6.2 Layout đề xuất
Parking Logs Page

[Search Plate] [Filter Direction: ALL/ENTRY/EXIT] [Date] [Search Button]

---------------------------------------------------------------------------
| ID | Plate | Direction | Entry Time | Exit Time | Image | Confidence |
---------------------------------------------------------------------------
| 1  | 59A...| ENTRY     | ...        | -         | View  | 91%        |
---------------------------------------------------------------------------
6.3 Component cần dùng
ParkingLogsPage.jsx
ParkingLogFilter.jsx
ParkingLogTable.jsx
StatusBadge.jsx
ImagePreviewModal.jsx
6.4 API cần gọi
GET /api/v1/vehicle-events

Có filter:

GET /api/v1/vehicle-events?direction=ENTRY&date=2026-06-08&plate=59A

Response mẫu:

{
  "data": [
    {
      "event_id": 101,
      "plate_number": "59A-12345",
      "direction": "ENTRY",
      "entry_time": "2026-06-08T15:20:00",
      "exit_time": null,
      "image_url": "/uploads/entry/entry_101.jpg",
      "vehicle_detected": true,
      "license_plate_detected": true,
      "confidence_score": 0.91
    }
  ],
  "total": 1
}
6.5 Bảng dữ liệu trên UI
Cột	Ý nghĩa
Event ID	Mã sự kiện
Plate Number	Biển số xe
Direction	ENTRY / EXIT
Entry Time	Thời gian vào
Exit Time	Thời gian ra
Image	Ảnh từ ESP32-CAM
Confidence	Độ tin cậy AI
6.6 Ghi chú thiết kế

Ảnh trong bảng chỉ nên hiển thị dạng nút:

[View Image]

Khi bấm thì mở modal ảnh lớn. Không nên nhét ảnh lớn trực tiếp vào bảng vì sẽ rối giao diện.

7. Trang 3 — Live Feed Page
7.1 Mục tiêu

Hiển thị ảnh mới nhất hoặc stream từ ESP32-CAM.

Với bài IoT102, nên làm theo thứ tự:

Phase 1: Hiển thị ảnh mới nhất từ camera.
Phase 2: Nếu còn thời gian, làm MJPEG stream.

Không nên bắt đầu bằng live stream ngay vì ESP32-CAM stream dễ lỗi, khó debug.

7.2 Layout đề xuất
Live Feed Page

Entry Camera
+----------------------------------+
| Latest Entry Image               |
+----------------------------------+
Status: ONLINE
Last captured: 2026-06-08 15:35:00

Exit Camera
+----------------------------------+
| Latest Exit Image                |
+----------------------------------+
Status: ONLINE
Last captured: 2026-06-08 15:35:05
7.3 Component cần dùng
LiveFeedPage.jsx
CameraFeedCard.jsx
StatusBadge.jsx
Loading.jsx
7.4 API lấy ảnh mới nhất
GET /api/v1/images/latest

Response mẫu:

{
  "entry": {
    "image_id": 1,
    "camera_id": "CAM_ENTRY_01",
    "image_url": "/uploads/entry/latest_entry.jpg",
    "status": "ONLINE",
    "captured_at": "2026-06-08T15:35:00"
  },
  "exit": {
    "image_id": 2,
    "camera_id": "CAM_EXIT_01",
    "image_url": "/uploads/exit/latest_exit.jpg",
    "status": "ONLINE",
    "captured_at": "2026-06-08T15:35:05"
  }
}
7.5 Nếu dùng stream

Backend có thể cung cấp:

GET /api/v1/images/entry/stream
GET /api/v1/images/exit/stream

Frontend dùng:

<img src="http://localhost:8000/api/v1/images/entry/stream" />
<img src="http://localhost:8000/api/v1/images/exit/stream" />

Nhưng phần này nên để sau.

7.6 Ghi chú thiết kế

Nên refresh ảnh mỗi 3 giây:

GET /api/v1/images/latest

Nếu ảnh không đổi, thêm timestamp vào URL để tránh trình duyệt cache:

const imageUrl = `${API_BASE_URL}${image.image_url}?t=${Date.now()}`;
8. Trang 4 — Gate Control Page
8.1 Mục tiêu

Cho phép người dùng điều khiển cổng từ dashboard.

Cần có:

- Trạng thái cổng hiện tại: OPEN / CLOSE.
- Nút Open Gate.
- Nút Close Gate.
- Lịch sử lệnh điều khiển.
8.2 Layout đề xuất
Gate Control Page

Current Gate Status: CLOSE

[Open Gate] [Close Gate]

Gate Command History
----------------------------------------------------------------
| Command ID | Gate | Command | Source | Status | Created At |
----------------------------------------------------------------
8.3 Component cần dùng
GateControlPage.jsx
GateStatusPanel.jsx
GateControlButtons.jsx
GateCommandTable.jsx
StatusBadge.jsx
8.4 API lấy trạng thái cổng
GET /api/v1/gates/status

Response mẫu:

{
  "gate_id": "GATE_ENTRY",
  "status": "CLOSE",
  "last_command": "CLOSE",
  "updated_at": "2026-06-08T15:38:00"
}
8.5 API gửi lệnh mở / đóng cổng
POST /api/v1/gates/commands

Request mở cổng:

{
  "gate_id": "GATE_ENTRY",
  "command": "OPEN",
  "source": "DASHBOARD"
}

Request đóng cổng:

{
  "gate_id": "GATE_ENTRY",
  "command": "CLOSE",
  "source": "DASHBOARD"
}

Response mẫu:

{
  "command_id": 501,
  "gate_id": "GATE_ENTRY",
  "command": "OPEN",
  "source": "DASHBOARD",
  "status": "PENDING",
  "created_at": "2026-06-08T15:40:00"
}
8.6 API lấy lịch sử lệnh
GET /api/v1/gates/commands

Response mẫu:

[
  {
    "command_id": 501,
    "gate_id": "GATE_ENTRY",
    "command": "OPEN",
    "source": "DASHBOARD",
    "status": "DONE",
    "created_at": "2026-06-08T15:40:00",
    "executed_at": "2026-06-08T15:40:03"
  }
]
8.7 Logic khi bấm nút

Luồng xử lý:

User bấm Open Gate
        ↓
Frontend gọi POST /api/v1/gates/commands
        ↓
Backend lưu command vào gate_command
        ↓
Arduino / ESP32 lấy command hoặc backend gửi command
        ↓
Servo mở cổng
        ↓
Backend cập nhật command DONE
        ↓
Dashboard reload status + command history
8.8 Ghi chú thiết kế

Khi bấm nút nên có confirm đơn giản:

Are you sure you want to open the gate?

Tránh bấm nhầm trong lúc demo.

9. Trang 5 — AI Detection Page
9.1 Mục tiêu

Trang này dùng để chứng minh AI YOLO đang hoạt động.

Cần hiển thị:

- Kết quả YOLO gần nhất.
- Có phát hiện xe không.
- Có phát hiện biển số không.
- Biển số nhận dạng được.
- Confidence score.
- Ảnh đã detect.
- Lịch sử detection.
9.2 Layout đề xuất
AI Detection Page

Latest Detection Result

Vehicle Detected: TRUE
License Plate Detected: TRUE
Plate Number: 59A-12345
Confidence Score: 91%
Camera: ENTRY
Detected At: 2026-06-08 15:45:00

[Detected Image]

Detection History
---------------------------------------------------------------------
| ID | Camera | Vehicle | Plate Detected | Plate | Confidence | Time |
---------------------------------------------------------------------
9.3 Component cần dùng
AiDetectionPage.jsx
LatestDetectionCard.jsx
DetectionHistoryTable.jsx
StatusBadge.jsx
ImagePreviewModal.jsx
9.4 API lấy detection mới nhất
GET /api/v1/detections/latest

Response mẫu:

{
  "detection_id": 301,
  "camera_id": "CAM_ENTRY_01",
  "vehicle_detected": true,
  "license_plate_detected": true,
  "plate_number": "59A-12345",
  "confidence_score": 0.91,
  "image_url": "/uploads/detection/detection_301.jpg",
  "detected_at": "2026-06-08T15:45:00"
}
9.5 API lấy lịch sử detection
GET /api/v1/detections?limit=20

Response mẫu:

[
  {
    "detection_id": 301,
    "camera_id": "CAM_ENTRY_01",
    "vehicle_detected": true,
    "license_plate_detected": true,
    "plate_number": "59A-12345",
    "confidence_score": 0.91,
    "image_url": "/uploads/detection/detection_301.jpg",
    "detected_at": "2026-06-08T15:45:00"
  }
]
10. Danh sách API tổng hợp cho frontend
Page	API	Method	Mục đích
Overview	/api/v1/dashboard/overview	GET	Lấy thống kê tổng quan
Overview	/api/v1/vehicle-events/recent?limit=5	GET	Lấy log gần nhất
Parking Logs	/api/v1/vehicle-events	GET	Lấy lịch sử xe
Live Feed	/api/v1/images/latest	GET	Lấy ảnh mới nhất
Live Feed	/api/v1/images/entry/stream	GET	Stream camera entry
Live Feed	/api/v1/images/exit/stream	GET	Stream camera exit
Gate Control	/api/v1/gates/status	GET	Lấy trạng thái cổng
Gate Control	/api/v1/gates/commands	POST	Gửi lệnh mở / đóng
Gate Control	/api/v1/gates/commands	GET	Lấy lịch sử lệnh
AI Detection	/api/v1/detections/latest	GET	Lấy detection mới nhất
AI Detection	/api/v1/detections	GET	Lấy lịch sử detection
11. Kết nối frontend với backend FastAPI
11.1 File .env frontend
VITE_API_BASE_URL=http://localhost:8000
11.2 File src/config.js
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;
11.3 File src/api/axiosClient.js
import axios from "axios";
import { API_BASE_URL } from "../config";

const axiosClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
  timeout: 10000,
});

export default axiosClient;
11.4 Ví dụ API file

File src/api/dashboardApi.js:

import axiosClient from "./axiosClient";

export const getOverview = async () => {
  const response = await axiosClient.get("/api/v1/dashboard/overview");
  return response.data;
};

export const getRecentVehicleEvents = async (limit = 5) => {
  const response = await axiosClient.get(`/api/v1/vehicle-events/recent?limit=${limit}`);
  return response.data;
};

File src/api/gateApi.js:

import axiosClient from "./axiosClient";

export const getGateStatus = async () => {
  const response = await axiosClient.get("/api/v1/gates/status");
  return response.data;
};

export const sendGateCommand = async (gateId, command) => {
  const response = await axiosClient.post("/api/v1/gates/commands", {
    gate_id: gateId,
    command: command,
    source: "DASHBOARD",
  });

  return response.data;
};

export const getGateCommands = async () => {
  const response = await axiosClient.get("/api/v1/gates/commands");
  return response.data;
};
12. Backend FastAPI cần chuẩn bị cho frontend

Trong main.py, backend cần bật CORS:

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

app = FastAPI(title="Smart Parking Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

Lý do cần app.mount("/uploads", ...):

Frontend cần hiển thị ảnh từ ESP32-CAM.
Database chỉ lưu image_path.
FastAPI public folder uploads để React load ảnh.

Ví dụ frontend hiển thị ảnh:

const fullImageUrl = `${API_BASE_URL}${image.image_url}`;

Nếu image_url là:

/uploads/entry/entry_001.jpg

Thì ảnh đầy đủ là:

http://localhost:8000/uploads/entry/entry_001.jpg
13. State management

Với dashboard này, chưa cần Redux.

Chỉ cần:

useState
useEffect
Axios API functions

Ví dụ logic chung cho mỗi page:

1. Page load.
2. Gọi API.
3. Set data vào state.
4. Hiển thị Loading nếu chưa có data.
5. Hiển thị Error nếu API lỗi.
6. Polling mỗi 3–5 giây nếu cần realtime.

Các page nên polling:

Page	Có polling không?	Chu kỳ
Overview	Có	5 giây
Live Feed	Có	3 giây
Gate Control	Có	5 giây
AI Detection	Có	3–5 giây
Parking Logs	Không bắt buộc	Chỉ reload khi filter
14. Màu sắc và UI style đề xuất

Nên làm giao diện đơn giản:

Background: xám nhạt
Sidebar: xanh đậm hoặc đen
Card: trắng
Status OPEN: xanh lá
Status CLOSE: đỏ
ONLINE: xanh lá
OFFLINE: xám hoặc đỏ
ENTRY: xanh dương
EXIT: cam

Badge status:

OPEN    → green badge
CLOSE   → red badge
ONLINE  → green badge
OFFLINE → gray/red badge
ENTRY   → blue badge
EXIT    → orange badge

Không cần animation phức tạp. Giao diện cần rõ, dễ nhìn, dễ giải thích.

15. Thứ tự triển khai hợp lý
Phase 1 — Setup frontend project

Mục tiêu: chạy được React dashboard rỗng.

Cần làm:

1. Tạo project React Vite.
2. Cài React Router DOM.
3. Cài Axios.
4. Cài Bootstrap.
5. Tạo MainLayout, Sidebar, Topbar.
6. Tạo 5 page rỗng.

Kết quả phase 1:

Mở localhost:5173 thấy dashboard có sidebar và chuyển trang được.
Phase 2 — Kết nối API cơ bản

Mục tiêu: frontend gọi được FastAPI.

Cần làm:

1. Tạo axiosClient.js.
2. Tạo .env VITE_API_BASE_URL.
3. Backend bật CORS.
4. Test gọi GET /api/v1/dashboard/overview.
5. Hiển thị dữ liệu Overview lên card.

Kết quả phase 2:

Overview Page hiển thị được số xe, lượt vào, lượt ra, trạng thái cổng.
Phase 3 — Làm Overview hoàn chỉnh

Cần làm:

1. OverviewStats.
2. CameraStatusPanel.
3. RecentLogsTable.
4. Polling mỗi 5 giây.
5. Loading và Error UI.

Kết quả phase 3:

Trang Overview có thể dùng để demo tổng quan.
Phase 4 — Làm Parking Logs

Cần làm:

1. Tạo ParkingLogTable.
2. Tạo filter theo direction, date, plate.
3. Gọi GET /api/v1/vehicle-events.
4. Hiển thị ảnh bằng modal.
5. Format confidence score thành phần trăm.

Kết quả phase 4:

Xem được lịch sử xe vào / ra từ SQL Server.
Phase 5 — Làm Gate Control

Cần làm:

1. Hiển thị trạng thái cổng.
2. Làm nút Open Gate.
3. Làm nút Close Gate.
4. Gọi POST /api/v1/gates/commands.
5. Hiển thị lịch sử command.
6. Reload sau khi gửi command.

Kết quả phase 5:

Dashboard có thể gửi lệnh điều khiển cổng.
Phase 6 — Làm AI Detection

Cần làm:

1. Gọi GET /api/v1/detections/latest.
2. Hiển thị vehicle_detected.
3. Hiển thị license_plate_detected.
4. Hiển thị plate_number.
5. Hiển thị confidence score.
6. Hiển thị ảnh detection.
7. Hiển thị detection history.

Kết quả phase 6:

Trang AI Detection chứng minh YOLO trả kết quả về backend.
Phase 7 — Làm Live Feed

Cần làm theo bản dễ trước:

1. Gọi GET /api/v1/images/latest.
2. Hiển thị ảnh latest_entry.
3. Hiển thị ảnh latest_exit.
4. Polling mỗi 3 giây.

Sau đó nếu còn thời gian:

1. Thêm MJPEG stream endpoint.
2. Hiển thị stream bằng thẻ img.

Kết quả phase 7:

Dashboard xem được ảnh mới nhất từ ESP32-CAM.
16. Quy tắc xử lý lỗi trên giao diện

Dashboard cần xử lý các lỗi cơ bản:

1. Backend tắt.
2. API timeout.
3. Chưa có ảnh.
4. Chưa có detection.
5. Chưa có parking logs.
6. Gate command gửi thất bại.

Ví dụ hiển thị:

Backend Offline
No image available
No detection data yet
Failed to send gate command

Không nên để màn hình trắng khi API lỗi.

17. Dữ liệu mock để demo nếu backend chưa xong

Trong lúc backend chưa hoàn chỉnh, frontend có thể dùng mock data.

Ví dụ:

export const mockOverview = {
  total_vehicles_inside: 12,
  entries_today: 25,
  exits_today: 13,
  gate_status: "CLOSE",
  entry_camera_status: "ONLINE",
  exit_camera_status: "ONLINE",
  entry_sensor_status: "ACTIVE",
  exit_sensor_status: "ACTIVE",
  last_updated: "2026-06-08T15:30:00",
};

Cách làm tốt:

1. Làm UI bằng mock data trước.
2. Khi backend API xong thì thay mock bằng Axios.
3. Không đợi backend xong mới làm frontend.
18. Checklist hoàn thành Web Dashboard

Dashboard được xem là hoàn thành khi có đủ:

[ ] Có layout Sidebar + Topbar.
[ ] Có 5 page: Overview, Parking Logs, Live Feed, Gate Control, AI Detection.
[ ] Overview hiển thị số xe, lượt vào, lượt ra, trạng thái gate/camera/sensor.
[ ] Parking Logs hiển thị bảng lịch sử xe.
[ ] Parking Logs xem được ảnh chụp.
[ ] Live Feed hiển thị ảnh mới nhất từ entry/exit camera.
[ ] Gate Control gửi được OPEN/CLOSE command.
[ ] Gate Control xem được command history.
[ ] AI Detection hiển thị kết quả YOLO mới nhất.
[ ] Frontend gọi được FastAPI qua Axios.
[ ] Backend bật CORS.
[ ] Backend public được folder uploads.
[ ] Có Loading UI.
[ ] Có Error UI.
[ ] Có polling cho dữ liệu realtime.
19. Kế hoạch làm demo tốt nhất

Nếu thời gian ít, Chủ nhân nên ưu tiên làm theo thứ tự này:

1. Overview Page
2. Parking Logs Page
3. Gate Control Page
4. AI Detection Page
5. Live Feed Page

Lý do:

Overview Page      → giảng viên thấy toàn cảnh hệ thống.
Parking Logs       → chứng minh có database.
Gate Control       → chứng minh web điều khiển phần cứng.
AI Detection       → chứng minh có YOLO.
Live Feed          → đẹp nhưng dễ lỗi, nên làm sau.
20. Thiết kế cuối cùng nên chốt

Chốt thiết kế Web Dashboard:

Frontend:
React + Vite + Bootstrap + Axios + React Router DOM

Backend:
FastAPI + SQL Server + uploads folder

Realtime:
Polling 3–5 giây

Ảnh:
ESP32-CAM gửi ảnh lên backend.
Backend lưu ảnh vào uploads/.
SQL Server chỉ lưu image_path.
Frontend lấy image_url từ API và hiển thị.

AI:
YOLO xử lý ảnh.
Backend lưu detection result.
Frontend hiển thị latest detection và detection history.

Gate:
Frontend gửi OPEN/CLOSE command.
Backend lưu gate_command.
Arduino/ESP32 nhận command và điều khiển servo.
