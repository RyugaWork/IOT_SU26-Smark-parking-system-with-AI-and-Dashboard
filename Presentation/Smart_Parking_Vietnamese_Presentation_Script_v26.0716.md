# KỊCH BẢN THUYẾT TRÌNH SMART PARKING SYSTEM

**Đề tài:** A Smart Parking System with Vehicle Detection and Barrier Control  
**Môn:** IOT102 – Research-Based Learning  
**Nhóm:** Group 7  
**Ngôn ngữ trình bày:** Tiếng Việt  
**Thời lượng mục tiêu:** 14–15 phút  
**Phiên bản:** v26.0716

---

# 1. Phân công thuyết trình

| Thành viên | Slide | Nội dung |
|---|---:|---|
| **Bùi Đình Long** | 1–2 | Giới thiệu đề tài, thành viên và vai trò |
| **Đỗ Thành Triết** | 3–4 | Background, vấn đề thực tế và hạn chế của hệ thống cũ |
| **Bùi Đình Long** | 5–9 | Mục tiêu, hướng giải quyết, scope, block diagram, architecture, circuit và flowchart |
| **Nguyễn Sỹ Minh Mẫn** | 10–12 | ERD, dashboard và prototype phần cứng |
| **Trần Đăng Khoa** | 13–15 | Phương pháp kiểm thử, kết quả, kết luận và future work |

---

# 2. Các ý bắt buộc phải làm rõ

Trong phần trình bày, nhóm cần làm rõ năm nội dung sau:

1. **Background:** Vì sao bài toán smart parking cần được nghiên cứu?
2. **Đánh giá các bài báo khác:** Các nghiên cứu trước đã làm gì và còn hạn chế gì?
3. **Điểm nổi bật:** Hệ thống của nhóm khác hoặc nổi bật ở điểm nào?
4. **Hướng giải quyết:** Nhóm giải quyết vấn đề bằng kiến trúc và quy trình nào?
5. **Scope:** Hệ thống làm được gì, không làm gì và được kiểm thử trong phạm vi nào?

Các nội dung này không nhất thiết phải xuất hiện thành slide riêng. Có thể bổ sung bằng lời nói tại Slide 3, 4 và 5.

---

# 3. Script chi tiết theo từng slide

---

## Slide 1 — Title Slide

**Người trình bày:** Bùi Đình Long  
**Thời lượng:** 25–30 giây

### Script

> Xin chào thầy và các bạn. Nhóm 7 xin trình bày đề tài **“A Smart Parking System with Vehicle Detection and Barrier Control”**, tức là hệ thống bãi đỗ xe thông minh tích hợp phát hiện phương tiện và điều khiển thanh chắn.
>
> Hệ thống của nhóm kết hợp cảm biến siêu âm, ESP32-CAM, Arduino, mô hình YOLO chạy trên server, cơ sở dữ liệu SQL Server và giao diện web dashboard.
>
> Mục tiêu chính của nhóm là xây dựng một mô hình bãi xe quy mô nhỏ có khả năng phát hiện vật thể, xác minh phương tiện bằng hình ảnh, điều khiển barrier và lưu lại dữ liệu để theo dõi.

### Ý cần nhớ

- Không đọc lại toàn bộ chữ trên slide.
- Không nói hệ thống đã nhận diện biển số vì chức năng đó chưa được triển khai.
- Có thể dùng từ “proof-of-concept prototype” nếu cần nhấn mạnh đây là mô hình thử nghiệm.

---

## Slide 2 — Team Members

**Người trình bày:** Bùi Đình Long  
**Thời lượng:** 35–40 giây

### Script

> Nhóm gồm bốn thành viên.
>
> Mẫn phụ trách web dashboard, SQL Server và hỗ trợ phần YOLO server.
>
> Triết phụ trách phần cứng, Arduino và hỗ trợ server xử lý ảnh.
>
> Khoa phụ trách web dashboard, SQL Server và tổng hợp báo cáo.
>
> Em là Long, phụ trách phần cứng, Arduino và hỗ trợ viết báo cáo.
>
> Trong quá trình thực hiện, các thành viên có phối hợp chéo giữa phần cứng, phần mềm và tài liệu để kiểm tra tính nhất quán của toàn hệ thống.

### Câu chuyển sang Triết

> Tiếp theo, Triết sẽ trình bày về bối cảnh thực tế của bài toán và những hạn chế của hệ thống quản lý bãi xe truyền thống.

---

## Slide 3 — Background / Problem Context

**Người trình bày:** Đỗ Thành Triết  
**Thời lượng:** 1 phút 15 giây

### Script chính

> Trước tiên là background của đề tài.
>
> Trong nhiều bãi xe nhỏ tại trường học, văn phòng hoặc khu dân cư, việc kiểm soát xe ra vào vẫn phụ thuộc nhiều vào con người. Nhân viên phải quan sát phương tiện, quyết định mở cổng và ghi nhận thông tin bằng phương pháp thủ công.
>
> Cách quản lý này có một số vấn đề. Thứ nhất, tốc độ xử lý phụ thuộc vào người vận hành. Thứ hai, thông tin xe vào và xe ra có thể bị thiếu hoặc không nhất quán. Thứ ba, khi xảy ra sự cố, hệ thống không có đủ hình ảnh hoặc dữ liệu để kiểm tra lại.
>
> Vì vậy, smart parking không chỉ có nghĩa là tự động mở thanh chắn. Một hệ thống hoàn chỉnh còn cần phát hiện phương tiện, xác minh đối tượng, điều khiển cổng, lưu sự kiện và cung cấp giao diện giám sát.

### Phần làm rõ background

> Về mặt kỹ thuật, bài toán này thuộc nhóm hệ thống IoT cyber-physical. Nghĩa là dữ liệu được lấy từ môi trường vật lý bằng cảm biến, sau đó được xử lý bởi vi điều khiển và server, cuối cùng hệ thống tác động trở lại môi trường bằng servo barrier.
>
> Trong dự án này, cảm biến HC-SR04 đại diện cho lớp sensing, Arduino đại diện cho lớp local control, ESP32-CAM và Wi-Fi đại diện cho lớp communication, YOLO server đại diện cho lớp AI processing, còn dashboard đại diện cho lớp monitoring.

