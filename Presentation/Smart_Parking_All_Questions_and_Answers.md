# SMART PARKING – TỔNG HỢP CÂU HỎI ORAL DEFENSE

**Project:** A Smart Parking System with Vehicle Detection and Barrier Control  
**Course:** IOT102 – Group 7  
**Purpose:** Tổng hợp toàn bộ câu hỏi có thể xuất hiện khi thuyết trình, demo và Q&A.

---

# 1. Câu hỏi về tổng quan và phạm vi hệ thống

## 1. Hệ thống này có thực sự là Smart Parking System không?

> Có. Hệ thống không chỉ phát hiện vật thể mà còn tích hợp camera, YOLO vehicle detection, barrier control, occupancy tracking, database và dashboard. Tuy nhiên, đây là prototype smart parking ở mức gate monitoring và barrier control, chưa phải nền tảng thương mại đầy đủ.

## 2. Điểm nổi bật của đề tài là gì?

> Điểm nổi bật là kiến trúc hybrid. HC-SR04 làm trigger ban đầu, ESP32-CAM cung cấp hình ảnh, YOLO xác minh phương tiện, Arduino Master điều khiển barrier, còn database và dashboard hỗ trợ lưu trữ và giám sát.

## 3. Tại sao gọi là smart parking nếu không có slot detection?

> Smart parking là khái niệm rộng. Hệ thống hiện tập trung vào smart gate monitoring và occupancy management. Slot-level detection là một hướng mở rộng, không phải điều kiện bắt buộc duy nhất để một hệ thống được xem là smart parking.

## 4. Scope hiện tại của hệ thống là gì?

> Scope gồm vehicle presence detection tại ENTRY/EXIT, camera capture, YOLO verification, OPEN/CLOSE decision, servo barrier control, occupancy tracking, SQL Server logging và dashboard monitoring.

## 5. Những gì nằm ngoài scope?

> License plate recognition, parking-slot detection, reservation, payment, mobile application, navigation đến chỗ trống và triển khai thương mại thực tế.

## 6. Hệ thống có triển khai thực tế được chưa?

> Chưa. Prototype chứng minh kiến trúc và chức năng. Triển khai thực tế cần motor barrier công suất lớn, nguồn ổn định, housing, network reliability, security, backup control và kiểm thử trên tập dữ liệu lớn hơn.

---

# 2. Câu hỏi về vấn đề và hướng giải quyết

## 7. Hệ thống truyền thống có hạn chế gì?

> Kiểm tra thủ công chậm, dễ sai sót, thiếu hình ảnh xác minh, khó quản lý lịch sử, không có dashboard tập trung và khả năng truy vết thấp.

## 8. Hệ thống của nhóm giải quyết được toàn bộ hạn chế đó không?

> Hệ thống giải quyết ở mức prototype: tự động phát hiện, chụp ảnh, xác minh, lưu log, cập nhật occupancy và hiển thị dashboard. Tuy nhiên, chưa có ANPR, payment hoặc security testing đầy đủ.

## 9. Tại sao không chỉ dùng camera?

> Camera có khả năng xác minh tốt hơn nhưng capture, upload và inference tốn thời gian. HC-SR04 giúp phát hiện nhanh và chỉ kích hoạt camera khi cần, giảm xử lý không cần thiết.

## 10. Tại sao không chỉ dùng ultrasonic sensor?

> Ultrasonic chỉ đo khoảng cách và không xác định được loại vật thể. Người, hộp hoặc vật cản khác cũng có thể kích hoạt sensor. YOLO được dùng làm lớp xác minh thứ hai.

## 11. Hướng giải quyết chính của nhóm là gì?

> Hybrid detection: ultrasonic làm trigger nhanh, camera cung cấp visual evidence, YOLO xác minh phương tiện, Master điều khiển barrier và dashboard hỗ trợ monitoring tập trung.

---

# 3. Câu hỏi về kiến trúc Master–Slave

## 12. Vì sao không dùng ESP32-CAM cho tất cả chức năng?

> ESP32-CAM phải quản lý camera buffer, JPEG capture và Wi-Fi upload. Các tác vụ này có thể gây blocking hoặc delay. Arduino Slave giúp sensor polling và giao tiếp local ổn định hơn.

## 13. Tại sao cần Arduino Slave?

> Slave tách ENTRY và EXIT thành các module độc lập. Mỗi Slave đọc sensor và phối hợp với camera, còn Master chỉ quản lý barrier, LCD và trạng thái tổng thể.

## 14. Tại sao dùng Arduino Master–Slave?

