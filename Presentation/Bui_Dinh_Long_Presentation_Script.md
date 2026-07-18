# SMART PARKING PRESENTATION – INDIVIDUAL SCRIPT

**Project:** A Smart Parking System with Vehicle Detection and Barrier Control  
**Course:** IOT102 – Group 7  
**Presentation language:** Vietnamese

---

# 3. Bùi Đình Long – Slide 1–2

## Slide 1 – Title

### Script

> Em xin chào thầy và các bạn. Nhóm em là Group 7, và đề tài của nhóm là **A Smart Parking System with Vehicle Detection and Barrier Control**.  
>  
> Mục tiêu của nhóm là xây dựng một prototype bãi xe thông minh quy mô nhỏ, có khả năng phát hiện phương tiện tại cổng vào và cổng ra, chụp ảnh, xác minh phương tiện bằng mô hình YOLO, điều khiển barrier, cập nhật số lượng xe và hiển thị thông tin trên web dashboard.  
>  
> Hệ thống được phát triển trong môn IOT102 và tập trung vào việc kết hợp phần cứng IoT, AI server, cơ sở dữ liệu và giao diện web thành một quy trình hoàn chỉnh.

### Kiến thức cần nắm

Long cần hiểu rõ:

- Đây không chỉ là hệ thống cảm biến.
- Đây không chỉ là dashboard.
- Đây là hệ thống tích hợp nhiều lớp:
  - Device Layer;
  - Server Layer;
  - Application Layer.
- Chức năng trung tâm là:
  - detect;
  - verify;
  - decide;
  - control;
  - store;
  - monitor.

### Câu hỏi có thể được hỏi

#### Câu 1: Hệ thống này có thực sự là smart parking system không?

**Trả lời:**

> Có, vì hệ thống không chỉ phát hiện vật thể mà còn kết hợp camera, AI vehicle detection, barrier control, occupancy tracking, database và dashboard. Tuy nhiên, đây là prototype smart parking ở mức gate monitoring và barrier control, chưa phải hệ thống thương mại đầy đủ có reservation, payment hoặc slot navigation.

#### Câu 2: Điểm nổi bật của đề tài là gì?

**Trả lời:**

> Điểm nổi bật là nhóm kết hợp ultrasonic sensor làm lớp kích hoạt ban đầu với ESP32-CAM và YOLO làm lớp xác minh phương tiện. Sau đó, quyết định OPEN hoặc CLOSE được truyền về để điều khiển barrier, đồng thời toàn bộ sự kiện được lưu và hiển thị trên dashboard.

---

## Slide 2 – Team Members

### Script

> Nhóm gồm bốn thành viên.  
>  
> Em là Bùi Đình Long, phụ trách phần hardware và Arduino, đồng thời hỗ trợ report writing.  
>  
> Đỗ Thành Triết phụ trách hardware, Arduino và YOLO server.  
>  
> Nguyễn Sỹ Minh Mẫn phụ trách web dashboard, SQL Server và tích hợp dữ liệu.  
>  
> Trần Đăng Khoa phụ trách web dashboard, SQL Server và report writing.  
>  
> Trong quá trình thực hiện, các phần không hoạt động độc lập mà được kiểm thử theo hướng tích hợp toàn hệ thống.

### Kiến thức cần nắm

- Không nên nói mỗi người làm tách biệt hoàn toàn.
- Nên nhấn mạnh có phân công chính nhưng vẫn tích hợp chung.
- Long phải nhớ đúng tên và vai trò từng thành viên.

### Câu hỏi có thể được hỏi

#### Câu: Phần nào khó tích hợp nhất?

**Trả lời:**

> Phần khó nhất là tích hợp giữa sensor, ESP32-CAM, backend YOLO và barrier. Vì camera upload và xử lý AI có độ trễ, trong khi phần điều khiển barrier cần phản hồi ổn định. Do đó nhóm tách nhiệm vụ giữa Arduino Slave, ESP32-CAM và Arduino Master.

### Chuyển tiếp