### Kiến thức cần tìm hiểu

#### IoT Cyber-Physical System

Một hệ thống cyber-physical thường gồm:

```text
Physical environment
→ Sensor
→ Embedded controller
→ Communication network
→ Backend processing
→ Decision
→ Actuator
```

Trong dự án:

```text
Vehicle model
→ HC-SR04
→ Arduino Slave/Master
→ ESP32-CAM and Wi-Fi
→ FastAPI and YOLO
→ OPEN/CLOSE
→ SG90 barrier
```

#### Tại sao không chỉ dùng camera?

Nếu camera liên tục chụp và gửi ảnh:

- Tốn bandwidth.
- Tăng số lượng ảnh không cần thiết.
- Tăng tải cho server.
- Phụ thuộc hoàn toàn vào ánh sáng và chất lượng hình ảnh.

Do đó, HC-SR04 được dùng như một trigger rẻ và nhanh trước khi camera hoạt động.

---

## Slide 4 — Limitations of the Old System

**Người trình bày:** Đỗ Thành Triết  
**Thời lượng:** 1 phút 30 giây

### Script chính

> Hệ thống cũ có năm hạn chế chính.
>
> Thứ nhất là kiểm tra thủ công, dẫn đến phụ thuộc vào người vận hành.
>
> Thứ hai là phản hồi chậm, đặc biệt khi có nhiều xe chờ.
>
> Thứ ba là không có image verification. Nếu chỉ dùng cảm biến thì hệ thống biết có vật thể ở gần nhưng không biết đó có thực sự là phương tiện hay không.
>
> Thứ tư là khó quản lý dữ liệu. Thông tin xe vào, xe ra, trạng thái cổng và hình ảnh có thể không được lưu tập trung.
>
> Thứ năm là không có dashboard để giám sát và kiểm tra lại sự kiện.

### Đánh giá các bài báo liên quan

> Nhóm đã tham khảo bảy bài báo liên quan đến smart parking.
>
> Các bài P3 và P4 cho thấy cảm biến ultrasonic phù hợp với các mô hình chi phí thấp vì dễ tích hợp và phản hồi nhanh. Tuy nhiên, cảm biến chỉ đo khoảng cách và không xác định được loại đối tượng.
>
> Bài P5 sử dụng ESP32-CAM và servo trong một hệ thống parking không tiếp xúc. Bài này gần với hướng triển khai của nhóm vì có camera và barrier, nhưng chưa tập trung nhiều vào kiến trúc nhiều module ENTRY và EXIT hoặc lịch sử dashboard.
>
> Bài P6 sử dụng camera để hỗ trợ theo dõi và nhận diện biển số. Ưu điểm là có bằng chứng hình ảnh, nhưng kết quả phụ thuộc nhiều vào góc camera, ánh sáng và độ rõ của ảnh.
>
> Bài P7 đánh giá các mô hình YOLO cho vehicle detection. Bài này cho thấy AI có thể cải thiện khả năng xác minh phương tiện, nhưng AI inference cần tài nguyên xử lý lớn hơn và không phù hợp chạy trực tiếp trên ESP32-CAM.
>
> Từ các bài báo trên, nhóm nhận thấy phần lớn hệ thống chỉ tập trung vào một hoặc hai thành phần, ví dụ sensor, camera hoặc dashboard. Ít hệ thống mô tả đầy đủ chuỗi từ sensor đến camera, AI server, barrier và event logging trong một mô hình low-cost.

### Bảng so sánh nhanh để học

| Nhóm giải pháp | Ưu điểm | Hạn chế |
|---|---|---|
| Ultrasonic only | Rẻ, nhanh, đơn giản | Không biết vật thể có phải xe không |
| Camera only | Có hình ảnh và thông tin trực quan | Phụ thuộc ánh sáng, góc chụp và network |
| RFID | Nhanh, dễ xác thực thẻ | Chỉ nhận xe có thẻ, không xác minh hình ảnh |
| YOLO vehicle detection | Phân loại được vehicle class | Cần server/GPU/CPU mạnh hơn |
| Dashboard monitoring | Có dữ liệu tập trung | Không tự đảm bảo barrier thật sự đã hoạt động |
| Hybrid sensor + camera | Giảm trigger sai và có visual evidence | Kiến trúc phức tạp hơn, có nhiều điểm có thể lỗi |

### Điểm chuyển tiếp

> Từ các hạn chế đó, nhóm không chọn giải pháp sensor-only hoặc camera-only, mà xây dựng một kiến trúc hybrid, trong đó cảm biến phát hiện trước và camera cùng YOLO thực hiện bước xác minh.

### Câu chuyển sang Long

> Từ những vấn đề và khoảng trống vừa trình bày, Long sẽ tiếp tục giới thiệu mục tiêu, phạm vi và thiết kế tổng thể của hệ thống.

---

## Slide 5 — Project Objectives and Key Functions

**Người trình bày:** Bùi Đình Long  
**Thời lượng:** 1 phút 40 giây

### Script chính

> Mục tiêu của dự án là xây dựng một hệ thống smart parking quy mô nhỏ, kết hợp detection, processing và management.
>
> Ở lớp detection, HC-SR04 được dùng để phát hiện vật thể gần khu vực ENTRY hoặc EXIT. Khi có vật thể, ESP32-CAM sẽ chụp ảnh.
>
> Ở lớp processing, ảnh được gửi qua Wi-Fi đến FastAPI server. Server sử dụng YOLO26l để kiểm tra xem ảnh có chứa một trong các lớp phương tiện được chấp nhận hay không.
>
> Các lớp được chấp nhận gồm car, motorcycle, bus và truck. Nếu có ít nhất một detection đạt confidence threshold 0.45, server trả về OPEN. Ngược lại, server trả về CLOSE.
>
> Ở lớp management, Arduino Master là module duy nhất có quyền điều khiển servo barrier. Dữ liệu detection có thể được lưu vào SQL Server và hiển thị trên dashboard.

