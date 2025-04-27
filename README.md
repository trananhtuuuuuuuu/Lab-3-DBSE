# Lab-3-DBSE


# Student Management System (Python + MSSQL)

## Setup Instructions:

1. Install Python packages:

2. Setup SQL Server:
- Create database `QLSVNhom`
- Create tables: SINHVIEN, NHANVIEN, LOP, HOCPHAN, BANGDIEM
- Create stored procedures (provided)

3. Run Streamlit app:

## Features:

- Employee login (with SHA1 password check)
- Manage Classes
- View Students by Class
- Enter encrypted Grades (RSA Public Key)


# Running follow code below, please

- cd into your my folder which you cloned from link github
- after go on that my folder let follow these command below
- pip install -r requirements.txt
- streamlit run app.py


Cần chỉnh lại hàm insert-DIEMTHI với DIEMthi mã hóa thep public key của cái này:
  DECLARE @MATKHAU VARBINARY(MAX) = HASHBYTES('SHA1', @MK);
  DECLARE @ASYM_KEY_ID INT = AsymKey_ID('AsymKey_NhanVien');
  DECLARE @LUONG_ENC VARBINARY(MAX) = EncryptByAsymKey(@ASYM_KEY_ID, CONVERT(VARBINARY(MAX), @LUONGCB));
  DECLARE @PUBKEY VARCHAR(20) = @MANV;
Giao diện hiển thị sinh viên thì chỉ hiển thị những sinh viên do nhân viên đó quản lý
Nhập điểm thì chỉ được nhập điểm của lớp mà nhân viên đó quản lý (Vì điểm thi mã hóa theo mã nhân viên nhập điểm của lớp đó)
Giải mã điểm thì truyền vào password của nhân viên đó để giải mã 
update thông tin sinh viên thì chỉ cần update điểm thi thôi

chưa fix được giải mã điểm theo password của nhân viên, vì mã hóa theo mã nhân viên
