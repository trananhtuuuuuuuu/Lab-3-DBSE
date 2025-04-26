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

                      if f"name_{student_id}" not in st.session_state:
                          st.session_state[f"name_{student_id}"] = sv[1]
                      if f"address_{student_id}" not in st.session_state:
                          st.session_state[f"address_{student_id}"] = sv[3]

                      st.write(f"Student ID: {student_id}")

                      new_name = st.text_input(f"Edit Name for {student_id}", key=f"name_{student_id}")
                      new_address = st.text_input(f"Edit Address for {student_id}", key=f"address_{student_id}")

                      if st.button(f"Update {student_id}", key=f"update_{student_id}"):
                        conn = get_connection()
                        cursor = conn.cursor()
                        cursor.execute(
                            "EXEC SP_UPDATE_STUDENT_INFO ?, ?, ?",
                            (student_id, new_name, new_address)
                        )
                        conn.commit()
                        conn.close()
                        st.success(f"✅ Updated info for {student_id}")


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