### Hướng giải quyết

> Hướng giải quyết của nhóm là kiến trúc hybrid gồm hai tầng xác minh.
>
> Tầng thứ nhất là ultrasonic sensing. Tầng này chỉ trả lời câu hỏi: có vật thể ở gần hay không.
>
> Tầng thứ hai là camera và YOLO. Tầng này trả lời câu hỏi: ảnh có chứa một lớp phương tiện được chấp nhận hay không.
>
> Barrier chỉ được mở sau khi Arduino Master nhận được kết quả OPEN hợp lệ của chu kỳ hiện tại.

### Điểm nổi bật của hệ thống

1. **Hybrid detection:** Không mở cổng trực tiếp chỉ từ cảm biến.
2. **Server-side AI:** ESP32-CAM chỉ chụp và gửi ảnh; YOLO chạy trên máy chủ.
3. **Modular ENTRY/EXIT:** Hai module có địa chỉ và identity riêng.
4. **Centralized actuator control:** Chỉ Master điều khiển servo.
5. **Fail-close policy:** Lỗi hoặc dữ liệu không chắc chắn đều giữ cổng đóng.
6. **Monitoring support:** Có SQL Server và dashboard để lưu và hiển thị sự kiện.
7. **Evidence-aware evaluation:** Nhóm phân biệt rõ inference time với total response time và detection rate với overall accuracy.

### Scope của dự án

#### Trong phạm vi

- Phát hiện vật thể bằng hai HC-SR04.
- Chụp ảnh bằng hai ESP32-CAM.
- Upload ảnh qua HTTP over Wi-Fi.
- Phát hiện vehicle class bằng YOLO26l.
- Trả quyết định OPEN hoặc CLOSE.
- Arduino Master điều khiển SG90.
- Lưu detection event vào SQL Server.
- Hiển thị dữ liệu trên Java web dashboard.
- Thử nghiệm bằng xe mô hình trong môi trường laboratory.

#### Ngoài phạm vi

- License plate recognition.
- Vehicle identity authorization.
- Payment processing.
- Full-size industrial barrier.
- Production security.
- Outdoor weather testing.
- Long-duration uptime testing.
- Complete end-to-end timestamp measurement.
- Formal barrier-safety certification.

### Câu nên nhấn mạnh

> Hệ thống hiện tại là proof-of-concept prototype. Nhóm chứng minh được kiến trúc và luồng điều khiển, nhưng chưa xem đây là một hệ thống bãi xe sẵn sàng triển khai thực tế.

---

## Slide 6 — Hardware Block Diagram

**Người trình bày:** Bùi Đình Long  
**Thời lượng:** 55–60 giây

### Script

> Sơ đồ khối của hệ thống được chia thành ba khu vực.
>
> Khu vực thứ nhất là Logic Control and LCD System. Arduino Master nhận trạng thái từ hai Slave, kiểm tra kết quả detection và điều khiển SG90. LCD1602 chỉ dùng để debug và hiển thị trạng thái cục bộ.
>
> Khu vực thứ hai gồm hai Sensor–Camera Module có cấu trúc tương tự nhau. ENTRY sử dụng địa chỉ I2C 0x08, còn EXIT sử dụng 0x09. Mỗi module có một Arduino Slave, một HC-SR04 và một ESP32-CAM.
>
> Khu vực thứ ba là Local Server and Dashboard. ESP32-CAM gửi ảnh đến FastAPI. YOLO26l xử lý ảnh, SQL Server lưu sự kiện và dashboard hiển thị dữ liệu.
>
> Điểm quan trọng là server chỉ tạo quyết định. Quyền điều khiển barrier vẫn thuộc Arduino Master.

### Kiến thức liên quan

#### Vì sao dùng Master–Slave?

- Tách sensing của ENTRY và EXIT.
- Master có một điểm điều khiển barrier duy nhất.
- Có thể mở rộng thêm module có địa chỉ riêng.
- Giảm xung đột giữa nhiều bộ điều khiển.

#### Trade-off

- Kiến trúc rõ ràng hơn.
- Nhưng phụ thuộc vào communication.
- Nếu một Slave lỗi, phần mềm hiện tại có thể dừng toàn bộ Master.

---

## Slide 7 — Overall System Architecture

**Người trình bày:** Bùi Đình Long  
**Thời lượng:** 1 phút

### Script

> Sơ đồ này thể hiện đường đi đầy đủ của dữ liệu.
>
> Đầu tiên, HC-SR04 phát hiện vật thể. Arduino Slave cập nhật trạng thái và Arduino Master đọc trạng thái qua I2C.
>
> Khi Master xác định có một sự kiện mới, Master yêu cầu Slave bắt đầu capture. Slave gửi lệnh CAPTURE đến ESP32-CAM qua UART ở tốc độ 9600 baud.
>
> ESP32-CAM chụp ảnh JPEG và gửi ảnh đến FastAPI server bằng HTTP qua Wi-Fi.
>
> Server chạy YOLO26l, sau đó trả OPEN hoặc CLOSE về ESP32-CAM. Kết quả tiếp tục đi qua UART đến Slave, rồi qua I2C đến Master.
>
> Cuối cùng, Master kiểm tra kết quả của chu kỳ hiện tại và quyết định điều khiển servo.
>
> Song song với control path là monitoring path. FastAPI lưu dữ liệu vào SQL Server, sau đó dashboard truy vấn và hiển thị các sự kiện.

### Hai đường xử lý cần phân biệt

#### Control path

```text
Sensor
→ Slave
→ Master
→ ESP32-CAM
→ FastAPI/YOLO
→ Slave
→ Master
→ Servo
```

#### Monitoring path

```text
FastAPI
→ SQL Server
→ Java Dashboard
```

### Câu quan trọng

