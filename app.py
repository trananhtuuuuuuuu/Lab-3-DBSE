# app.py
import streamlit as st
from auth import login
from class_manager import get_classes
from student import get_students_by_class
from grade_entry import insert_grade

st.title("Quản lý Sinh viên - Đăng nhập")

if 'logged_in' not in st.session_state:
    st.session_state.logged_in = False

if not st.session_state.logged_in:
    username = st.text_input("Tài khoản (MANV)")
    password = st.text_input("Mật khẩu", type="password")
    if st.button("Đăng nhập"):
        user = login(username, password)
        if user:
            st.session_state.logged_in = True
            st.session_state.user = user
            st.success("Đăng nhập thành công!")
        else:
            st.error("Sai tài khoản hoặc mật khẩu")
else:
    st.sidebar.title("Menu")
    choice = st.sidebar.selectbox("Chọn chức năng", ["Quản lý lớp học", "Quản lý sinh viên", "Nhập bảng điểm"])

    if choice == "Quản lý lớp học":
        classes = get_classes()
        for c in classes:
            st.write(f"Mã lớp: {c[0]}, Tên lớp: {c[1]}, Giáo viên: {c[2]}")

    elif choice == "Quản lý sinh viên":
        malop = st.text_input("Nhập mã lớp để xem sinh viên:")
        if st.button("Xem danh sách"):
            students = get_students_by_class(malop)
            for sv in students:
                st.write(f"Mã SV: {sv[0]}, Họ tên: {sv[1]}, Ngày sinh: {sv[2]}")

    elif choice == "Nhập bảng điểm":
        masv = st.text_input("Mã sinh viên")
        mahp = st.text_input("Mã học phần")
        diemthi = st.number_input("Điểm thi", min_value=0.0, max_value=10.0)
        if st.button("Nhập điểm"):
            pubkey_pem = st.session_state.user[-1].encode()  # Cột PUBKEY lấy từ user session
            insert_grade(masv, mahp, diemthi, pubkey_pem)
            st.success("Nhập điểm thành công!")