> Sau đây, bạn Đỗ Thành Triết sẽ trình bày bối cảnh, vấn đề và phạm vi của hệ thống.

---

# 5. Bùi Đình Long – Slide 6–12

## Slide 6 – Hardware Block Diagram

### Script

> Hệ thống phần cứng được chia thành ba nhóm chính.  
>  
> Arduino Master là bộ điều khiển trung tâm, phụ trách servo barrier và LCD status display.  
>  
> Hai Arduino Slave tương ứng với cổng ENTRY và EXIT. Mỗi Slave đọc HC-SR04 và giao tiếp với một ESP32-CAM.  
>  
> Master giao tiếp với các Slave qua I2C. Slave và ESP32-CAM giao tiếp qua UART. ESP32-CAM gửi ảnh đến server qua Wi-Fi.  
>  
> Nhóm không dùng ESP32-CAM để thay toàn bộ Arduino Slave vì camera và Wi-Fi có thể gây blocking hoặc delay. Slave giúp sensor polling và giao tiếp local ổn định hơn.

### Kiến thức cần nắm

- Master:
  - control servo;
  - display status;
  - poll Slave;
  - handle final decision.
- Slave:
  - read HC-SR04;
  - trigger camera;
  - hold result;
  - respond to Master.
- ESP32-CAM:
  - capture image;
  - connect Wi-Fi;
  - upload image;
  - receive backend decision.

### Câu hỏi quan trọng

#### Câu: Vì sao không dùng một ESP32 cho tất cả?

**Trả lời:**

> ESP32 có thể làm nhiều chức năng, nhưng trong prototype này ESP32-CAM còn phải quản lý camera buffer, JPEG capture và Wi-Fi upload. Các tác vụ này có thể làm chậm sensor polling và logic gate. Arduino Slave tách phần sensor và giao tiếp local, giúp hệ thống modular và dễ debug hơn.

#### Câu: Tại sao cần Slave?

**Trả lời:**

> Slave giúp tách ENTRY và EXIT thành hai module độc lập. Mỗi module chịu trách nhiệm đọc sensor và phối hợp với camera. Master chỉ cần quản lý quyết định cuối, barrier và trạng thái tổng thể.

---

## Slide 7 – Overall System Architecture

### Script

> Kiến trúc hệ thống gồm ba layer.  
>  
> Device Layer gồm Arduino Master, Arduino Slave, HC-SR04, ESP32-CAM, servo và LCD.  
>  
> Server Layer gồm FastAPI backend, YOLO model và SQL Server. Server tiếp nhận ảnh, thực hiện detection, tạo quyết định và lưu dữ liệu.  
>  
> Application Layer là Java Web dashboard, dùng để hiển thị occupancy, trạng thái gate, sensor, ảnh mới nhất và lịch sử sự kiện.  
>  
> Luồng dữ liệu đi từ thiết bị đến server, sau đó kết quả được trả về phần cứng và đồng thời lưu vào database để dashboard truy xuất.

### Câu hỏi

#### Câu: Vì sao YOLO đặt ở server?

**Trả lời:**

> Vì YOLO cần nhiều RAM và tài nguyên tính toán hơn khả năng thực tế của ESP32-CAM. Server-side inference cho phép dùng model lớn hơn, dễ cập nhật model và không làm quá tải camera module.

---

## Slide 8 – Full Circuit Diagram

### Script

> Đây là sơ đồ tổng thể của toàn bộ mạch. Nó thể hiện Arduino Master, hai Slave, hai HC-SR04, hai ESP32-CAM, servo, LCD, I2C bus, UART và common ground.  
>  
> Vì sơ đồ tổng thể có nhiều kết nối, các slide tiếp theo sẽ tách phần Master–Slave, Master module và Slave module để giải thích rõ hơn.

### Kiến thức cần nắm

- Common ground là bắt buộc.
- Nguồn cho camera phải ổn định.
- Không nên cấp sai điện áp cho ESP32-CAM.
- Servo có thể gây sụt áp nếu dùng chung nguồn yếu.