> Dashboard không có quyền mở barrier. Nếu dashboard bị lỗi, quyền điều khiển vẫn nằm tại Arduino Master.

---

## Slide 8 — Hardware Circuit Diagram

**Người trình bày:** Bùi Đình Long  
**Thời lượng:** 55 giây

### Script

> Đây là sơ đồ mạch hoàn chỉnh của hệ thống.
>
> Ba Arduino dùng chung đường SDA, SCL và common ground cho giao tiếp I2C. ENTRY được cấu hình tại địa chỉ 0x08 và EXIT tại 0x09.
>
> Mỗi Slave kết nối với một HC-SR04 và một ESP32-CAM. Slave giao tiếp với camera bằng UART.
>
> Do Arduino Uno sử dụng logic 5 volt còn ESP32-CAM sử dụng logic 3.3 volt, đường Arduino TX sang ESP32-CAM RX cần có voltage divider hoặc level shifter.
>
> Servo và LCD được kết nối trực tiếp với Master. Hệ thống sử dụng nguồn regulated 5 volt, khoảng 3 ampere và tất cả module phải dùng chung ground.
>
> Trong quá trình tích hợp, nguồn điện là một yếu tố quan trọng vì ESP32-CAM và servo có thể tạo ra dòng tăng đột ngột khi Wi-Fi truyền ảnh hoặc servo bắt đầu di chuyển.

### Kiến thức liên quan

#### Common ground

Các thiết bị giao tiếp bằng tín hiệu điện phải có cùng mốc điện áp. Nếu không có common ground, mức logic HIGH và LOW có thể bị hiểu sai.

#### Voltage divider

Arduino TX có thể xuất khoảng 5 V. ESP32 RX chỉ phù hợp mức 3.3 V. Voltage divider làm giảm điện áp trước khi tín hiệu đi vào ESP32-CAM.

#### Brownout

Brownout xảy ra khi điện áp giảm dưới mức ổn định. ESP32-CAM có thể reset, mất Wi-Fi hoặc capture thất bại.

---

## Slide 9 — System Flowchart

**Người trình bày:** Bùi Đình Long  
**Thời lượng:** 1 phút 10 giây

### Script

> Flowchart mô tả toàn bộ trạng thái hoạt động của hệ thống.
>
> Sau khi khởi động, hệ thống vào trạng thái idle và liên tục đọc ENTRY và EXIT.
>
> Nếu không có vật thể, hệ thống tiếp tục monitoring.
>
> Khi phát hiện một vật thể mới, Master bắt đầu capture cycle. ESP32-CAM chụp ảnh và server xử lý bằng YOLO.
>
> Nếu kết quả là OPEN, Master điều khiển servo mở barrier. Nếu kết quả là CLOSE, invalid hoặc timeout, barrier vẫn đóng.
>
> Sau khi sự kiện hoàn tất, hệ thống chuyển sang trạng thái WAIT_OBJECT_CLEAR. Đây là bước quan trọng để cùng một vật thể không liên tục kích hoạt nhiều ảnh và nhiều lần mở cổng.
>
> Chỉ khi vật thể rời khỏi detection area, hệ thống mới reset và quay lại trạng thái idle.

### Fail-close policy

Các trường hợp sau đều dẫn đến CLOSE:

- Camera initialization failure.
- Wi-Fi unavailable.
- JPEG capture failure.
- HTTP timeout.
- FastAPI unavailable.
- Non-200 response.
- Empty response.
- Invalid UART result.
- Stale result.
- Master timeout.
- Không phát hiện lớp xe được chấp nhận.

### Câu chuyển sang Mẫn

> Sau phần kiến trúc phần cứng và quy trình điều khiển, Mẫn sẽ trình bày thiết kế cơ sở dữ liệu, giao diện dashboard và prototype đã được tích hợp.

---

## Slide 10 — System ERD

**Người trình bày:** Nguyễn Sỹ Minh Mẫn  
**Thời lượng:** 1 phút

### Script

> Cơ sở dữ liệu chính của hệ thống gồm ba bảng.
>
> Bảng `parking_occupancy` lưu capacity, số lượng xe hiện tại và thời điểm cập nhật.
>
> Bảng `gates` lưu trạng thái logic của ENTRY và EXIT.
>
> Bảng `detection_events` lưu lịch sử xử lý ảnh, bao gồm gate direction, thời gian tạo, quyết định OPEN hoặc CLOSE, confidence, class name, raw image path và annotated image path.
>
> `detection_events` liên kết với `gates` thông qua `gate_id`. Trong đó gate ID 1 đại diện cho ENTRY và gate ID 2 đại diện cho EXIT.
>
> Việc lưu relative image path thay vì absolute path giúp hệ thống có thể chuyển sang máy khác mà không phụ thuộc vào thư mục người dùng cụ thể.

### Giới hạn cần nói rõ

> Một detection event trong database chứng minh rằng backend đã xử lý ảnh và tạo quyết định. Nó chưa chứng minh chắc chắn servo vật lý đã mở, vì Arduino Master chưa gửi đầy đủ telemetry về server.

### Kiến thức liên quan

#### Detection decision và physical action

```text
Server decision: OPEN
```

không đồng nghĩa tuyệt đối với:

```text
Physical barrier successfully opened
```

Để xác nhận đầy đủ cần có telemetry:

- Master received result.
- Master validated sequence.
- Servo command issued.
- Barrier state changed.
- Object cleared.

---

## Slide 11 — Web Dashboard Interface

**Người trình bày:** Nguyễn Sỹ Minh Mẫn  
**Thời lượng:** 55 giây

### Script

> Dashboard được xây dựng bằng Java Servlet, JSP, DAO và SQL Server.
>
> Controller chính là `DashboardController`, được mapping tại đường dẫn `/dashboard`.
>
> Dashboard hiển thị capacity, số xe đang ở trong bãi, số chỗ còn trống, trạng thái gate, sự kiện ENTRY gần nhất, sự kiện EXIT gần nhất, class, confidence, timestamp và hình ảnh raw hoặc annotated.
>
> Các ảnh YOLO được lưu ở backend, không nằm trực tiếp trong web project. Vì vậy, nhóm sử dụng image-serving servlet để đọc relative path, kiểm tra file và stream ảnh về trình duyệt.
>
> Dashboard có vai trò monitoring. Nó không gửi lệnh trực tiếp đến servo.