> Kiến trúc này modular, tiết kiệm chân trên Master, dễ debug, dễ mở rộng ENTRY/EXIT và giảm ảnh hưởng của camera hoặc network delay lên logic barrier.

## 15. Nếu một Slave bị lỗi thì sao?

> Prototype hiện tại có thể bị ảnh hưởng khi polling. Hướng cải tiến là thêm timeout, retry, health status và cho phép Master đánh dấu module offline thay vì dừng toàn hệ thống.

## 16. Tại sao dùng I2C?

> I2C chỉ cần SDA và SCL để Master giao tiếp với nhiều Slave. Mỗi Slave được phân biệt bằng địa chỉ riêng, phù hợp với mô hình một Master và nhiều module.

## 17. Địa chỉ của hai Slave là gì?

> ENTRY Slave dùng `0x08`, EXIT Slave dùng `0x09`, nhưng phải kiểm tra lại để bảo đảm code, circuit và slide dùng cùng mapping.

## 18. Sync signal dùng để làm gì?

> Sync signal là đường riêng ngoài I2C để đồng bộ một số trạng thái điều khiển hoặc trigger giữa Master và Slave. Pin cuối cùng phải thống nhất giữa code, circuit và slide.

---

# 4. Câu hỏi về phần cứng và giao tiếp

## 19. Vì sao common ground quan trọng?

> Các tín hiệu số cần cùng mức tham chiếu điện áp. Không có common ground thì UART, I2C và tín hiệu điều khiển có thể hoạt động sai hoặc không ổn định.

## 20. Tại sao cần đổi mức điện áp Arduino sang ESP32?

> Arduino dùng logic 5V, trong khi ESP32 dùng 3.3V. Tín hiệu 5V trực tiếp vào ESP32 RX có thể không an toàn, nên cần voltage divider hoặc level shifter.

## 21. UART giữa Slave và ESP32-CAM hoạt động thế nào?

> Arduino TX nối với ESP32 RX qua chuyển mức điện áp. ESP32 TX nối với Arduino RX. Hai đường phải đấu chéo TX–RX và dùng chung ground.

## 22. HC-SR04 đo khoảng cách như thế nào?

> Sensor gửi sóng siêu âm và đo thời gian echo quay về. Khoảng cách được tính bằng thời gian nhân vận tốc âm thanh rồi chia hai. Trong Arduino thường dùng công thức gần đúng `distance_cm = echo_time_us / 58`.

## 23. HC-SR04 có nhận biết được xe không?

> Không. Nó chỉ biết có vật thể ở một khoảng cách nhất định. YOLO mới thực hiện xác minh loại phương tiện.

## 24. Tại sao vẫn cần LCD khi đã có dashboard?

> LCD1602 là local debugging/status display trong quá trình thử nghiệm. Dashboard mới là giao diện giám sát chính.

## 25. Servo SG90 có đủ cho hệ thống thực tế không?

> Không. SG90 chỉ phù hợp với prototype mô hình nhỏ. Hệ thống thực tế cần motor mạnh hơn, motor driver, limit switch và cơ chế an toàn.

## 26. Tại sao nguồn điện là vấn đề quan trọng?

> ESP32-CAM và servo có thể tạo tải dòng lớn. Nguồn yếu gây reset, lỗi Wi-Fi, lỗi camera hoặc servo không ổn định. Camera cần 5V ổn định và tất cả module phải dùng common ground.

---

# 5. Câu hỏi về flow và barrier

## 27. Luồng hoạt động tổng thể là gì?

> Object detected → capture image → upload to server → YOLO verification → check accepted class → check occupancy → OPEN/CLOSE → control barrier → update occupancy → save event → update dashboard.

## 28. Barrier đóng dựa trên timer hay sensor?

> Timer 3 giây chỉ là thời gian tối thiểu. Barrier chỉ đóng khi sensor xác nhận vùng cổng đã trống.

## 29. Làm sao tránh barrier đóng lên xe?

> Sau khi mở, hệ thống tiếp tục kiểm tra sensor. Nếu vẫn còn vật thể, barrier chưa được phép đóng.

## 30. Nếu mất Wi-Fi thì sao?

> Camera không thể upload ảnh và backend không thể xác minh. Hệ thống giữ trạng thái an toàn là CLOSE.

## 31. Nếu server timeout thì sao?

> Hệ thống không mở barrier tự động. Timeout hoặc lỗi backend phải dẫn đến safe state là CLOSE.

## 32. Nếu confidence thấp hơn threshold thì sao?

> Backend trả CLOSE vì kết quả chưa đủ tin cậy.

## 33. Nếu bãi đầy thì sao?

