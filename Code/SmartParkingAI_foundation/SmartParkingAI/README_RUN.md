# SmartParkingAI - FastAPI + SQL Server Dashboard

## 1. Install packages

```bash
cd SmartParkingAI
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

## 2. Prepare SQL Server

Open SQL Server Management Studio and run:

```text
sql/smart_parking.sql
```

Default database:

```text
SmartParkingIOT102
```

## 3. Configure database connection

Default config is inside `database.py`:

```python
DB_HOST = "localhost"
DB_PORT = "1433"
DB_NAME = "SmartParkingIOT102"
DB_USER = "sa"
DB_PASSWORD = "12345"
DB_DRIVER = "ODBC Driver 17 for SQL Server"
```

If your PC uses ODBC Driver 18, change:

```python
DB_DRIVER = "ODBC Driver 18 for SQL Server"
```

## 4. Run backend

```bash
uvicorn main:app --reload
```

Open:

```text
http://127.0.0.1:8000
```

Check API:

```text
http://127.0.0.1:8000/api/health
http://127.0.0.1:8000/api/dashboard
```

## 5. Test entry/exit detection without YOLO

Open FastAPI docs:

```text
http://127.0.0.1:8000/docs
```

Use:

```text
POST /api/detect/entry
POST /api/detect/exit
```

Upload any vehicle image and fill `mock_plate`, for example:

```text
71AA-23210
```

The system will save the image, update SQL Server, and refresh the dashboard automatically.

## 6. Where to integrate YOLO later

Edit:

```text
yolo_service.py
```

Replace the function:

```python
detect_vehicle()
```

with real YOLO/OCR logic.