### Không nên nói

- Dashboard đã được kiểm chứng 100%.
- Dashboard có real-time latency cụ thể.
- Occupancy luôn chính xác tuyệt đối.
- Mọi database event đều đồng bộ với barrier vật lý.

### Cách nói đúng

> Nhóm đã chứng minh được khả năng hiển thị dữ liệu và hình ảnh từ SQL Server, nhưng chưa thực hiện đầy đủ repeated reliability testing cho toàn bộ dashboard.

---

## Slide 12 — Complete Hardware Prototype

**Người trình bày:** Nguyễn Sỹ Minh Mẫn  
**Thời lượng:** 50 giây

### Script

> Đây là prototype phần cứng hoàn chỉnh của nhóm.
>
> Hệ thống được lắp thành một assembly duy nhất, bao gồm một Arduino Master, hai Arduino Slave, hai HC-SR04, hai ESP32-CAM, một LCD1602 và một SG90 servo.
>
> Hai sensor-camera module đại diện cho ENTRY và EXIT. Master nằm ở trung tâm và là bộ điều khiển duy nhất của barrier.
>
> LCD1602 được sử dụng để quan sát khoảng cách, trạng thái module, kết quả capture và trạng thái barrier trong quá trình debug.
>
> Mô hình này sử dụng xe mô hình và SG90 nên chỉ chứng minh nguyên lý hoạt động. Nó không đại diện cho barrier công nghiệp hoặc môi trường bãi xe thực tế.

### Câu chuyển sang Khoa

> Cuối cùng, Khoa sẽ trình bày điều kiện kiểm thử, kết quả thực nghiệm, các giới hạn và hướng phát triển tiếp theo.

---

## Slide 13 — Testing Method and Conditions

**Người trình bày:** Trần Đăng Khoa  
**Thời lượng:** 1 phút 35 giây

### Script

> Phần kiểm thử tập trung vào kết quả xử lý ảnh của YOLO26l và các quan sát trong quá trình tích hợp phần cứng.
>
> Dataset chính gồm 146 ảnh thực được lấy từ workflow ESP32-CAM. Mỗi ảnh đều chứa một xe mô hình, do đó đây là positive-only dataset.
>
> Server sử dụng YOLO26l với image size 640, confidence threshold 0.45 và bốn lớp được chấp nhận là car, motorcycle, bus và truck.
>
> Khi có ít nhất một detection thuộc nhóm trên và confidence lớn hơn hoặc bằng 0.45, server trả OPEN. Nếu không có detection hợp lệ, server trả CLOSE.
>
> Thời gian inference được lấy từ log của YOLO server. Đây chỉ là thời gian xử lý model, không bao gồm sensor detection, Master polling, camera capture, image upload, result return và servo movement.
>
> Do không có negative samples và ground truth đầy đủ, nhóm không thể tính overall accuracy, precision, specificity, false-positive rate hoặc F1-score.
>
> Ngoài ra, end-to-end gate response time chưa được đo vì các module chưa có synchronized timestamp.

### Quy trình kiểm thử

```text
ESP32-CAM image
→ HTTP upload
→ FastAPI receives image
→ YOLO26l inference
→ Filter class and confidence
→ OPEN/CLOSE
→ Save result log
```

### Điều kiện cần nói rõ

- 146 ảnh là positive vehicle-model images.
- Không phải 146 complete barrier cycles.
- Confidence không phải accuracy.
- Inference time không phải total response time.
- Không có negative image nên không tính được false positive.

---

## Slide 14 — Results and Benefits

**Người trình bày:** Trần Đăng Khoa  
**Thời lượng:** 1 phút 50 giây

### Script

> Kết quả chính của dataset 146 ảnh là 66 quyết định OPEN và 80 quyết định CLOSE.
>
> Vì toàn bộ 146 ảnh đều là positive samples, positive-sample detection rate được tính bằng 66 chia cho 146, tương đương 45.21%.
>
> Miss rate là 80 chia cho 146, tương đương 54.79%.
>
> Thời gian inference trung bình là 432.23 milliseconds, median là 415.76 milliseconds và maximum là 837.82 milliseconds.
>
> Trong 66 detection được chấp nhận, YOLO dự đoán 43 ảnh là truck và 23 ảnh là car.
>
> Mean accepted confidence là 72.63%.
>
> Kết quả cho thấy server có thể nhận ảnh, chạy YOLO và trả quyết định trong thời gian dưới một giây ở phần lớn trường hợp. Tuy nhiên, miss rate còn cao, nghĩa là image-verification layer chưa ổn định trong điều kiện ảnh cuối cùng.

### So sánh YOLOv8n và YOLO26l

> Nhóm cũng có một comparison trên nguồn ảnh cũ.
>
> YOLOv8n đạt positive-sample detection rate 80.43% với inference trung bình 93.42 milliseconds.
>
> YOLO26l đạt 94.23% với inference trung bình 421.39 milliseconds.
>
> Như vậy, YOLO26l tăng 13.80 percentage points về detection rate trên nguồn ảnh đó, nhưng inference chậm hơn khoảng 4.51 lần.
>
> Đây là trade-off giữa detection consistency và processing speed.

### Trạng thái Research Questions

#### RQ1

> RQ1 hỏi độ chính xác của HC-SR04 trong việc phát hiện phương tiện. RQ này chưa được trả lời đầy đủ vì nhóm chưa thực hiện controlled sensor experiment với ground-truth distance, vehicle, non-vehicle và repeated trials.

#### RQ2

> RQ2 hỏi thời gian từ vehicle detection đến gate response. RQ này cũng chưa được trả lời đầy đủ vì nhóm chỉ đo YOLO inference time, chưa đo toàn bộ đường đi từ HC-SR04 đến servo.

