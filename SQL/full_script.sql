USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'QLSVNhom')
BEGIN
    ALTER DATABASE [QLSVNhom] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [QLSVNhom];
END
GO

-- ============================
-- CREATE NEW DATABASE
-- ============================
CREATE DATABASE QLSVNhom;
GO

USE QLSVNhom;
GO

-- ============================
-- CREATE TABLES
-- ============================

CREATE TABLE SINHVIEN (
    MASV VARCHAR(20) PRIMARY KEY,
    HOTEN NVARCHAR(100) NOT NULL,
    NGAYSINH DATETIME,
    DIACHI NVARCHAR(200),
    MALOP NVARCHAR(200),
    TENDN NVARCHAR(100) NOT NULL UNIQUE,
    MATKHAU VARBINARY(MAX) NOT NULL
);

CREATE TABLE NHANVIEN (
    MANV VARCHAR(20) PRIMARY KEY,
    HOTEN NVARCHAR(100) NOT NULL,
    EMAIL VARCHAR(20),
    LUONG VARBINARY(MAX),
    TENDN NVARCHAR(100) NOT NULL UNIQUE,
    MATKHAU VARBINARY(MAX) NOT NULL,
    PUBKEY VARCHAR(20)
);

CREATE TABLE HOCPHAN (
    MAHP VARCHAR(20) PRIMARY KEY,
    TENHP NVARCHAR(100) NOT NULL,
    SOTC INT
);

CREATE TABLE LOP (
    MALOP VARCHAR(20) PRIMARY KEY,
    TENLOP NVARCHAR(100) NOT NULL,
    MANV VARCHAR(20),
    FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
);

CREATE TABLE BANGDIEM (
    MASV VARCHAR(20),
    MAHP VARCHAR(20),
    DIEMTHI VARBINARY(MAX),
    PRIMARY KEY (MASV, MAHP),
    FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    FOREIGN KEY (MAHP) REFERENCES HOCPHAN(MAHP)
);

-- ============================
-- CREATE SAMPLE DATA
-- ============================


-- Insert Courses
INSERT INTO HOCPHAN (MAHP, TENHP, SOTC) VALUES 
('HP01', N'Database Systems', 3),
('HP02', N'Computer Networks', 3),
('HP03', N'Maching Learning', 3),
('HP04', N'Deep Learning', 3),
('HP05', N'Introduction AI', 3),
('HP06', N'How to become Data Engineering', 3),
('HP07', N'Introduction Software Engineer', 3);

-- Insert Classes
INSERT INTO LOP (MALOP, TENLOP, MANV) VALUES 
('L01', N'Class Data Science', 'NV01'),
('L02', N'Class Artificial Intelligence', 'NV02'),
('L03', N'Intro ML', 'NV03'),
('L04', N'Intro DL', 'NV04'),
('L05', N'Intro AI', 'NV02'),
('L06', N'Intro DE', 'NV01'),
('L07', N'Intro SE', 'NV05');

-- Insert Students
INSERT INTO SINHVIEN (MASV, HOTEN, NGAYSINH, DIACHI, MALOP, TENDN, MATKHAU) VALUES
('SV01', N'Pham Thi A', '2002-01-01', N'HCMC', 'L01', 'pta', HASHBYTES('SHA1', '123456')),
('SV02', N'Le Van B', '2002-02-02', N'Hanoi', 'L01', 'lvb', HASHBYTES('SHA1', '123456')),
('SV03', N'Nguyen Van C', '2001-03-03', N'Da Nang', 'L02', 'nvc', HASHBYTES('SHA1', '123456')),
('SV04', N'Tran Thi D', '2001-04-04', N'Can Tho', 'L02', 'ttd', HASHBYTES('SHA1', '123456')),
('SV05', N'Peter Cua Em', '2001-04-04', N'TP.HCM', 'L03', 'pce', HASHBYTES('SHA1', '123456')),
('SV06', N'Anh Jack Cua Em', '2001-04-04', N'TP.HCM', 'L04', 'ajce', HASHBYTES('SHA1', '123456')),
('SV07', N'Hotboy Ben Tre', '2001-04-04', N'Ben Tre', 'L05', 'hbt', HASHBYTES('SHA1', '123456')),
('SV08', N'Trinh Tran Phuong Tuan', '2001-04-04', N'Ben Tre', 'L06', 'ttpt', HASHBYTES('SHA1', '123456')),
('SV09', N'Vi Tinh Tu', '2001-04-04', N'Ben Tre', 'L07', 'vtt', HASHBYTES('SHA1', '123456')),
('SV010', N'Mai Yeu Peter', '2001-04-04', N'TP.HCM', 'L01', 'myp', HASHBYTES('SHA1', '123456'));


