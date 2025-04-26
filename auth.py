from db import get_connection

def login(manv, password):
    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC SP_LOGIN_NHANVIEN ?, ?", (manv, password))
        result = cursor.fetchone()
    except Exception as e:
        conn.close()
        return f"ERROR::{str(e)}"

    conn.close()
    return result