### Điểm nổi bật được chứng minh

- Có chuỗi xử lý từ ESP32-CAM đến YOLO server.
- Có quyết định OPEN/CLOSE.
- Có event logging và annotated image.
- Có kiến trúc fail-close.
- Có model trade-off analysis.
- Báo cáo phân biệt rõ measured và unmeasured metrics.

---

## Slide 15 — Conclusion and Future Work

**Người trình bày:** Trần Đăng Khoa  
**Thời lượng:** 1 phút 15 giây

### Script

> Tóm lại, nhóm đã xây dựng được một prototype smart parking tích hợp cảm biến siêu âm, Arduino Master–Slave, ESP32-CAM, FastAPI, YOLO26l, SQL Server, dashboard và servo barrier.
>
> Điểm nổi bật của hệ thống là sử dụng hybrid detection. HC-SR04 chỉ tạo trigger, còn camera và YOLO thực hiện bước xác minh. Chỉ Arduino Master mới có quyền điều khiển barrier.
>
> Hệ thống cũng áp dụng fail-close policy. Khi camera, Wi-Fi, HTTP, server, UART hoặc timeout xảy ra lỗi, barrier vẫn giữ trạng thái đóng.
>
> Tuy nhiên, kết quả 45.21% trên dataset cuối cho thấy chất lượng ảnh, góc camera, khoảng cách, ánh sáng và kích thước xe mô hình ảnh hưởng lớn đến detection.
>
> Trong tương lai, nhóm sẽ bổ sung negative samples, đánh giá HC-SR04, đo end-to-end response time, cải thiện fault isolation khi một Slave lỗi, gửi telemetry từ Master lên server và nghiên cứu thêm license plate recognition.
>
> Phần trình bày của nhóm đến đây là kết thúc. Nhóm xin cảm ơn thầy và các bạn đã lắng nghe.

---

# 4. Tóm tắt năm nội dung trọng tâm

## 4.1 Background

Smart parking giải quyết các vấn đề:

- Phụ thuộc vào nhân viên vận hành.
- Xử lý xe chậm.
- Thiếu dữ liệu sự kiện.
- Thiếu hình ảnh xác minh.
- Khó giám sát từ xa.
- Khó kiểm tra lại khi xảy ra sự cố.

Smart parking là một hệ thống IoT cyber-physical vì có:

- Sensor.
- Embedded controller.
- Network.
- Backend processing.
- Database.
- Dashboard.
- Actuator.

---

## 4.2 Đánh giá các bài báo khác

| Paper | Hướng nghiên cứu | Hỗ trợ cho dự án | Hạn chế |
|---|---|---|---|
| P1 | IoT parking và web/mobile monitoring | Hỗ trợ dashboard và centralized monitoring | Ít tập trung vào camera verification và barrier |
| P2 | Smart parking management | Hỗ trợ background và real-time status | Không có camera verification và barrier tự động |
| P3 | IoT sensors for parking | Hỗ trợ sensor-based detection | Sensor không xác minh được vehicle |
| P4 | Ultrasonic control sensor | Hỗ trợ HC-SR04 và low-cost sensing | Không có visual evidence hoặc AI |
| P5 | ESP32-CAM touchless parking | Gần với camera và servo architecture | Chưa làm rõ multi-module coordination và event history |
| P6 | Camera/license-plate monitoring | Hỗ trợ image verification và future LPR | Phụ thuộc image quality |
| P7 | YOLO vehicle detection | Hỗ trợ backend AI verification | Tập trung AI hơn là complete IoT control chain |

### Research gap rút ra

1. Sensor-only không xác minh được vehicle.
2. Camera/AI thường được đánh giá tách biệt với barrier.
3. End-to-end gate response time ít được đo đầy đủ.
4. Dashboard và physical gate state chưa luôn được đồng bộ.
5. Low-cost modular architecture chưa được đánh giá đầy đủ về failure dependency.

---

## 4.3 Điểm nổi bật

### Hybrid Detection

```text
Ultrasonic trigger
+ Camera evidence
+ YOLO verification
```

### Centralized Control

```text
Only Arduino Master controls SG90
```

### Fail-Close

```text
Invalid or uncertain result
→ CLOSE
```

### Modular Identity

```text
ENTRY = 0x08
EXIT  = 0x09
```

### Server-Side AI

ESP32-CAM không chạy YOLO trực tiếp. Nó chỉ:

- Capture JPEG.
- Upload through Wi-Fi.
- Receive OPEN/CLOSE.
- Return result through UART.

### Evidence-Aware Evaluation

Nhóm không đánh đồng:

- Detection rate với overall accuracy.
- Confidence với accuracy.
- Inference time với total gate response.
- Server log với physical barrier success.

---

## 4.4 Hướng giải quyết

```text
1. HC-SR04 detects object
2. Arduino Slave reports state
3. Arduino Master starts capture cycle
4. Slave sends CAPTURE to ESP32-CAM
5. ESP32-CAM uploads JPEG to FastAPI
6. YOLO26l detects allowed vehicle class
7. Server returns OPEN or CLOSE
8. ESP32-CAM returns decision to Slave
9. Slave exposes decision to Master
10. Master validates current cycle
11. Master controls SG90
12. Server stores event for dashboard
13. System waits until object clears
```

---

## 4.5 Scope

### Implemented Scope

- Small-scale laboratory prototype.
- Physical vehicle models.
- Two directions: ENTRY and EXIT.
- One shared SG90 barrier.
- HC-SR04 initial trigger.
- ESP32-CAM image capture.
- FastAPI and YOLO26l.
- SQL Server event storage.
- Java dashboard.
- Fail-close decision policy.

### Not Implemented

- License plate recognition.
- Registered-vehicle authorization.
- User authentication at gate.
- Payment.
- Mobile application.
- Cloud deployment.
- Heartbeat mechanism.
- Industrial barrier.
- Full-size vehicle testing.
- Production safety.
- Complete end-to-end timing.
- Complete HC-SR04 accuracy experiment.

