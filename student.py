from db import get_connection

def get_students_by_class(malop, manv):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC SP_GET_STUDENTS_BY_CLASS ?, ?", (malop, manv))
    students = cursor.fetchall()
    conn.close()
    return students

