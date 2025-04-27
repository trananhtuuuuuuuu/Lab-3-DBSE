import streamlit as st
from auth import login
from class_manager import get_classes
from student import get_students_by_class
from grade_entry import insert_grade
from db import get_connection

st.set_page_config(page_title="Database Security", layout="centered")

st.title("LOGIN")

# Initialize session variables
if 'logged_in' not in st.session_state:
    st.session_state.logged_in = False
    st.session_state.user = None
if 'just_logged_in' not in st.session_state:
    st.session_state.just_logged_in = False
if 'logout_flag' not in st.session_state:
    st.session_state.logout_flag = False

# 💡 Only show login if not logged in!
if not st.session_state.logged_in:
    with st.form(key="login_form"):
        username = st.text_input("MANV")
        password = st.text_input("Password", type="password")
        submit_button = st.form_submit_button("Login")

    if submit_button:
        result = login(username, password)

        if isinstance(result, str) and result.startswith("ERROR::"):
            st.error("❌ " + result.replace("ERROR::", ""))
        elif result:
            st.session_state.logged_in = True
            st.session_state.user = result
            st.session_state.just_logged_in = True
        else:
            st.error("❌ Invalid ID or password!")

# 🎯 After login, show main app
if st.session_state.logged_in:
    if st.session_state.just_logged_in:
        st.success("✅ Login successful!")
        st.session_state.just_logged_in = False

    st.sidebar.title("📚 Menu")

    # Add Logout button
    if st.sidebar.button("🚪 Logout"):
        st.session_state.logged_in = False
        st.session_state.user = None
        st.session_state.just_logged_in = False
       

    choice = st.sidebar.selectbox("Choose function", ["Manage Classes", "Manage Students", "Enter Grades"])

    if choice == "Manage Classes":
        st.header("📚 Class List")
        classes = get_classes()
        for c in classes:
            st.write(f"Class ID: {c[0]}, Class Name: {c[1]}, Teacher: {c[2]}")

    elif choice == "Manage Students":
        st.header("👨‍🏫 Student List")

        malop = st.text_input("Enter Class ID:", key="malop_input")

        if st.button("View Students", key="view_students_button"):
            st.session_state.current_class = malop  # ✅ Save class id
            st.session_state.show_students = True

        if st.session_state.get('show_students', False):
            current_manv = st.session_state.user[0]
            malop = st.session_state.get('current_class', None)

            try:
                students = get_students_by_class(malop, current_manv)

                if students:
                    for sv in students:
                        student_id = sv[0]
                        st.write(f"Student ID: {student_id}")

                        # 👉 Thêm phần: Hiển thị điểm thi
                        try:
                            conn = get_connection()
                            cursor = conn.cursor()
                            # Gọi SP giải mã điểm, truyền password (ví dụ lấy từ session luôn nếu lưu lúc login)
                            password = '22120429'  # hoặc lấy st.session_state.user_password nếu đã lưu
                            cursor.execute("EXEC SP_SEL_PUBLIC_GRADE ?", (password,))
                            grades = cursor.fetchall()

                            # Tìm điểm thi theo student_id
                            student_grades = [g for g in grades if g[0] == student_id]

                            if student_grades:
                                for g in student_grades:
                                    st.write(f"➔ Course: {g[1]}, Score: {g[2]}")
                            else:
                                st.write("➔ No scores yet.")

                            conn.close()
                        except Exception as e:
                            st.warning(f"⚠️ Cannot fetch grades: {str(e)}")

                        # 👉 Phần nhập để update điểm mới
                        course_id = st.text_input(f"Enter Course ID for {student_id}", key=f"course_{student_id}")
                        score = st.number_input(f"Enter New Score for {student_id}", min_value=0.0, max_value=10.0, key=f"score_{student_id}")

                        if st.button(f"Update Grade for {student_id}", key=f"update_grade_{student_id}"):
                            if course_id and score is not None:
                                conn = get_connection()
                                cursor = conn.cursor()
                                cursor.execute(
                                    "EXEC SP_UPDATE_GRADE ?, ?, ?, ?",
                                    (student_id, course_id, score, current_manv)
                                )
                                conn.commit()
                                conn.close()
                                st.success(f"✅ Updated grade for {student_id}")
                            else:
                                st.warning("❗ Please enter Course ID and Score before updating.")

                else:
                    st.warning("❗ No students found or you don't have permission to view this class.")

            except Exception as e:
                error_message = str(e)
                if "Access denied" in error_message:
                    st.warning("❗ You don't have permission to access this class.")
                else:
                    st.error(f"❌ Error: {error_message}")




    elif choice == "Enter Grades":
      st.header("📝 Enter Grades")

      masv = st.text_input("Student ID", key="student_id_input")
      mahp = st.text_input("Course ID", key="course_id_input")
      diemthi = st.number_input("Score", min_value=0.0, max_value=10.0)

      if st.button("Submit Grade", key="submit_grade_button"):
          try:
              manv = st.session_state.user[0]  # lấy MANV, ví dụ 'NV01'
              insert_grade(masv, mahp, diemthi, manv)
              st.success("✅ Grade encrypted and inserted successfully!")
          except Exception as e:
              st.error(f"❌ Error inserting grade: {str(e)}")