---

# 5. Kiến thức bổ sung để chuẩn bị Q&A

## 5.1 Vì sao dùng HC-SR04 nếu YOLO vẫn có thể phát hiện xe?

HC-SR04 đóng vai trò trigger:

- Không cần camera chạy liên tục.
- Giảm số request gửi lên server.
- Giảm số ảnh rỗng.
- Giảm network và server workload.
- Cho phép hệ thống biết khi nào cần bắt đầu capture cycle.

YOLO đóng vai trò verification:

- Kiểm tra ảnh có chứa allowed vehicle class.
- Cung cấp confidence và class.
- Tạo annotated image.
- Không phụ thuộc hoàn toàn vào sensor threshold.

---

## 5.2 Vì sao không chạy YOLO trực tiếp trên ESP32-CAM?

ESP32-CAM có giới hạn về:

- RAM.
- Flash.
- CPU.
- Frame buffer.
- Thermal stability.
- Power stability.

YOLO26l là model lớn, nên phù hợp chạy trên máy tính hoặc server. ESP32-CAM được dùng như image acquisition gateway.

---

## 5.3 Vì sao dùng HTTP thay vì MQTT?

HTTP thuận tiện cho việc upload trực tiếp một JPEG request body đến FastAPI và nhận response OPEN/CLOSE.

Ưu điểm:

- Dễ debug.
- Dễ tích hợp FastAPI.
- Request–response rõ ràng.
- Phù hợp với image upload.

Hạn chế:

- Có overhead.
- Phụ thuộc network.
- Có thể chậm hơn protocol nhẹ hơn.
- Cần timeout và error handling.

MQTT phù hợp hơn cho message nhỏ và telemetry liên tục, nhưng việc upload ảnh cần thêm thiết kế payload hoặc lưu ảnh ngoài rồi gửi URL.

---

## 5.4 Vì sao confidence 0.45?

Threshold 0.45 là giá trị được chọn cho thử nghiệm cuối.

Nếu tăng threshold:

- Ít false positive hơn.
- Có thể tăng miss rate.

Nếu giảm threshold:

- Có thể tăng số OPEN.
- Có thể tăng false positive.

Muốn chọn threshold tối ưu cần có cả positive và negative samples, sau đó đánh giá precision, recall, F1 hoặc ROC.

---

## 5.5 Tại sao 45.21% không phải accuracy?

Dataset chỉ có positive samples.

```text
Positive sample count = 146
Detected as OPEN = 66
Missed as CLOSE = 80
```

Do không có negative samples nên không tính được:

- True Negative.
- False Positive.
- Specificity.
- Precision đầy đủ.
- Overall accuracy.
- F1-score.

Chỉ có thể nói:

```text
Positive-sample detection rate = 66 / 146 = 45.21%
Miss rate = 80 / 146 = 54.79%
```

---

## 5.6 Inference time và end-to-end response time khác nhau thế nào?

### Inference time

Chỉ là thời gian YOLO xử lý ảnh trên server.

### End-to-end response time

Bao gồm:

```text
Sensor detection
+ Master polling
+ Slave processing
+ UART command
+ Camera capture
+ Image upload
+ YOLO inference
+ HTTP response
+ UART return
+ I2C return
+ Master validation
+ Servo movement
```

Dự án hiện mới đo được inference time.

---

## 5.7 Vì sao fail-close quan trọng?

Fail-close nghĩa là khi không chắc chắn thì cổng không mở.

Ví dụ:

- Wi-Fi mất.
- Server không phản hồi.
- ESP32-CAM không capture được.
- UART trả dữ liệu sai.
- Kết quả cũ bị stale.
- Timeout.

Điều này giảm khả năng cổng mở do lỗi, nhưng làm giảm availability vì xe hợp lệ cũng có thể bị giữ lại khi network lỗi.

---

## 5.8 Hạn chế của Master–Slave hiện tại là gì?

Khi cả hai Slave hoạt động, Master giao tiếp bình thường trong các test quan sát được.

Khi một Slave ngừng hoạt động, Master hiện tại dừng normal operation.

Điều này cho thấy:

- Hardware modular.
- Software chưa fault-isolated.

Future work:

- Health state riêng cho ENTRY và EXIT.
- Timeout riêng.
- Isolate failed module.
- Cho phép healthy direction tiếp tục hoạt động nếu an toàn.

---

## 5.9 Dashboard có phải là real-time không?

Có thể nói dashboard hỗ trợ current monitoring hoặc near-real-time display dựa trên dữ liệu database.

Không nên khẳng định real-time latency vì chưa đo:

- Server-to-database delay.
- Database-to-dashboard delay.
- Auto-refresh interval.
- Complete event synchronization.

---

## 5.10 Hệ thống có nhận diện biển số không?

Không.

Hệ thống hiện chỉ phát hiện vehicle class:

- car
- motorcycle
- bus
- truck

License plate recognition là future work và cần thêm:

- Plate localization.
- OCR.
- Text validation.
- Vehicle database.
- Authorization rule.
- Entry–exit matching.

---

# 6. Câu hỏi phản biện thường gặp

## Câu 1: Vì sao kết quả chỉ đạt 45.21% mà vẫn chọn YOLO26l?

### Trả lời

> Kết quả 45.21% đến từ dataset cuối với ảnh ESP32-CAM của xe mô hình trong điều kiện góc chụp và object scale hạn chế. Trên nguồn ảnh cũ, YOLO26l đạt 94.23%, cao hơn YOLOv8n 13.80 percentage points. Điều này cho thấy model performance phụ thuộc mạnh vào dataset. Nhóm chọn YOLO26l vì nó cho detection consistency tốt hơn trên reused test source, nhưng đồng thời thừa nhận rằng camera setup và local dataset cần được cải thiện.

---

## Câu 2: Vì sao không dùng RFID?

### Trả lời

