import cv2
from deepface import DeepFace
import os
import csv
from datetime import datetime
import threading
import tensorflow as tf

# --- GPU CONFIG ---
gpus = tf.config.experimental.list_physical_devices('GPU')
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
    except RuntimeError as e:
        print(e)

# --- GLOBAL VARIABLES ---
last_results = []
is_processing = False  # Flag to prevent multiple threads from running at once
db_path = r"C:\Users\la_user\Desktop\stat_ai_DF\DB"
file = open("emotions.csv", "a", newline="", encoding="utf-8")

def save_to_csv(writer, student_id, emotion, confidence, lecture_id):
    time_now = datetime.now().strftime("%H:%M:%S")
    writer.writerow([
        student_id,
        time_now,
        emotion,
        confidence,
        lecture_id
    ])

def background_analysis(frame_to_process):
    global last_results, is_processing
    try:
        # 1. Analyze Emotion
        emotions = DeepFace.analyze(frame_to_process, actions=['emotion'],
                                    enforce_detection=False, detector_backend='opencv')

        # 2. Find Identity
        identities = DeepFace.find(img_path=frame_to_process, db_path=db_path,
                                   enforce_detection=False, detector_backend='opencv')

        new_results = []
        for i in range(len(emotions)):
            res = emotions[i]
            name = "Unknown"
            if len(identities) > i and not identities[i].empty:
                file_path = identities[i].iloc[0]['identity']
                name = os.path.basename(os.path.dirname(file_path))
            res['identity_name'] = name
            new_results.append(res)

        last_results = new_results  # Update the main thread's results
    except Exception as e:
        print(f"Analysis error: {e}")
    finally:
        is_processing = False  # Ready for the next task


# --- MAIN LOOP ---
cap = cv2.VideoCapture(0)
target_width, target_height = 480, 360
writer = csv.writer(file)
writer.writerow(["Student_Name", "Time", "Emotion", "Confidence", "Lecture_ID"])


while True:
    ret, frame = cap.read()
    if not ret: break

    h_orig, w_orig = frame.shape[:2]
    x_ratio, y_ratio = w_orig / target_width, h_orig / target_height

    # Kick off a background thread if we aren't already processing
    if not is_processing:
        is_processing = True
        small_frame = cv2.resize(frame, (target_width, target_height))
        thread = threading.Thread(target=background_analysis, args=(small_frame,), daemon=True)
        thread.start()

    # Always draw the last known results (results will "jump" to new faces when thread finishes)
    for res in last_results:
        region = res['region']
        x, y, w, h = int(region['x'] * x_ratio), int(region['y'] * y_ratio), int(region['w'] * x_ratio), int(region['h'] * y_ratio)
        save_to_csv(writer, res['identity_name'], res['emotion'], res['confidence'], "L1")
        label = f"{res['identity_name']} | {res['dominant_emotion']}"
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
        cv2.putText(frame, label, (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    cv2.imshow('Real-Time (Threading Enabled)', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'): break

cap.release()
cv2.destroyAllWindows()