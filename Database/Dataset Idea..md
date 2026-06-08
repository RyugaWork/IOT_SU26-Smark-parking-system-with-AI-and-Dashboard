Chủ nhân, nên chia dataset thành 2 nhóm riêng: dataset ảnh cho AI/YOLO và dataset CSV cho database + dashboard. Đừng cố tìm một dataset làm hết mọi thứ, vì ảnh nhận dạng biển số và dữ liệu occupancy thường là hai bài toán khác nhau.

1. Từ khóa tìm kiếm trên Kaggle

Dùng các keyword này:

Mục tiêu	Keyword nên tìm
Nhận dạng biển số	license plate detection YOLO, car number plate YOLO format, ANPR YOLO dataset, vehicle license plate detection
Nhận dạng xe + biển số	car and license plate detection YOLO, vehicle detection YOLO, car detection bounding box
Parking slot occupied/empty bằng ảnh	parking occupancy image dataset, parking lot occupancy detection, PKLot dataset, parking space detection YOLO
CSV cho dashboard	smart parking dataset csv, IoT smart parking dataset, parking occupancy timestamp slot, parking management dataset, parking transactions dataset
2. Dataset nên chọn cho dự án IoT102
Dataset	Loại	Dùng cho phần nào	Nhận xét
Car Number Plate Dataset (YOLO Format)	Ảnh + annotation YOLO	Train/test YOLO nhận diện biển số	Phù hợp vì đã có annotation YOLO, đỡ mất công convert label.
License Plate Detection Dataset ANPR (YOLO Format)	Ảnh + label YOLO	Demo YOLOv8/YOLO11 nhận diện biển số	Nhỏ, khoảng vài trăm ảnh, có cấu trúc train/val và single class license plate, hợp sinh viên demo.
Car and License Plate Detection	Ảnh + XML/TXT YOLO	Nhận diện cả xe và biển số	Có cả object car và license plate, hợp với flow cổng gửi ảnh rồi AI xác định xe hợp lệ.
Car License Plate Detection	Ảnh + PASCAL VOC	Test detection biển số	Nhỏ, 433 ảnh, nhưng annotation là PASCAL VOC nên phải convert sang YOLO nếu muốn train YOLO trực tiếp.
PKLot Dataset	Ảnh bãi xe + nhãn occupied/empty	Demo parking occupancy bằng camera	Có 12,416 ảnh bãi xe, nhiều điều kiện thời tiết, slot được gán nhãn occupied/empty. Hợp nếu muốn demo nhận diện chỗ trống/chỗ có xe.
IoT based Smart Parking System dataset	CSV/time-series	Dữ liệu mẫu cho SQL Server + Dashboard	Rất hợp vì có dữ liệu IoT theo timestamp, gồm created_at, field1 = parking slot ID, field2 = availability.
Smart Parking Management Dataset	CSV	Dashboard quản lý bãi xe	Dữ liệu từ hệ thống IoT parking, giai đoạn 01/2021 đến 06/2024, dùng được cho phân tích occupancy/demand.
Smart Parking Usage and Occupancy Analytics	CSV	Dashboard occupancy, zone, demand	Phù hợp nếu muốn dashboard có biểu đồ usage pattern, occupancy level, demand theo khu vực/thời gian.
Parking Dynamic Dataset	CSV	Dashboard nâng cao	Có khoảng 18,400 records và 11 cột về parking activity, traffic condition, vehicle type. Dùng tốt nếu cần dữ liệu phong phú hơn.

Khuyến nghị thực tế cho nhóm của Chủ nhân: dùng License Plate Detection Dataset ANPR (YOLO Format) hoặc Car Number Plate Dataset (YOLO Format) cho phần AI, và dùng IoT based Smart Parking System dataset cho SQL Server/Web Dashboard. Hai dataset này nhẹ, đúng mục tiêu, dễ giải thích trong demo.

3. Cách đánh giá dataset có phù hợp không

Với dataset ảnh YOLO, kiểm tra các tiêu chí này:

Tiêu chí	Cách kiểm tra
Có annotation không	Phải có file .txt, .xml, .json, hoặc .csv chứa bounding box.
Có đúng YOLO format không	File label .txt phải có dạng: class_id x_center y_center width height. Tọa độ phải được normalize từ 0 đến 1. Ultralytics yêu cầu label YOLO dùng một file .txt cho mỗi ảnh, mỗi dòng là class x_center y_center width height.
Có folder train/val/test không	Tốt nhất có sẵn images/train, images/val, labels/train, labels/val.
Số ảnh vừa đủ	Demo môn IoT102 chỉ cần 300–1000 ảnh. Không cần dataset quá lớn.
Có class phù hợp không	Với dự án này nên có car, motorcycle, truck, license_plate, hoặc tối thiểu license_plate.
Ảnh có gần thực tế không	Nên có ảnh xe ở góc camera gần giống ESP32-CAM: trước/sau xe, khoảng cách gần, ánh sáng bình thường.

Với dataset CSV, kiểm tra các tiêu chí này:

Tiêu chí	Cách kiểm tra
Có timestamp	Cần cột kiểu created_at, timestamp, datetime, date_time.
Có parking slot	Cần cột slot_id, parking_slot, space_id, field1.
Có trạng thái	Cần cột occupied, available, status, availability, field2.
Có thể map vào database	Cột phải đủ để tạo bảng ParkingSlotStatus, VehicleEvent, hoặc SensorReading.
Dữ liệu không quá lớn	Demo nên lấy 500–5000 dòng là đủ cho dashboard.
Có license rõ	Nên chọn dataset public hoặc license cho phép dùng học thuật/demo.
4. Cách import dataset CSV vào SQL Server

Giả sử dataset có dạng:

created_at,field1,field2
2024-01-01 08:00:00,A01,1
2024-01-01 08:01:00,A02,0

Tạo bảng staging trước:

CREATE TABLE dbo.StagingSmartParking
(
    created_at NVARCHAR(50) NULL,
    field1 NVARCHAR(50) NULL,
    field2 NVARCHAR(50) NULL
);

Import CSV bằng BULK INSERT:

BULK INSERT dbo.StagingSmartParking
FROM 'C:\SmartParking\smart_parking_sample.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

SQL Server hỗ trợ FORMAT = 'CSV' từ SQL Server 2017 trở lên.

Sau đó đưa dữ liệu từ staging vào bảng chính:

CREATE TABLE dbo.ParkingSlotStatus
(
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    slot_code NVARCHAR(50) NOT NULL,
    recorded_at DATETIME2 NOT NULL,
    is_occupied BIT NOT NULL,
    source_type NVARCHAR(50) NOT NULL DEFAULT 'Kaggle CSV'
);
INSERT INTO dbo.ParkingSlotStatus
(
    slot_code,
    recorded_at,
    is_occupied,
    source_type
)
SELECT
    field1 AS slot_code,
    TRY_CONVERT(DATETIME2, created_at) AS recorded_at,
    CASE 
        WHEN field2 IN ('1', 'occupied', 'OCCUPIED', 'true', 'TRUE') THEN 1
        WHEN field2 IN ('0', 'available', 'AVAILABLE', 'empty', 'EMPTY', 'false', 'FALSE') THEN 0
        ELSE 0
    END AS is_occupied,
    'Kaggle CSV' AS source_type
FROM dbo.StagingSmartParking
WHERE TRY_CONVERT(DATETIME2, created_at) IS NOT NULL;

Lưu ý: phải mở CSV ra xem field2 = 1 là occupied hay available. Một số dataset dùng 1 = available, một số dataset dùng 1 = occupied, nên không được đoán bừa.

5. Cách dùng dataset ảnh để test YOLO

Nếu dataset đã có YOLO format, cấu trúc nên như sau:

license_plate_dataset/
│
├── images/
│   ├── train/
│   └── val/
│
├── labels/
│   ├── train/
│   └── val/
│
└── data.yaml

