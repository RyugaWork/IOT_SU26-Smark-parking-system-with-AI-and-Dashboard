from pathlib import Path

from ultralytics import YOLO


def main() -> None:
    image_path = Path("test.jpg")

    if not image_path.exists():
        raise FileNotFoundError(f"Image not found: {image_path.resolve()}")

    # Automatically downloads yolo26l.pt on first use.
    model = YOLO("yolo26l.pt")

    results = model.predict(
        source=str(image_path),
        imgsz=960,
        conf=0.20,
        classes=[2, 3, 5, 7],
        save=True,
        verbose=True,
    )

    result = results[0]

    if result.boxes is None or len(result.boxes) == 0:
        print("No vehicle detected.")
        return

    for box in result.boxes:
        class_id = int(box.cls.item())
        confidence = float(box.conf.item())
        class_name = model.names[class_id]

        print(
            f"class={class_name}, "
            f"class_id={class_id}, "
            f"confidence={confidence:.3f}"
        )


if __name__ == "__main__":
    main()