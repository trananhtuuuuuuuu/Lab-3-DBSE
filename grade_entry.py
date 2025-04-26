from db import get_connection

def insert_grade(masv, mahp, diemthi, manv):
    conn = get_connection()
    cursor = conn.cursor()

    # Gọi SP, để SQL Server tự mã hóa
    cursor.execute("EXEC SP_INSERT_GRADE ?, ?, ?, ?", (masv, mahp, diemthi, manv))

    print(f"✅ Đã insert điểm thi đã mã hóa cho {masv} - {mahp}")
    conn.commit()
    conn.close()