> RFID phù hợp để xác thực một thẻ hoặc người dùng đã đăng ký, nhưng dự án tập trung vào vehicle presence và visual verification. RFID không cung cấp hình ảnh và không xác nhận trực quan đối tượng trước cổng. Trong future work, RFID có thể được kết hợp với camera để tạo multi-factor vehicle access control.

---

## Câu 3: Nếu server bị mất kết nối thì hệ thống làm gì?

### Trả lời

> ESP32-CAM không nhận được HTTP response hợp lệ nên trả CLOSE. Slave truyền kết quả CLOSE hoặc timeout về Master. Master giữ barrier đóng theo fail-close policy.

---

## Câu 4: Vì sao chỉ Master được điều khiển servo?

### Trả lời

> Nếu nhiều module cùng điều khiển servo, các lệnh có thể xung đột. Việc centralize actuator authority tại Master giúp mọi quyết định OPEN hoặc CLOSE được kiểm tra ở một nơi và bảo đảm kết quả thuộc đúng capture cycle.

---

## Câu 5: 146 ảnh có phải 146 lần hệ thống hoạt động hoàn chỉnh không?

### Trả lời

> Không. Đây là 146 server-side image results từ ESP32-CAM workflow. Chúng chứng minh ảnh đã được xử lý bởi YOLO server. Nhóm chưa có đủ evidence để nói rằng cả 146 ảnh đều tương ứng với 146 barrier cycles hoàn chỉnh.

---

## Câu 6: RQ1 và RQ2 đã được trả lời chưa?

### Trả lời

> Chưa đầy đủ. RQ1 cần controlled HC-SR04 accuracy testing. RQ2 cần synchronized timestamps từ sensor đến servo. Báo cáo hiện chỉ có YOLO positive-sample detection rate và server-side inference time.

---

## Câu 7: Hệ thống khác gì so với các bài báo trước?

### Trả lời

> Điểm khác chính là nhóm tích hợp low-cost ultrasonic trigger, ESP32-CAM image capture, server-side YOLO verification, Arduino Master-controlled barrier, SQL Server logging và Java dashboard trong một modular ENTRY/EXIT architecture. Nhóm cũng áp dụng fail-close policy và tách rõ control path khỏi monitoring path.

---

## Câu 8: Tại sao dùng xe mô hình?

### Trả lời

> Vì phạm vi môn học và giới hạn thiết bị, nhóm xây dựng proof-of-concept trong phòng lab. Xe mô hình và SG90 đủ để kiểm chứng logic sensing, communication, AI decision và actuator control. Kết quả không được khái quát trực tiếp sang xe thật hoặc barrier công nghiệp.

---

# 7. Câu chuyển phần hoàn chỉnh

## Long → Triết

> Tiếp theo, Triết sẽ trình bày về bối cảnh thực tế, các nghiên cứu liên quan và những hạn chế mà nhóm muốn giải quyết.

## Triết → Long

> Từ các vấn đề và khoảng trống vừa trình bày, Long sẽ giới thiệu mục tiêu, phạm vi và kiến trúc giải pháp của nhóm.

## Long → Mẫn

> Sau phần thiết kế phần cứng và workflow, Mẫn sẽ trình bày cơ sở dữ liệu, dashboard và prototype hoàn chỉnh.

## Mẫn → Khoa

> Cuối cùng, Khoa sẽ trình bày phương pháp kiểm thử, kết quả thực nghiệm, giới hạn và hướng phát triển.

---

# 8. Phân bổ thời gian đề xuất

| Phần | Người | Thời gian |
|---|---|---:|
| Slide 1–2 | Long | 1 phút |
| Slide 3–4 | Triết | 2 phút 45 giây |
| Slide 5–9 | Long | 5 phút 20 giây |
| Slide 10–12 | Mẫn | 2 phút 45 giây |
| Slide 13–15 | Khoa | 4 phút |
| Chuyển phần và dự phòng | Cả nhóm | 30–45 giây |
| **Tổng** |  | **Khoảng 15 phút** |

---

# 9. Checklist trước khi thuyết trình

- [ ] Không gọi 45.21% là overall accuracy.
- [ ] Không gọi 432.23 ms là total gate response time.
- [ ] Không nói 146 ảnh là 146 barrier cycles.
- [ ] Không nói đã implement license plate recognition.
- [ ] Không nói có heartbeat.
- [ ] ENTRY luôn là 0x08.
- [ ] EXIT luôn là 0x09.
- [ ] UART là 9600 baud.
- [ ] Camera final: 20 MHz, VGA, JPEG quality 12, one frame buffer.
- [ ] YOLO threshold là 0.45.
- [ ] Allowed classes: car, motorcycle, bus, truck.
- [ ] Chỉ Arduino Master điều khiển SG90.
- [ ] LCD1602 chỉ là debug/status display.
- [ ] Hệ thống là small-scale proof-of-concept.
- [ ] Nêu rõ fail-close policy.
- [ ] Nêu rõ RQ1 và RQ2 chưa được trả lời đầy đủ.

---

# 10. References

[1] A. Z. M. T. Kabir, A. M. Mizan, P. K. Saha, M. S. Hasan, and M. Pramanik, “An IoT-based intelligent parking system for the unutilized parking area with real-time monitoring using mobile and web application,” 2021.

[2] I. Jung, “An IoT-based smart parking management system,” 2020.

[3] S. Y. C. Hong, C. C. Kang, J. D. Tan, and M. Ariannejad, “Smart parking system using IoT sensors,” 2023.

[4] Y. Allbadi, J. N. Shehab, and M. M. Jasim, “The smart parking system using ultrasonic control sensors,” 2021.

[5] V. A. Kusuma et al., “An internet of things-based touchless parking system using ESP32-CAM,” 2023.

[6] E. Saputra et al., “Car parking monitoring system based on location plate detection using web camera,” 2026.

[7] G. P. C. P. da Luz et al., “Smart parking with pixel-wise ROI selection for vehicle detection using YOLOv8, YOLOv9, YOLOv10, and YOLOv11,” 2024.
