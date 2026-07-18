# SMART PARKING PRESENTATION – INDIVIDUAL SCRIPT

**Project:** A Smart Parking System with Vehicle Detection and Barrier Control  
**Course:** IOT102 – Group 7  
**Presentation language:** Vietnamese

---

# 7. Trần Đăng Khoa – Slide 15–18

## Slide 15 – YOLO Model and Experimental Results

### Script

> Hệ thống sử dụng mô hình YOLO ở backend để xác minh phương tiện từ ảnh do ESP32-CAM gửi lên.  
>  
> Ảnh được resize về 640 nhân 640 pixel. Confidence threshold được đặt là 0.45. Các class được chấp nhận gồm car, motorcycle, bus và truck.  
>  
> Trong tập dữ liệu hiện tại có 146 ảnh, gồm 66 quyết định OPEN và 80 quyết định CLOSE. Trong 66 ảnh OPEN có 43 truck và 23 car.  
>  
> Detection Rate được tính bằng số positive sample được phát hiện đúng chia cho tổng positive sample. Miss Rate là số positive sample bị bỏ sót chia cho tổng positive sample.  
>  
> Kết quả YOLO26l đạt Detection Rate 94.23%, tương ứng 49 trên 52 positive samples, và Miss Rate là 5.77%. Mean inference time là giá trị đo riêng cho quá trình xử lý model trên server, không phải toàn bộ gate response time.  
>  
> So với YOLOv8n, model được chọn có detection rate cao hơn nhưng inference chậm hơn. Nhóm ưu tiên reliability vì model được xử lý trên backend thay vì ESP32-CAM.

### Công thức cần thuộc

\[
DetectionRate = \frac{TP}{TP + FN} \times 100\%
\]

\[
MissRate = \frac{FN}{TP + FN} \times 100\%
\]

Với 49/52:

\[
DetectionRate = \frac{49}{52}\times100\% = 94.23\%
\]

\[
MissRate = \frac{3}{52}\times100\% = 5.77\%
\]

### Kiến thức cần nắm

- Confidence threshold meaning.
- Accepted class meaning.
- OPEN does not necessarily mean correct unless ground truth confirms it.
- Inference time is not end-to-end latency.
- Fair comparison requires same dataset.
- The exact model name must match actual code.

### Câu hỏi

#### Câu 1: Vì sao threshold là 0.45?

**Trả lời:**

> Threshold 0.45 được chọn để cân bằng giữa việc bỏ sót phương tiện và nhận nhầm. Nếu threshold quá cao, model có thể bỏ sót ảnh chất lượng thấp. Nếu quá thấp, false detection tăng. Đây là giá trị dùng trong prototype và cần được tối ưu thêm bằng tập dữ liệu lớn hơn.

#### Câu 2: Vì sao YOLO26l chậm hơn YOLOv8n?

**Trả lời:**

> Model lớn hơn thường có nhiều parameter và computation hơn, nên inference chậm hơn. Đổi lại, model có khả năng biểu diễn tốt hơn và đạt detection rate cao hơn trong thử nghiệm hiện tại.

#### Câu 3: 421.39 ms có phải thời gian từ sensor đến barrier không?

**Trả lời:**

> Không. Đây chỉ là mean model inference time trên server. End-to-end response còn gồm sensor detection, camera capture, Wi-Fi upload, preprocessing, server response và servo movement.

#### Câu 4: Hai model có dùng cùng sample không?

**Trả lời mẫu an toàn nếu chưa rerun cùng dataset:**

> Các số liệu hiện tại được thu ở hai giai đoạn thử nghiệm khác nhau nên sample count chưa hoàn toàn giống nhau. Vì vậy đây là kết quả tham khảo, chưa phải controlled benchmark tuyệt đối. Một bước cải tiến là chạy lại cả hai model trên cùng một fixed test set.

#### Câu 5: 80 ảnh CLOSE gồm những gì?

**Trả lời:**

> CLOSE gồm các trường hợp không có accepted vehicle class, confidence dưới threshold, ảnh không hợp lệ hoặc điều kiện hệ thống không cho phép mở. Khi báo cáo chính thức, nhóm cần phân loại rõ từng trường hợp để tránh hiểu CLOSE là toàn bộ negative ground truth.

---

## Slide 16 – Results and Benefits

### Script

> Về technical results, hệ thống đã thực hiện được toàn bộ chuỗi xử lý từ sensor, camera, YOLO, barrier, database đến dashboard.  
>  
> HC-SR04 có thể kích hoạt quá trình phát hiện. ESP32-CAM chụp và gửi ảnh. Backend tạo quyết định OPEN hoặc CLOSE. Servo phản hồi theo quyết định. Event, confidence, class và image path được lưu trong database. Dashboard hiển thị occupancy, ảnh mới nhất và lịch sử sự kiện.  
>  
> Về practical benefits, hệ thống giảm phụ thuộc vào kiểm tra thủ công, cung cấp visual evidence, hỗ trợ monitoring tập trung và theo dõi occupancy.  
>  
> Đây là lợi ích của prototype, chưa phải kết quả triển khai thương mại.

### Câu hỏi

#### Câu: Có thể nói hệ thống cải thiện security không?

**Trả lời:**

