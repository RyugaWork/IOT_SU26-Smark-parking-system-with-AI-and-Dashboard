# SMART PARKING PRESENTATION – INDIVIDUAL SCRIPT

**Project:** A Smart Parking System with Vehicle Detection and Barrier Control  
**Course:** IOT102 – Group 7  
**Presentation language:** Vietnamese

---

# 6. Nguyễn Sỹ Minh Mẫn – Slide 13–14

## Slide 13 – ERD

### Script

> Hệ thống sử dụng ba nhóm dữ liệu chính.  
>  
> Bảng `gates` lưu trạng thái hiện tại của cổng ENTRY và EXIT, bao gồm trạng thái mở hoặc đóng, quyết định gần nhất và thời gian cập nhật.  
>  
> Bảng `detection_events` lưu lịch sử từng lần xử lý. Mỗi event có sensor distance, kết quả detection, raw image, annotated image, class, confidence, quyết định cuối, trạng thái xử lý, occupancy trước và sau, cùng thông tin lỗi nếu có.  
>  
> Bảng `parking_occupancy` lưu capacity, số xe hiện tại và thời gian cập nhật gần nhất.  
>  
> `detection_events` là dữ liệu lịch sử, trong khi `gates` và `parking_occupancy` thể hiện trạng thái hiện tại.

### Kiến thức cần nắm

- Current-state table vs history table.
- Why event log is needed.
- Occupancy update:
  - ENTRY OPEN success → +1;
  - EXIT OPEN success → -1;
  - never below 0;
  - entry rejected when capacity full.

### Câu hỏi

#### Câu: Vì sao không lưu tất cả trong một bảng?

**Trả lời:**

> Vì trạng thái hiện tại và lịch sử có mục đích khác nhau. `gates` và `parking_occupancy` cần truy vấn nhanh để hiển thị current state. `detection_events` lưu nhiều bản ghi theo thời gian để audit, review và thống kê.

#### Câu: Làm sao tránh occupancy âm?

**Trả lời:**

> Khi xử lý EXIT, backend phải kiểm tra giá trị hiện tại trước khi giảm. Giá trị được giới hạn không nhỏ hơn 0. Tương tự, ENTRY chỉ tăng khi chưa đạt capacity và sự kiện được chấp nhận.

#### Câu: Vì sao lưu cả raw image và annotated image?

**Trả lời:**

> Raw image dùng để kiểm tra dữ liệu gốc. Annotated image cho biết bounding box, class và confidence do YOLO tạo ra. Lưu cả hai giúp review và kiểm chứng kết quả detection.

---

## Slide 14 – Web Dashboard

### Script

> Dashboard là giao diện giám sát chính của hệ thống.  
>  
> Phần trên hiển thị tổng số xe đang ở trong bãi, số lượt vào trong ngày, số lượt ra và trạng thái gate.  
>  
> Khu vực tiếp theo hiển thị trạng thái camera và sensor tại ENTRY và EXIT.  
>  
> Phần dưới hiển thị latest entry image, latest exit image và lịch sử parking event.  
>  
> Dashboard không trực tiếp chạy YOLO. Nó đọc dữ liệu đã được backend lưu trong SQL Server và trình bày lại cho người quản lý.

### Kiến thức cần nắm

- Dashboard is monitoring interface.
- Backend owns business logic.
- Database is source of truth.
- Dashboard refreshes data through controller/DAO.
- Images are loaded from stored paths via web-serving mechanism.

### Câu hỏi

#### Câu: Dashboard có real-time hoàn toàn không?

**Trả lời:**

> Trong prototype, dashboard cập nhật theo request hoặc refresh. Nó gần real-time nhưng chưa dùng WebSocket hoặc server push. Future work có thể thêm auto-refresh hoặc WebSocket để cập nhật ngay khi có event.

#### Câu: Nếu database lỗi thì barrier có hoạt động không?

**Trả lời:**

> Barrier decision nên ưu tiên safety và local control. Tuy nhiên, nếu database lỗi thì event có thể không được lưu. Hướng cải tiến là dùng retry queue hoặc local temporary storage để đồng bộ lại sau.

### Chuyển tiếp

> Tiếp theo, Trần Đăng Khoa sẽ trình bày mô hình YOLO, phương pháp kiểm thử, kết quả và phần kết luận.

---

# 8. Nguyễn Sỹ Minh Mẫn – Slide 19

## Slide 19 – Complete Hardware Prototype

### Script

> Đây là prototype phần cứng hoàn chỉnh của nhóm.  
>  
> Hệ thống gồm Arduino Master ở trung tâm, hai Slave module cho ENTRY và EXIT, hai HC-SR04, hai ESP32-CAM, LCD status display và servo barrier.  
>  
> Các module được kết nối thành một hệ thống hoàn chỉnh, không phải các mô hình tách rời. Master nhận thông tin từ Slave, điều khiển barrier và hiển thị trạng thái. Camera gửi ảnh đến backend, còn dashboard đọc dữ liệu từ database.  
>  
> Sau đây nhóm sẽ demo toàn bộ luồng từ lúc sensor phát hiện phương tiện đến khi barrier phản hồi và dashboard cập nhật.

