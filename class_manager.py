from db import get_connection

def get_classes():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("EXEC SP_GET_CLASSES")
    classes = cursor.fetchall()

    conn.close()
    return classes
