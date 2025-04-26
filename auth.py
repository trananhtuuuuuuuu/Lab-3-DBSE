from db import get_connection

def login(manv, password):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("EXEC SP_LOGIN_NHANVIEN ?, ?", (manv, password))
    user = cursor.fetchone()

    conn.close()
    return user