-- ============================
-- CREATE STORED PROCEDURES
-- ============================


IF OBJECT_ID('SP_LOGIN_NHANVIEN', 'P') IS NOT NULL
    DROP PROCEDURE SP_LOGIN_NHANVIEN;
GO

CREATE PROCEDURE SP_LOGIN_NHANVIEN
    @MANV NVARCHAR(20),
    @MK VARBINARY(20) -- Nhận mật khẩu đã mã hóa SHA1 từ client
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MANV, HOTEN, EMAIL, TENDN, PUBKEY
    FROM NHANVIEN
    WHERE MANV = @MANV AND MATKHAU = @MK;
END;
GO



CREATE PROCEDURE SP_INS_PUBLIC_ENCRYPT_NHANVIEN
    @MANV VARCHAR(10),
    @HOTEN NVARCHAR(100),
    @EMAIL VARCHAR(100),
    @LUONG VARBINARY(MAX), 
    @TENDN VARCHAR(50),
    @MK VARBINARY(MAX),    
    @PUB VARCHAR(2048)      
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
    VALUES (@MANV, @HOTEN, @EMAIL, @LUONG, @TENDN, @MK, @PUB);
END



IF OBJECT_ID('SP_SEL_PUBLIC_ENCRYPT_NHANVIEN', 'P') IS NOT NULL
    DROP PROCEDURE SP_SEL_PUBLIC_ENCRYPT_NHANVIEN;
GO

CREATE PROCEDURE SP_SEL_PUBLIC_ENCRYPT_NHANVIEN
    @TENDN NVARCHAR(20),
    @MK VARBINARY(20) -- Mật khẩu đã mã hóa SHA1 từ client
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MANV, HOTEN, EMAIL, LUONG, PUBKEY
    FROM NHANVIEN
    WHERE TENDN = @TENDN AND MATKHAU = @MK;
END;
GO



IF OBJECT_ID('SP_GET_CLASSES', 'P') IS NOT NULL
    DROP PROCEDURE SP_GET_CLASSES;
GO

CREATE PROCEDURE SP_GET_CLASSES
    @MANV NVARCHAR(20) -- Lọc lớp theo nhân viên đăng nhập
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MALOP, TENLOP, MANV 
    FROM LOP 
    WHERE MANV = @MANV;
END;
GO


-- DROP IF EXISTS + CREATE SP_GET_STUDENTS_BY_CLASS
IF OBJECT_ID('SP_GET_STUDENTS_BY_CLASS', 'P') IS NOT NULL
    DROP PROCEDURE SP_GET_STUDENTS_BY_CLASS;
GO

CREATE PROCEDURE SP_GET_STUDENTS_BY_CLASS
    @MALOP NVARCHAR(20),
    @MANV NVARCHAR(20)  -- ✅ Logged-in employee ID
AS
BEGIN
    SET NOCOUNT ON;

    -- Only return students if this teacher manages the class
    IF EXISTS (
        SELECT 1 FROM LOP WHERE MALOP = @MALOP AND MANV = @MANV
    )
    BEGIN
        SELECT MASV, HOTEN, NGAYSINH, DIACHI, MALOP
        FROM SINHVIEN
        WHERE MALOP = @MALOP;
    END
    ELSE
    BEGIN
        RAISERROR('Access denied: you do not manage this class.', 16, 1);
    END
END;
GO




IF OBJECT_ID('SP_INSERT_GRADE', 'P') IS NOT NULL
    DROP PROCEDURE SP_INSERT_GRADE;
GO

