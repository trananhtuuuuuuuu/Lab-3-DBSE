import streamlit as st
from auth import login
from class_manager import get_classes
from student import get_students_by_class
from grade_entry import insert_grade

st.set_page_config(page_title="Student Management System", layout="centered")

st.title("🔐 Employee Login")

if 'logged_in' not in st.session_state:
    st.session_state.logged_in = False
    st.session_state.user = None

# 💡 Only show login if not logged in!
if not st.session_state.logged_in:
    with st.form(key="login_form"):
        username = st.text_input("Employee ID (MANV)")
        password = st.text_input("Password", type="password")
        submit_button = st.form_submit_button("Login")

    if submit_button:
        result = login(username, password)
        if result:
            result_code = result[0]
            if result_code == 1:
                st.session_state.logged_in = True
                st.session_state.user = result[1:]  # Skip ResultCode
                st.success("✅ Login successful!")
                st.experimental_rerun()  # 🚨 Force rerun app to load new page
            elif result_code == -1:
                st.error("❌ Employee ID not found!")
            elif result_code == 0:
                st.error("❌ Incorrect password!")
        else:
            st.error("❌ Unknown login error!")

# 🎯 After login, show main app
if st.session_state.logged_in:
    st.sidebar.title("📚 Menu")
    choice = st.sidebar.selectbox("Choose function", ["Manage Classes", "Manage Students", "Enter Grades"])

    if choice == "Manage Classes":
        st.header("📚 Class List")
        classes = get_classes()
        for c in classes:
            st.write(f"Class ID: {c[0]}, Class Name: {c[1]}, Teacher: {c[2]}")

    elif choice == "Manage Students":
        st.header("👨‍🎓 Student List")
        malop = st.text_input("Enter Class ID:")
        if st.button("View Students"):
            students = get_students_by_class(malop)
            for sv in students:
                st.write(f"Student ID: {sv[0]}, Name: {sv[1]}, Birthdate: {sv[2]}, Address: {sv[3]}")

    elif choice == "Enter Grades":
        st.header("📝 Enter Grades")
        masv = st.text_input("Student ID")
        mahp = st.text_input("Course ID")
        diemthi = st.number_input("Score", min_value=0.0, max_value=10.0)
        if st.button("Submit Grade"):
            pubkey_pem = st.session_state.user[-1].encode()  # PUBKEY from login
            insert_grade(masv, mahp, diemthi, pubkey_pem)
            st.success("✅ Grade entered successfully!")
