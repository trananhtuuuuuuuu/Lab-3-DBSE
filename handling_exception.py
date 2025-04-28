# handling_exception.py
import streamlit as st

def handle_error(e: Exception):
    """Handle and display user-friendly error messages."""
    error_message = str(e).lower()

    if "access denied" in error_message:
        st.warning("Bạn không có quyền truy cập dữ liệu này.")
    elif "closed connection" in error_message:
        st.toast("Kết nối cơ sở dữ liệu bị gián đoạn. Vui lòng tải lại trang.", icon="⚡")
    elif "decryption" in error_message or "decryptbyasymkey" in error_message:
        st.warning("Lỗi giải mã dữ liệu. Vui lòng kiểm tra lại mật khẩu hoặc liên hệ admin.")
    elif "timeout" in error_message:
        st.warning("Kết nối quá hạn. Vui lòng đăng nhập lại.")
    elif "network-related" in error_message or "server not found" in error_message:
        st.error("Không thể kết nối đến máy chủ. Kiểm tra mạng hoặc cấu hình database.")
    else:
        st.error("Đã xảy ra lỗi. Vui lòng thử lại sau hoặc liên hệ hỗ trợ kỹ thuật.")