### Câu hỏi

#### Câu: Tại sao common ground quan trọng?

**Trả lời:**

> Các tín hiệu số cần cùng một mức tham chiếu điện áp. Nếu không có common ground, UART, I2C và các tín hiệu điều khiển có thể bị sai mức hoặc không ổn định.

---

## Slide 9 – Master–Slave Connection

### Script

> Master giao tiếp với hai Slave qua I2C. A4 là SDA và A5 là SCL. Hai Slave có địa chỉ riêng, ENTRY là 0x08 và EXIT là 0x09.  
>  
> Ngoài I2C, hệ thống có một sync signal từ Master D13 sang Slave D2 để đồng bộ một số trạng thái điều khiển.  
>  
> Tất cả các board phải dùng common ground.

### Kiến thức cần nắm

- I2C allows multiple slaves.
- Address identifies each Slave.
- SDA carries data.
- SCL carries clock.
- Sync line is separate from I2C.

### Câu hỏi

#### Câu: Tại sao dùng I2C?

**Trả lời:**

> I2C phù hợp vì chỉ cần hai đường SDA và SCL để Master giao tiếp với nhiều Slave. Mỗi Slave được phân biệt bằng địa chỉ, giúp tiết kiệm chân và phù hợp với kiến trúc một Master, nhiều module.

#### Câu: Nếu một Slave bị lỗi thì sao?

**Trả lời:**

> Trong prototype hiện tại, lỗi một Slave có thể ảnh hưởng quá trình polling hoặc khiến Master không nhận được dữ liệu đúng thời gian. Hướng cải tiến là thêm timeout, retry và cơ chế đánh dấu module offline thay vì dừng toàn hệ thống.

---

## Slide 10 – Master Circuit

### Script

> Arduino Master điều khiển servo SG90 qua chân D11. Servo được dùng để mở và đóng barrier.  
>  
> LCD1602 được kết nối ở chế độ parallel và chỉ dùng làm local debugging hoặc status display trong quá trình kiểm thử. Dashboard mới là giao diện giám sát chính.  
>  
> Master cũng quản lý I2C với các Slave và nhận quyết định OPEN/CLOSE để điều khiển barrier.

### Câu hỏi

#### Câu: Tại sao vẫn cần LCD khi đã có dashboard?

**Trả lời:**

> LCD giúp debug tại chỗ khi kiểm thử phần cứng, đặc biệt khi server hoặc dashboard chưa hoạt động. Nó hiển thị trạng thái cơ bản như detection, OPEN, CLOSE hoặc lỗi giao tiếp.

#### Câu: Servo có đủ cho hệ thống thực tế không?

**Trả lời:**

> SG90 chỉ phù hợp cho prototype mô hình nhỏ. Hệ thống thực tế cần motor công suất lớn hơn, driver, limit switch và cơ chế an toàn.

---

## Slide 11 – Slave Circuit

### Script

> Mỗi Slave kết nối với một HC-SR04 và một ESP32-CAM.  
>  
> HC-SR04 sử dụng TRIG và ECHO để đo khoảng cách. Khi khoảng cách nhỏ hơn ngưỡng, Slave xác định có vật thể và yêu cầu camera chụp ảnh.  
>  
> Slave và ESP32-CAM giao tiếp qua UART. Vì Arduino dùng logic 5V trong khi ESP32 dùng 3.3V, đường tín hiệu từ Arduino sang ESP32 phải có logic-level conversion phù hợp.  
>  
> Hai module ENTRY và EXIT có cấu trúc giống nhau.

### Kiến thức cần nắm

Distance formula:

\[
Distance = \frac{EchoTime \times SpeedOfSound}{2}
\]

Typical simplified Arduino formula:

\[
Distance(cm) = \frac{EchoTime(\mu s)}{58}
\]

### Câu hỏi

#### Câu: HC-SR04 có nhận biết được xe không?

**Trả lời:**