### Câu hỏi

#### Câu: Prototype hiện dùng nguồn như thế nào?

**Trả lời:**

> Camera cần nguồn 5V ổn định vì Wi-Fi và image capture có dòng tải cao. Servo cũng có thể gây sụt áp. Vì vậy cần tránh cấp nguồn yếu hoặc cấp sai điện áp, và tất cả module phải dùng common ground.

---

# 9. Demo – Slide 20

## Phân công demo

| Thành viên | Nhiệm vụ |
|---|---|
| **Nguyễn Sỹ Minh Mẫn** | Giới thiệu flow, điều phối demo và giải thích dashboard |
| **Bùi Đình Long** | Đặt mô hình phương tiện tại sensor, theo dõi barrier |
| **Đỗ Thành Triết** | Theo dõi ESP32-CAM, FastAPI và YOLO result |
| **Trần Đăng Khoa** | Refresh web, chỉ ra event mới, ảnh, class, confidence và occupancy |

## Script demo

### Nguyễn Sỹ Minh Mẫn

> Bây giờ nhóm sẽ demo luồng ENTRY. Khi phương tiện đi vào vùng sensor, hệ thống sẽ yêu cầu camera chụp ảnh, gửi lên server, YOLO xác minh và trả về quyết định.

### Bùi Đình Long

> Em đặt phương tiện trước sensor ENTRY. Sensor đã phát hiện vật thể và kích hoạt quá trình capture.

### Đỗ Thành Triết

> ESP32-CAM đã gửi ảnh lên FastAPI server. YOLO phát hiện class là car hoặc truck với confidence lớn hơn threshold, nên backend trả về OPEN.

### Bùi Đình Long

> Arduino Master nhận quyết định OPEN và điều khiển servo mở barrier.

### Trần Đăng Khoa

> Em refresh dashboard. Dashboard đã cập nhật latest entry image, detected class, confidence, gate decision, event time và vehicles inside.

### Nguyễn Sỹ Minh Mẫn

> Sau khi phương tiện đi qua và sensor xác nhận vùng barrier đã trống, hệ thống đóng barrier.  
>  
> Luồng EXIT hoạt động tương tự, nhưng occupancy sẽ giảm thay vì tăng.

---


# Trọng tâm điều phối demo

- Giới thiệu demo flow trước khi thao tác.
- Giải thích dữ liệu dashboard trước và sau event.
- Chỉ rõ latest entry image, latest exit image, confidence, decision và occupancy.
- Điều phối Long, Triết và Khoa theo đúng thứ tự.
- Tổng kết kết quả sau demo.

## Câu nói mở đầu demo

> Bây giờ nhóm sẽ demo luồng ENTRY. Khi phương tiện đi vào vùng sensor, hệ thống sẽ yêu cầu camera chụp ảnh, gửi lên server, YOLO xác minh và trả về quyết định.

## Câu nói kết thúc demo

> Sau khi phương tiện đi qua và sensor xác nhận vùng barrier đã trống, hệ thống đóng barrier. Luồng EXIT hoạt động tương tự nhưng occupancy sẽ giảm thay vì tăng.

## Kiến thức bắt buộc

- ERD và vai trò từng bảng.
- Current-state table và history table.
- Logic tăng giảm occupancy.
- Dashboard lấy dữ liệu từ controller, DAO và database.
- Raw image và annotated image.
- Cách giải thích khi dashboard chưa refresh.
- Cách điều phối demo khi một module gặp lỗi.



# 10. Demo Failure Cases

Nhóm nên biết cách giải thích cả khi demo lỗi.

## Nếu camera không gửi ảnh

> Hệ thống giữ barrier ở trạng thái CLOSE vì chưa có kết quả xác minh từ backend. Đây là fail-safe behavior.

## Nếu YOLO không nhận diện được xe

> Nếu class không thuộc accepted list hoặc confidence thấp hơn 0.45, backend trả CLOSE.

## Nếu dashboard chưa cập nhật

> Dashboard hiện cập nhật theo refresh/request. Backend và database có thể đã lưu event trước, sau đó dashboard mới tải dữ liệu mới.

## Nếu servo không mở

> Kiểm tra quyết định backend, tín hiệu Master, nguồn servo và common ground. Servo có thể không đủ dòng nếu nguồn bị sụt áp.

## Nếu occupancy sai

> Kiểm tra event direction ENTRY/EXIT, điều kiện chỉ update occupancy khi event được chấp nhận, và giới hạn giá trị từ 0 đến capacity.

---