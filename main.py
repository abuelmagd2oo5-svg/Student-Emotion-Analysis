import cv2
from deepface import DeepFace
import csv
from datetime import datetime
def save_to_csv(writer, student_id, emotion, confidence, lecture_id):

    time_now = datetime.now().strftime("%H:%M:%S")

    writer.writerow([
        student_id,
        time_now,
        emotion,
        confidence,
        lecture_id
    ])
    
cap = cv2.VideoCapture(0)

file = open("emotions.csv", "a", newline="", encoding="utf-8")
writer = csv.writer(file)

writer.writerow(["Student_ID", "Time", "Emotion", "Confidence", "Lecture_ID"])

while True:
    ret, frame = cap.read()

    if not ret:
        break

    try:
        results = DeepFace.analyze(
            frame,
            actions=['emotion'],
            enforce_detection=False
        )

        if isinstance(results, dict):
            results = [results]

        for i, result in enumerate(results):
            emotion = result['dominant_emotion']
            conf = result['emotion'][emotion]

            student_id = f"S{i+1}"  
            lecture_id = "L1"

            save_to_csv(writer, student_id, emotion, conf, lecture_id)

            region = result['region']
            x, y, w, h = region['x'], region['y'], region['w'], region['h']

            cv2.rectangle(frame, (x,y), (x+w,y+h), (0,255,0), 2)
            cv2.putText(frame, emotion, (x, y-10),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.8, (0,255,0), 2)

    except:
        pass

    cv2.imshow("Emotion Dataset System", frame)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
file.close()
cv2.destroyAllWindows()