CREATE PROCEDURE SP_INSERT_GRADE
    @MASV NVARCHAR(20),
    @MAHP NVARCHAR(20),
    @ENCRYPTED_SCORE VARBINARY(MAX), -- Nhận điểm đã mã hóa RSA từ client
    @MANV NVARCHAR(20) -- Nhân viên đăng nhập
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MALOP NVARCHAR(20);

    -- Lấy lớp của sinh viên
    SELECT @MALOP = MALOP
    FROM SINHVIEN
    WHERE MASV = @MASV;

    IF @MALOP IS NULL
    BEGIN
        RAISERROR(N'Sinh viên không tồn tại hoặc chưa có lớp.', 16, 1);
        RETURN;
    END

    -- Kiểm tra nhân viên có quản lý lớp không
    IF NOT EXISTS (
        SELECT 1
        FROM LOP
        WHERE MALOP = @MALOP AND MANV = @MANV
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền nhập điểm cho sinh viên này.', 16, 1);
        RETURN;
    END

    -- Kiểm tra sinh viên có đăng ký học phần không
    IF NOT EXISTS (
        SELECT 1
        FROM BANGDIEM
        WHERE MASV = @MASV AND MAHP = @MAHP
    )
    BEGIN
        -- Thêm mới nếu chưa có
        INSERT INTO BANGDIEM (MASV, MAHP, DIEMTHI)
        VALUES (@MASV, @MAHP, @ENCRYPTED_SCORE);
    END
    ELSE
    BEGIN
        -- Cập nhật nếu đã có
        UPDATE BANGDIEM
        SET DIEMTHI = @ENCRYPTED_SCORE
        WHERE MASV = @MASV AND MAHP = @MAHP;
    END

    PRINT N'Đã nhập điểm thành công.';
END;
GO


IF OBJECT_ID('SP_UPDATE_GRADE', 'P') IS NOT NULL
    DROP PROCEDURE SP_UPDATE_GRADE;
GO

CREATE PROCEDURE SP_UPDATE_GRADE
    @MASV NVARCHAR(20),
    @MAHP NVARCHAR(20),
    @ENCRYPTED_SCORE VARBINARY(MAX), -- Nhận điểm đã mã hóa RSA từ client
    @MANV NVARCHAR(20) -- Nhân viên đăng nhập
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MALOP NVARCHAR(20);

    -- Lấy lớp của sinh viên
    SELECT @MALOP = MALOP FROM SINHVIEN WHERE MASV = @MASV;

    IF @MALOP IS NULL
    BEGIN
        RAISERROR(N'Sinh viên không tồn tại hoặc chưa có lớp.', 16, 1);
        RETURN;
    END

    -- Kiểm tra nhân viên có quản lý lớp không
    IF NOT EXISTS (
        SELECT 1
        FROM LOP
        WHERE MALOP = @MALOP AND MANV = @MANV
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền cập nhật điểm sinh viên này.', 16, 1);
        RETURN;
    END

    -- Kiểm tra sinh viên có đăng ký học phần không
    IF NOT EXISTS (
        SELECT 1
        FROM BANGDIEM
        WHERE MASV = @MASV AND MAHP = @MAHP
    )
    BEGIN
        RAISERROR(N'Sinh viên này chưa đăng ký học phần này.', 16, 1);
        RETURN;
    END

    -- Cập nhật điểm đã mã hóa
    UPDATE BANGDIEM
    SET DIEMTHI = @ENCRYPTED_SCORE
    WHERE MASV = @MASV AND MAHP = @MAHP;

    PRINT N'Đã cập nhật điểm thành công.';
END;
GO



IF OBJECT_ID('SP_VIEW_SCORES_BY_TEACHER_V2', 'P') IS NOT NULL
    DROP PROCEDURE SP_VIEW_SCORES_BY_TEACHER_V2;
GO

CREATE PROCEDURE SP_VIEW_SCORES_BY_TEACHER_V2
    @MANV NVARCHAR(20) -- Nhân viên đăng nhập
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        BD.MASV,
        SV.HOTEN AS TenSinhVien,
        BD.MAHP,
        HP.TENHP AS TenHocPhan,
        BD.DIEMTHI AS ENCRYPTED_SCORE -- Trả về điểm đã mã hóa
    FROM 
        BANGDIEM BD
    INNER JOIN
        SINHVIEN SV ON SV.MASV = BD.MASV
    INNER JOIN
        HOCPHAN HP ON HP.MAHP = BD.MAHP
    INNER JOIN
        LOP L ON SV.MALOP = L.MALOP
    WHERE 
        L.MANV = @MANV; -- Chỉ trả về điểm của sinh viên trong lớp do nhân viên quản lý
END;
GO