> Không. HC-SR04 chỉ đo khoảng cách và phát hiện vật thể. Vì vậy nhóm dùng YOLO để xác minh xem ảnh có chứa car, motorcycle, bus hoặc truck hay không.

#### Câu: Tại sao cần đổi mức điện áp?

**Trả lời:**

> ESP32 sử dụng logic 3.3V. Tín hiệu 5V trực tiếp từ Arduino có thể không an toàn cho chân RX của ESP32, nên phải giảm mức bằng voltage divider hoặc level shifter.

---

## Slide 12 – High-Level Flowchart

### Script

> Luồng hoạt động bắt đầu khi sensor phát hiện vật thể. Slave yêu cầu ESP32-CAM chụp ảnh và gửi ảnh đến server.  
>  
> YOLO kiểm tra xem ảnh có chứa phương tiện thuộc class được chấp nhận hay không. Nếu hợp lệ và điều kiện occupancy cho phép, server trả về OPEN. Nếu không, server trả về CLOSE.  
>  
> Master mở barrier khi nhận OPEN, cập nhật trạng thái LCD và lưu sự kiện. Sau ít nhất 3 giây, barrier chỉ đóng khi sensor không còn phát hiện vật thể.  
>  
> Nếu confidence thấp, bãi đầy hoặc server timeout, hệ thống giữ trạng thái an toàn là CLOSE.

### Câu hỏi

#### Câu: Nếu mất Wi-Fi thì sao?

**Trả lời:**

> Camera không thể gửi ảnh và server không thể xác minh. Trong trường hợp đó, hệ thống không nên mở tự động mà giữ CLOSE. Manual override có thể được dùng trong giai đoạn prototype nếu cần.

#### Câu: Barrier đóng dựa trên timer hay sensor?

**Trả lời:**

> Timer 3 giây chỉ là thời gian tối thiểu. Điều kiện chính để đóng là sensor xác nhận vùng barrier đã không còn vật thể.

### Chuyển tiếp

> Tiếp theo, Nguyễn Sỹ Minh Mẫn sẽ trình bày cách dữ liệu được lưu trong hệ thống và cách dashboard hiển thị trạng thái.

---


# Phần demo của Bùi Đình Long

## Nhiệm vụ

- Đặt mô hình phương tiện tại sensor ENTRY hoặc EXIT.
- Theo dõi phản ứng của HC-SR04.
- Chỉ ra thời điểm servo barrier mở và đóng.
- Hỗ trợ kiểm tra nguồn, dây nối và common ground nếu demo lỗi.

## Câu nói mẫu

> Em đặt phương tiện trước sensor ENTRY. Sensor đã phát hiện vật thể và kích hoạt quá trình capture.

> Arduino Master đã nhận quyết định OPEN và điều khiển servo mở barrier.

## Kiến thức bắt buộc

- Master, Slave và ESP32-CAM khác nhau ở vai trò nào.
- Vì sao dùng Arduino Slave thay vì chỉ dùng ESP32-CAM.
- I2C, UART, common ground.
- Nguồn 5V ổn định cho ESP32-CAM và servo.
- Điều kiện đóng barrier.
- Safe state khi mất server hoặc Wi-Fi.



# 12. Kiến thức tối thiểu từng người phải thuộc

## Bùi Đình Long

- toàn bộ phần cứng;
- vai trò Master, Slave, ESP32-CAM;
- I2C, UART, common ground;
- servo and LCD;
- power stability;
- flowchart;
- lý do không dùng ESP32-only.

## Đỗ Thành Triết

- vấn đề thực tế;
- project scope;
- hybrid solution;
- HC-SR04 limitation;
- YOLO server purpose;
- difference between prototype and commercial system.

## Nguyễn Sỹ Minh Mẫn

- ERD;
- current-state vs event-history tables;
- occupancy logic;
- dashboard data flow;
- image paths;
- demo coordination;
- failure explanation.

## Trần Đăng Khoa

- exact model name;
- threshold;
- dataset composition;
- Detection Rate and Miss Rate;
- inference time vs system response time;
- AI audit;
- limitations and future work.

---