# SMART PARKING PRESENTATION – INDIVIDUAL SCRIPT

**Project:** A Smart Parking System with Vehicle Detection and Barrier Control  
**Course:** IOT102 – Group 7  
**Presentation language:** Vietnamese

---

# 4. Đỗ Thành Triết – Slide 3–5

## Slide 3 – Background / Problem Context

### Script

> Trong các bãi xe nhỏ, việc kiểm soát xe ra vào vẫn thường phụ thuộc vào nhân viên vận hành. Quá trình kiểm tra có thể chậm, dữ liệu không được lưu đầy đủ và người quản lý khó theo dõi trạng thái theo thời gian thực.  
>  
> Ngoài ra, nếu chỉ dùng một cơ chế mở cổng đơn giản thì hệ thống không có ảnh xác minh, không có lịch sử sự kiện và khó kiểm tra lại khi có vấn đề.  
>  
> Vì vậy, nhóm đề xuất một hệ thống có thể tự động phát hiện, xác minh, điều khiển barrier và lưu dữ liệu tập trung.

### Kiến thức cần nắm

- Problem không phải chỉ là “không có chỗ đậu”.
- Project của nhóm tập trung vào gate control, không phải slot navigation.
- Các vấn đề chính:
  - manual operation;
  - slow checking;
  - weak traceability;
  - no centralized monitoring;
  - difficult event review.

### Câu hỏi có thể được hỏi

#### Câu: Tại sao không chỉ dùng camera?

**Trả lời:**

> Camera có thể xác minh phương tiện nhưng việc chụp ảnh, truyền qua Wi-Fi và xử lý YOLO tốn thời gian hơn. Ultrasonic được dùng làm trigger nhanh và chi phí thấp. Camera chỉ hoạt động khi cảm biến phát hiện vật thể, giúp giảm số lần xử lý không cần thiết.

---

## Slide 4 – Limitations of Traditional System

### Script

> Hệ thống truyền thống có năm hạn chế chính.  
>  
> Thứ nhất, việc kiểm tra thủ công dễ gây chậm tại cổng.  
> Thứ hai, trạng thái cổng và lịch sử xe thường không được lưu tự động.  
> Thứ ba, hệ thống thiếu hình ảnh để xác minh sự kiện.  
> Thứ tư, người quản lý không có dashboard để theo dõi từ một nơi tập trung.  
> Và cuối cùng, việc kiểm tra lại sự cố hoặc đối chiếu lịch sử mất nhiều thời gian.  
>  
> Những hạn chế này dẫn đến ùn tắc tại cổng, sai sót con người và khả năng truy vết thấp.

### Kiến thức cần nắm

- Không nên nói “hệ thống truyền thống hoàn toàn không an toàn”.
- Nên dùng từ:
  - limited verification;
  - limited traceability;
  - inefficient monitoring.
- Chỉ nói “improve security” khi có dữ liệu kiểm thử bảo mật. Nếu không, nói “improve verification”.

### Câu hỏi có thể được hỏi

#### Câu: Hệ thống của nhóm giải quyết được toàn bộ các hạn chế này không?

**Trả lời:**

> Hệ thống giải quyết ở mức prototype: tự động phát hiện, có hình ảnh xác minh, lưu log, cập nhật occupancy và hiển thị dashboard. Tuy nhiên, hệ thống chưa xử lý license plate recognition, thanh toán hoặc xác thực người dùng nâng cao.

---

## Slide 5 – Objectives, Solution and Scope

### Script

> Mục tiêu của nhóm là phát triển một prototype IoT chi phí thấp cho bãi xe quy mô nhỏ.  
>  
> Hệ thống có ba nhóm chức năng chính.  
>  
> Nhóm đầu tiên là **Detection**, sử dụng HC-SR04 để phát hiện vật thể và ESP32-CAM để chụp ảnh.  
>  
> Nhóm thứ hai là **Processing**, ảnh được gửi đến FastAPI server để YOLO xác minh xem có phương tiện thuộc class được chấp nhận hay không. Server sau đó trả về quyết định OPEN hoặc CLOSE.  
>  
> Nhóm thứ ba là **Management**, Arduino Master điều khiển barrier, dữ liệu được lưu trong SQL Server và hiển thị trên dashboard.  
>  
> Scope của hệ thống gồm gate-level detection, camera verification, barrier control, occupancy tracking, event logging và dashboard monitoring.  
>  
> Các chức năng như nhận diện biển số, xác định từng slot đỗ xe, reservation và payment chưa nằm trong phạm vi hiện tại.

### Kiến thức cần nắm

### In scope

- Entry/exit detection.
- ESP32-CAM image capture.
- YOLO vehicle verification.
- OPEN/CLOSE decision.
- Servo barrier control.
- Occupancy update.
- SQL logging.
- Dashboard monitoring.

### Out of scope