> Dù YOLO phát hiện đúng phương tiện, ENTRY vẫn trả CLOSE khi `vehicles_inside >= capacity`.

## 34. Nếu người đứng trước sensor thì sao?

> Sensor có thể phát hiện người như một vật thể, nhưng YOLO không xác nhận accepted vehicle class nên barrier vẫn CLOSE.

---

# 6. Câu hỏi về server, YOLO và mô hình

## 35. Vì sao YOLO chạy trên server?

> YOLO cần nhiều RAM và tài nguyên tính toán hơn ESP32-CAM. Server-side inference cho phép dùng model lớn hơn, dễ cập nhật và giảm tải cho camera module.

## 36. Vì sao dùng FastAPI?

> FastAPI phù hợp với Python và YOLO, giúp xây dựng API nhận ảnh, chạy inference, trả decision và lưu dữ liệu nhanh chóng.

## 37. Confidence threshold 0.45 có ý nghĩa gì?

> Detection chỉ được chấp nhận khi confidence lớn hơn hoặc bằng 0.45. Threshold thấp giảm miss nhưng có thể tăng false detection; threshold cao giảm false detection nhưng tăng miss.

## 38. Vì sao chọn threshold 0.45?

> Đây là giá trị thực nghiệm dùng để cân bằng giữa bỏ sót và nhận nhầm trong prototype. Nó vẫn cần được tối ưu trên tập dữ liệu lớn hơn.

## 39. Accepted classes gồm những class nào?

> `car`, `motorcycle`, `bus`, `truck`.

## 40. OPEN được quyết định như thế nào?

> Hình ảnh phải có accepted class với confidence đạt threshold, đồng thời điều kiện occupancy phải cho phép. Nếu một trong các điều kiện không đạt thì CLOSE.

## 41. Tại sao model lớn chậm hơn?

> Model lớn thường có nhiều parameter và phép tính hơn, nên inference chậm hơn nhưng có thể cho detection rate tốt hơn.

## 42. Vì sao chọn model chậm hơn YOLOv8n?

> Prototype ưu tiên reliability trong vehicle verification hơn minimum latency, và inference được chạy trên backend server.

## 43. YOLO26l chính xác là model gì?

> Nhóm phải xác minh tên model đúng theo code, weight file và phiên bản Ultralytics hoặc repository đang sử dụng. Không nên trả lời suy đoán nếu chưa kiểm chứng.

## 44. Hai model có dùng cùng một tập ảnh không?

> Nếu chưa dùng cùng dataset, phải nói rõ đây là kết quả ở hai giai đoạn test khác nhau, chưa phải controlled benchmark tuyệt đối. So sánh công bằng cần cùng fixed test set.

---

# 7. Câu hỏi về dữ liệu và metric

## 45. Tổng số ảnh hiện tại là bao nhiêu?

> 146 ảnh.

## 46. Số OPEN và CLOSE là bao nhiêu?

> 66 OPEN và 80 CLOSE.

## 47. Vì sao 66 OPEN là hợp lý?

> Vì 43 truck + 23 car = 66 accepted vehicle detections.

## 48. Detection Rate được tính như thế nào?

> `Detection Rate = TP / (TP + FN) × 100%`.

## 49. Miss Rate được tính như thế nào?

> `Miss Rate = FN / (TP + FN) × 100%`.

## 50. 49/52 tương ứng bao nhiêu?

> Detection Rate là 94.23%.

## 51. Miss Rate của 49/52 là bao nhiêu?

> Có 3 ảnh bị miss, nên Miss Rate là 5.77%.

## 52. 421.39 ms có phải toàn bộ gate response time không?

> Không. Đây chỉ là mean model inference time. End-to-end response còn gồm sensor, capture, upload, preprocessing, server response và servo.

## 53. End-to-end response time gồm những thành phần nào?

> Sensor detection, image capture, upload, preprocessing, inference, backend response, communication về phần cứng và servo movement.

## 54. 80 ảnh CLOSE gồm những gì?

> Có thể gồm ảnh không có accepted class, confidence thấp, ảnh lỗi, non-vehicle hoặc điều kiện occupancy không cho phép. Cần phân loại rõ khi báo cáo.

## 55. OPEN có đồng nghĩa với detection đúng không?

> Không hoàn toàn. OPEN là quyết định hệ thống. Muốn đánh giá đúng/sai phải có ground truth để xác định TP, FP, TN và FN.

## 56. Metric nào nên bổ sung?

> Precision, recall, false-open rate, false-close rate, confusion matrix và end-to-end response time.

---

# 8. Câu hỏi về database và ERD

## 57. Tại sao không lưu tất cả vào một bảng?