File data.yaml tối thiểu:

path: C:/SmartParking/license_plate_dataset
train: images/train
val: images/val

names:
  0: license_plate

Train YOLO:

pip install ultralytics
yolo detect train model=yolo11n.pt data=data.yaml epochs=30 imgsz=640 batch=8

Test một ảnh:

yolo detect predict model=runs/detect/train/weights/best.pt source=test_car.jpg conf=0.25

Nếu chỉ cần demo nhanh, Chủ nhân không cần train từ đầu. Có thể dùng model YOLO pretrained để detect car, motorcycle, truck, sau đó dùng model biển số nhỏ để detect license_plate. Với môn IoT102, hướng này dễ demo hơn vì nhóm có thể tập trung vào flow: ESP32-CAM chụp ảnh → FastAPI nhận ảnh → YOLO predict → lưu kết quả vào SQL Server → Dashboard hiển thị.

6. Cách trích một phần nhỏ dataset để demo

Với CSV, lấy 1000 dòng đầu:

import pandas as pd

df = pd.read_csv("smart_parking_full.csv")
sample = df.head(1000)
sample.to_csv("smart_parking_sample.csv", index=False)

Hoặc lấy ngẫu nhiên 2000 dòng:

import pandas as pd

df = pd.read_csv("smart_parking_full.csv")
sample = df.sample(n=2000, random_state=42)
sample.to_csv("smart_parking_sample.csv", index=False)

Với dataset ảnh YOLO, lấy 300 ảnh train và 100 ảnh val:

from pathlib import Path
import shutil
import random

src = Path("license_plate_dataset")
dst = Path("license_plate_demo")

for split, n in [("train", 300), ("val", 100)]:
    img_dir = src / "images" / split
    lbl_dir = src / "labels" / split

    out_img = dst / "images" / split
    out_lbl = dst / "labels" / split
    out_img.mkdir(parents=True, exist_ok=True)
    out_lbl.mkdir(parents=True, exist_ok=True)

    images = list(img_dir.glob("*.jpg")) + list(img_dir.glob("*.png")) + list(img_dir.glob("*.jpeg"))
    random.seed(42)
    selected = random.sample(images, min(n, len(images)))

    for img_path in selected:
        label_path = lbl_dir / (img_path.stem + ".txt")

        shutil.copy(img_path, out_img / img_path.name)

        if label_path.exists():
            shutil.copy(label_path, out_lbl / label_path.name)

Sau đó tạo data.yaml cho bản demo:

path: C:/SmartParking/license_plate_demo
train: images/train
val: images/val

names:
  0: license_plate
7. Cách đưa dataset vào đúng hệ thống Smart Parking của nhóm

Luồng demo nên làm như này:

Dataset ảnh
→ YOLO detect vehicle/license_plate
→ Backend nhận kết quả: vehicle_type, plate_text hoặc plate_detected, confidence, image_path
→ SQL Server lưu AI result + vehicle event
→ Web Dashboard hiển thị lịch sử vào/ra, ảnh, confidence, trạng thái cổng

Dataset CSV dùng để tạo dữ liệu nền:

Dataset CSV parking occupancy
→ Import vào SQL Server
→ Map thành ParkingSlotStatus / SensorReading
→ Dashboard hiển thị số slot trống, slot đang occupied, biểu đồ occupancy theo thời gian

Chốt lựa chọn tốt nhất cho Chủ nhân:

Phần hệ thống	Dataset nên dùng
YOLO biển số	License Plate Detection Dataset ANPR (YOLO Format) hoặc Car Number Plate Dataset (YOLO Format)
YOLO xe + biển số	Car and License Plate Detection
Parking occupancy bằng ảnh	PKLot Dataset
SQL Server + Dashboard CSV	IoT based Smart Parking System dataset
Dashboard nâng cao	Smart Parking Usage and Occupancy Analytics hoặc Parking Dynamic Dataset