> Nhóm nên nói hệ thống cải thiện verification và traceability vì có ảnh và log. Nhóm chưa thực hiện security testing đầy đủ, nên không khẳng định mức độ bảo mật định lượng.

---

## Slide 17 – AI Used

### Script

> AI được sử dụng như công cụ hỗ trợ trong quá trình tìm tài liệu, đề xuất kiến trúc, lựa chọn metric, hỗ trợ code, debug và diễn giải kết quả.  
>  
> Tuy nhiên, nhóm không sử dụng trực tiếp mọi output do AI tạo ra. Các tài liệu tham khảo được kiểm tra lại, code được chạy trên prototype thật, kết quả được tính lại và các giả định không có bằng chứng được loại bỏ.  
>  
> Ví dụ, AI hỗ trợ đề xuất cách so sánh model, nhưng nhóm phải kiểm tra lại sample count, công thức Detection Rate và inference time trước khi đưa vào slide.

### Kiến thức cần nắm

- AI support is not decision ownership.
- Human verification:
  - source verification;
  - code testing;
  - recalculation;
  - removal of unsupported claims.
- AI hallucination can affect:
  - references;
  - model names;
  - metric interpretation;
  - technical wiring.

### Câu hỏi

#### Câu: AI đã làm bao nhiêu phần trăm project?

**Trả lời:**

> AI hỗ trợ tạo gợi ý và giải thích, nhưng phần triển khai, kết nối phần cứng, chạy server, kiểm thử, thu dữ liệu, xác minh kết quả và quyết định cuối đều do nhóm thực hiện. Nhóm không sử dụng tỷ lệ phần trăm vì khó đo chính xác, mà phân biệt rõ AI Support và Human Verification.

---

## Slide 18 – Conclusion and Future Work

### Script

> Nhóm đã xây dựng được một prototype smart parking chi phí thấp, tích hợp vehicle detection, camera verification, barrier control, occupancy tracking, database storage và web monitoring.  
>  
> Kiến trúc modular giúp tách phần sensor, camera, control và backend, từ đó dễ kiểm thử từng module và tích hợp toàn hệ thống.  
>  
> Tuy nhiên, hệ thống vẫn còn giới hạn về chất lượng camera, low-light performance, Wi-Fi dependency, end-to-end response time và quy mô test data.  
>  
> Trong tương lai, nhóm có thể bổ sung license plate recognition, cải thiện camera, giảm latency, tăng khả năng offline, mở rộng test set và phát triển slot management, reservation hoặc payment.

### Câu hỏi

#### Câu: Future work quan trọng nhất là gì?

**Trả lời:**

> Quan trọng nhất trước tiên là chuẩn hóa experiment và đo end-to-end response time. Sau đó mới bổ sung ANPR, cải thiện low-light và tăng reliability khi Wi-Fi hoặc server lỗi.

#### Câu: Hệ thống có triển khai thực tế được chưa?

**Trả lời:**

> Chưa. Prototype chứng minh kiến trúc và luồng chức năng, nhưng triển khai thực tế cần motor barrier công suất lớn, nguồn ổn định, housing, network reliability, security, backup control và kiểm thử với tập dữ liệu lớn hơn.

### Chuyển tiếp

> Tiếp theo, Nguyễn Sỹ Minh Mẫn sẽ giới thiệu prototype phần cứng hoàn chỉnh và dẫn vào phần demo.

---


# Phần demo của Trần Đăng Khoa

## Nhiệm vụ

- Refresh dashboard sau khi event hoàn thành.
- Chỉ ra event mới.
- Giải thích detected class, confidence, gate decision và timestamp.
- Kiểm tra occupancy đã tăng hoặc giảm đúng.
- Giải thích nếu dashboard chưa cập nhật ngay.

## Câu nói mẫu

> Em refresh dashboard. Dashboard đã cập nhật latest entry image, detected class, confidence, gate decision, event time và vehicles inside.

## Kiến thức bắt buộc

- Tổng ảnh 146.
- OPEN 66 và CLOSE 80.
- 43 truck và 23 car tương ứng 66 OPEN.
- Detection Rate và Miss Rate.
- 49/52 tương ứng 94.23%.
- 3/52 tương ứng 5.77%.
- Inference time không phải end-to-end response time.
- Sự khác nhau giữa kết quả kiểm thử ở các giai đoạn.
- AI support và human verification.
- Giới hạn hiện tại và future work.



# 13. Final Checklist Before Presentation

- [ ] Model name is verified against actual code.
- [ ] Total images = 146.
- [ ] OPEN = 66.
- [ ] CLOSE = 80.
- [ ] 43 trucks + 23 cars = 66 OPEN.
- [ ] Only one inference-time value is used.
- [ ] YOLO comparison conditions are explained.
- [ ] Flowchart closing logic is complete.
- [ ] D13/D2 sync pin matches code and circuit.
- [ ] UART direction is correct.
- [ ] Logic-level conversion is explained.
- [ ] Dashboard is ready before demo.
- [ ] FastAPI server is running.
- [ ] Database connection is verified.
- [ ] ESP32-CAM Wi-Fi is connected.
- [ ] Servo power is stable.
- [ ] Backup screenshots or recorded demo are prepared.