> Current state và historical events có mục đích khác nhau. Tách bảng giúp truy vấn nhanh, tránh lặp dữ liệu và dễ quản lý.

## 58. Bảng `gates` dùng để làm gì?

> Lưu trạng thái hiện tại của ENTRY/EXIT gate, quyết định gần nhất và thời gian cập nhật.

## 59. Bảng `detection_events` dùng để làm gì?

> Lưu lịch sử từng event, bao gồm sensor distance, class, confidence, decision, image path, occupancy before/after và error detail.

## 60. Bảng `parking_occupancy` dùng để làm gì?

> Lưu capacity, số xe hiện tại và thời gian cập nhật gần nhất.

## 61. Vì sao lưu raw image và annotated image?

> Raw image là dữ liệu gốc để kiểm tra lại. Annotated image chứa bounding box, class và confidence do YOLO tạo.

## 62. Làm sao tránh occupancy âm?

> EXIT chỉ giảm khi `vehicles_inside > 0`, và giá trị được giới hạn không nhỏ hơn 0.

## 63. Làm sao tránh vượt capacity?

> ENTRY chỉ tăng khi `vehicles_inside < capacity`. Nếu đã đầy thì trả CLOSE.

## 64. Vì sao dùng SQL Server?

> SQL Server giúp lưu current state, historical events, phục vụ dashboard, audit và thống kê thay vì chỉ giữ dữ liệu tạm trong RAM.

---

# 9. Câu hỏi về dashboard

## 65. Dashboard hiển thị những gì?

> Occupancy, entries today, exits today, gate status, camera status, sensor status, latest entry image, latest exit image và parking-event history.

## 66. Dashboard có chạy YOLO không?

> Không. YOLO chạy ở FastAPI backend. Dashboard chỉ đọc dữ liệu từ database và hiển thị.

## 67. Dashboard có real-time hoàn toàn không?

> Prototype hiện cập nhật theo request hoặc refresh, nên gần real-time nhưng chưa dùng WebSocket hoặc server push.

## 68. Nếu database lỗi thì barrier có hoạt động không?

> Gate decision nên ưu tiên safety và local control. Tuy nhiên event có thể không được lưu. Future work là retry queue hoặc local temporary storage.

## 69. Nếu dashboard chưa cập nhật thì sao?

> Backend và database có thể đã lưu event trước. Dashboard chỉ cần refresh hoặc dùng auto-refresh/WebSocket trong tương lai.

---

# 10. Câu hỏi về AI usage

## 70. AI được dùng vào những việc gì?

> Literature review, architecture suggestion, metric selection, coding support, debugging, model comparison structure và result interpretation.

## 71. AI có quyết định thay nhóm không?

> Không. Nhóm kiểm tra tài liệu, chạy code trên prototype thật, tính lại metric và loại bỏ các giả định không có bằng chứng.

## 72. AI có thể sai ở đâu?

> Tên paper, DOI, model name, wiring, metric interpretation và technical claims.

## 73. Nhóm kiểm chứng AI như thế nào?

> Đối chiếu nguồn chính thức, chạy thực nghiệm, kiểm tra code, tính lại kết quả và ghi nhận các output không hợp lệ trong AI Audit Log.

## 74. AI làm bao nhiêu phần trăm project?

> Không nên đưa ra tỷ lệ phần trăm vì khó đo chính xác. Nên phân biệt rõ AI Support và Human Verification.

---

# 11. Câu hỏi về kết quả, giới hạn và future work

## 75. Kết quả kỹ thuật đã đạt được là gì?

> Sensor kích hoạt detection flow, ESP32-CAM capture/upload ảnh, YOLO trả decision, servo phản hồi, database lưu event và dashboard hiển thị dữ liệu.

## 76. Lợi ích thực tế của prototype là gì?

> Giảm phụ thuộc vào kiểm tra thủ công, có visual evidence, monitoring tập trung, quản lý occupancy và kiến trúc modular.

## 77. Có thể nói hệ thống cải thiện security không?

> Nên nói cải thiện verification và traceability. Chưa có security testing đầy đủ để khẳng định mức độ bảo mật.

## 78. Điểm yếu lớn nhất hiện tại là gì?

> Phụ thuộc camera và Wi-Fi, test dataset nhỏ, end-to-end latency chưa đo đầy đủ và chưa có production-grade fault tolerance.

## 79. Future work quan trọng nhất là gì?

> Chuẩn hóa experiment và đo end-to-end response time. Sau đó cải thiện low-light, offline reliability, ANPR và mở rộng chức năng.

## 80. Tại sao chưa làm license plate recognition?

