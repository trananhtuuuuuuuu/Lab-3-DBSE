from db import get_connection

def login(manv, hashed_password_bytes):
    """
    Nhận mã nhân viên và mật khẩu đã băm bằng SHA1 (dạng bytes),
    gọi stored procedure SP_LOGIN_NHANVIEN để kiểm tra.
    """
    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC SP_LOGIN_NHANVIEN ?, ?", (manv, hashed_password_bytes))
        result = cursor.fetchone()
    except Exception as e:
        conn.close()
        return f"ERROR::{str(e)}"

    conn.close()
    return result