- License plate recognition.
- Parking-slot detection.
- Reservation.
- Payment.
- Mobile application.
- Commercial deployment.

### Câu hỏi có thể được hỏi

#### Câu 1: Tại sao gọi là smart parking nếu không có slot detection?

**Trả lời:**

> Smart parking là khái niệm rộng. Hệ thống của nhóm tập trung vào smart gate monitoring và parking occupancy management. Nó có tự động phát hiện, AI verification, điều khiển barrier, lưu dữ liệu và dashboard. Slot-level detection chỉ là một hướng mở rộng.

#### Câu 2: Tại sao chọn HC-SR04?

**Trả lời:**

> HC-SR04 có chi phí thấp, dễ tích hợp với Arduino và phù hợp cho prototype đo khoảng cách. Tuy nhiên, cảm biến không xác định được loại vật thể, nên nhóm bổ sung camera và YOLO làm lớp xác minh thứ hai.

#### Câu 3: Hướng giải quyết chính là gì?

**Trả lời:**

> Hướng giải quyết là hybrid detection. Ultrasonic làm trigger nhanh, camera cung cấp bằng chứng hình ảnh, YOLO xác minh loại phương tiện, Master điều khiển barrier và dashboard cung cấp giám sát tập trung.

### Chuyển tiếp

> Tiếp theo, Bùi Đình Long sẽ trình bày kiến trúc phần cứng, kết nối giữa các module và luồng hoạt động của hệ thống.

---


# Phần demo của Đỗ Thành Triết

## Nhiệm vụ

- Theo dõi kết nối ESP32-CAM.
- Theo dõi FastAPI server.
- Xác nhận server nhận ảnh.
- Giải thích class, confidence và OPEN/CLOSE decision.
- Xử lý hoặc giải thích lỗi upload, timeout và Wi-Fi.

## Câu nói mẫu

> ESP32-CAM đã gửi ảnh lên FastAPI server. YOLO phát hiện class thuộc nhóm phương tiện được chấp nhận và confidence lớn hơn threshold, nên backend trả về OPEN.

## Kiến thức bắt buộc

- FastAPI nhận và xử lý ảnh như thế nào.
- Vì sao YOLO chạy trên server.
- Confidence threshold 0.45 có ý nghĩa gì.
- Accepted classes gồm car, motorcycle, bus và truck.
- Khi nào backend trả CLOSE.
- Phân biệt camera capture, image upload và model inference.



# 11. Câu hỏi chung cho toàn nhóm

## 1. Tại sao dùng hybrid sensor + camera?

> Sensor nhanh và rẻ nhưng không xác định được loại vật thể. Camera và YOLO xác minh phương tiện nhưng chậm hơn. Kết hợp hai lớp giúp giảm xử lý không cần thiết và tăng độ tin cậy.

## 2. Vì sao dùng Arduino Master–Slave?

> Master quản lý barrier và trạng thái tổng thể. Slave tách sensor và camera coordination cho ENTRY/EXIT. Kiến trúc này modular, tiết kiệm chân trên Master và giảm ảnh hưởng của camera/network delay.

## 3. Vì sao dùng SQL Server?

> SQL Server lưu được event history, current gate state và occupancy. Database giúp dashboard truy vấn, audit và review sự kiện thay vì chỉ giữ dữ liệu tạm trong bộ nhớ.

## 4. Vì sao dùng FastAPI?

> FastAPI hỗ trợ xây dựng API nhanh bằng Python và tích hợp trực tiếp với YOLO. Nó tiếp nhận ảnh, xử lý model, trả quyết định và ghi dữ liệu.

## 5. Vì sao không xử lý YOLO trên ESP32-CAM?

> ESP32-CAM không đủ tài nguyên để chạy model YOLO lớn với tốc độ và độ ổn định phù hợp. Server có khả năng xử lý tốt hơn và dễ thay đổi model.

## 6. Hệ thống có nhận diện biển số không?

> Chưa. Hiện tại hệ thống chỉ vehicle detection theo class. License plate recognition là future work.

## 7. Hệ thống có biết từng slot trống không?

> Chưa. Hệ thống theo dõi occupancy tổng tại cổng vào/ra, không theo dõi từng slot.

## 8. Nếu bãi đầy thì sao?

> Backend hoặc Master kiểm tra vehicles_inside so với capacity. Nếu đạt capacity, ENTRY sẽ trả CLOSE ngay cả khi YOLO phát hiện đúng phương tiện.

## 9. Nếu có người đứng trước sensor thì sao?

> Sensor có thể phát hiện người như một vật thể, nhưng camera và YOLO không xác nhận accepted vehicle class, nên barrier giữ CLOSE.

## 10. Điểm yếu lớn nhất hiện tại là gì?

> Phụ thuộc vào chất lượng camera và Wi-Fi, test dataset còn nhỏ, end-to-end latency chưa được đo đầy đủ và prototype chưa có cơ chế production-grade fault tolerance.

---