> Scope hiện tại ưu tiên vehicle detection, barrier control và monitoring. ANPR cần camera tốt hơn, preprocessing và OCR pipeline riêng.

## 81. Tại sao chưa làm payment và reservation?

> Đây là các chức năng ứng dụng cấp cao, không phải trọng tâm của prototype IoT gate-control hiện tại.

---

# 12. Câu hỏi demo và xử lý sự cố

## 82. Demo flow gồm những bước nào?

> Vehicle detected → image captured → YOLO verification → gate decision → barrier control → database update → dashboard display.

## 83. Nếu camera không gửi ảnh thì sao?

> Barrier giữ CLOSE vì chưa có kết quả xác minh.

## 84. Nếu YOLO không phát hiện được xe thì sao?

> Nếu không có accepted class hoặc confidence dưới threshold thì CLOSE.

## 85. Nếu servo không mở thì kiểm tra gì?

> Backend decision, Master signal, servo power, common ground và chân điều khiển.

## 86. Nếu occupancy sai thì kiểm tra gì?

> Event direction ENTRY/EXIT, điều kiện chỉ update khi event accepted và giới hạn từ 0 đến capacity.

## 87. Nếu Wi-Fi bị mất giữa demo thì trả lời thế nào?

> Hệ thống chuyển về safe state CLOSE. Đây là hạn chế hiện tại và cũng là lý do cần offline fallback trong future work.

## 88. Nếu dashboard chưa thấy ảnh mới thì sao?

> Refresh dashboard và kiểm tra event đã được lưu trong database chưa. Dashboard hiện chưa dùng push update.

---

# 13. Câu hỏi riêng theo từng thành viên

## Bùi Đình Long phải trả lời tốt

- Vì sao cần Slave?
- Vì sao không dùng ESP32-only?
- I2C và UART khác nhau thế nào?
- Common ground là gì?
- Barrier đóng theo sensor hay timer?
- Nguồn ESP32-CAM và servo cần lưu ý gì?
- LCD dùng để làm gì?
- Nếu Slave lỗi thì sao?

## Đỗ Thành Triết phải trả lời tốt

- Problem statement là gì?
- Scope và out-of-scope là gì?
- Hybrid detection là gì?
- Vì sao YOLO chạy trên server?
- FastAPI làm gì?
- Threshold 0.45 nghĩa là gì?
- Khi nào backend trả CLOSE?
- Vì sao camera không thay sensor hoàn toàn?

## Nguyễn Sỹ Minh Mẫn phải trả lời tốt

- ERD gồm những bảng nào?
- Current state khác history như thế nào?
- Occupancy update ra sao?
- Vì sao lưu raw và annotated image?
- Dashboard lấy dữ liệu từ đâu?
- Nếu database hoặc dashboard lỗi thì sao?
- Demo flow được điều phối thế nào?

## Trần Đăng Khoa phải trả lời tốt

- Tổng ảnh, OPEN, CLOSE.
- Detection Rate và Miss Rate.
- 49/52 và 3/52.
- Inference time khác system response time thế nào.
- Model comparison có công bằng không.
- 80 CLOSE gồm gì.
- AI support và human verification.
- Giới hạn và future work.

---

# 14. Câu trả lời an toàn khi chưa chắc dữ liệu

Khi không chắc, không được đoán. Có thể trả lời:

> Phần này nhóm chưa có đủ dữ liệu để kết luận định lượng. Trong prototype hiện tại, nhóm mới xác nhận chức năng hoạt động và xem đây là một limitation cần kiểm thử thêm.

Hoặc:

> Số liệu này được thu ở các giai đoạn test khác nhau, nên nhóm xem đây là kết quả tham khảo chứ chưa phải controlled benchmark tuyệt đối.

Hoặc:

> Nhóm sẽ kiểm tra lại code, circuit và log thực nghiệm để xác nhận chính xác thay vì đưa ra một giá trị chưa được kiểm chứng.

---

# 15. Checklist trước Q&A

- [ ] Xác minh chính xác tên model.
- [ ] Chỉ dùng một giá trị mean inference time.
- [ ] Giải thích rõ dataset 146 ảnh.
- [ ] OPEN 66, CLOSE 80.
- [ ] 43 truck + 23 car = 66 OPEN.
- [ ] Giải thích sample 52 trong positive-sample experiment.
- [ ] D13/D2 phải khớp code và circuit.
- [ ] ENTRY 0x08, EXIT 0x09 phải nhất quán.
- [ ] UART TX/RX direction phải chính xác.
- [ ] Biết safe-state khi timeout.
- [ ] Dashboard, server và database phải sẵn sàng trước demo.
