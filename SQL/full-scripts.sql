

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
-- CREATE ENCRYPTION MATERIAL
-- ============================

-- Create MASTER KEY
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '22120429';
END;
GO

-- Create CERTIFICATE
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'MYCERTIFICATE')
BEGIN
    CREATE CERTIFICATE MYCERTIFICATE
    WITH SUBJECT = 'Certificate use for create asymmetric key';
END;
GO

-- Create ASYMMETRIC KEY
IF NOT EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = 'AsymKey_NhanVien')
BEGIN
    CREATE ASYMMETRIC KEY AsymKey_NhanVien
    WITH ALGORITHM = RSA_2048
    ENCRYPTION BY PASSWORD = '22120429';
END;
GO

-- ============================
-- CREATE ENCRYPTION MATERIAL
-- ============================

-- Create MASTER KEY
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '22120429';
END;
GO

-- Create CERTIFICATE
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'MYCERTIFICATE')
BEGIN
    CREATE CERTIFICATE MYCERTIFICATE
    WITH SUBJECT = 'Certificate use for create asymmetric key';
END;
GO

-- Create ASYMMETRIC KEY
IF NOT EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = 'AsymKey_NhanVien')
BEGIN
    CREATE ASYMMETRIC KEY AsymKey_NhanVien
    WITH ALGORITHM = RSA_2048
    ENCRYPTION BY PASSWORD = '22120429';
END;
GO

-- ============================
-- CREATE STORED PROCEDURES
-- ============================

-- Drop procedure if exists
IF OBJECT_ID('SP_CREATE_ASYMMETRIC_KEY', 'P') IS NOT NULL
    DROP PROCEDURE SP_CREATE_ASYMMETRIC_KEY;
GO

-- SP tạo asymmetric key 

CREATE PROCEDURE SP_CREATE_ASYMMETRIC_KEY 

    @KeyName NVARCHAR(100),    

    @Password NVARCHAR(100) 

AS 

BEGIN 

    IF NOT EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = @KeyName) 

BEGIN 

DECLARE @SQL NVARCHAR(MAX); 

SET @SQL = 'CREATE ASYMMETRIC KEY '  + CAST(@KeyName AS VARCHAR) + ' WITH ALGORITHM = RSA_2048 ' + 'ENCRYPTION BY PASSWORD = '''+@Password+''''; 

EXEC sp_executesql @SQL; 

PRINT N'Asymmetric Key đã được tạo: ' + @KeyName; 

END 

    ELSE 

        PRINT N'Asymmetric Key đã tồn tại: ' + @KeyName; 

END 

GO 





-- SP_INS_PUBLIC_NHANVIEN
-- Drop old procedure if exists
IF OBJECT_ID('SP_INS_PUBLIC_NHANVIEN', 'P') IS NOT NULL
    DROP PROCEDURE SP_INS_PUBLIC_NHANVIEN;
GO

-- Create new SP_INS_PUBLIC_NHANVIEN
CREATE PROCEDURE SP_INS_PUBLIC_NHANVIEN
    @MANV NVARCHAR(20),
    @HOTEN NVARCHAR(100),
    @EMAIL NVARCHAR(20),
    @LUONGCB VARCHAR(100),
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MK_HASHED VARBINARY(MAX);
    DECLARE @LUONG_ENCRYPTED VARBINARY(MAX);
    DECLARE @PublicKey NVARCHAR(20);

    -- Hash mật khẩu bằng SHA1
    SET @MK_HASHED = HASHBYTES('SHA1', CONVERT(NVARCHAR(100), @MK));

    -- Gán PUBKEY
    SET @PublicKey = @MANV;

    -- Tạo asymmetric key ứng với nhân viên
    EXEC SP_CREATE_ASYMMETRIC_KEY @PublicKey, @MK;

    -- Mã hóa lương sử dụng AsymKey của nhân viên
    SET @LUONG_ENCRYPTED = EncryptByAsymKey(AsymKey_ID(@PublicKey), CONVERT(VARBINARY(MAX), @LUONGCB));

    -- Thêm nhân viên vào bảng nếu chưa tồn tại
    IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV)
    BEGIN
        INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
        VALUES (@MANV, @HOTEN, @EMAIL, @LUONG_ENCRYPTED, @TENDN, @MK_HASHED, @PublicKey);

        PRINT N'Nhân viên đã được thêm vào bảng NHANVIEN: ' + @MANV;
    END
    ELSE
    BEGIN
        PRINT N'Nhân viên với mã ' + @MANV + N' đã tồn tại.';
    END
END;
GO









-- SP_SEL_PUBLIC_NHANVIEN
CREATE PROCEDURE SP_SEL_PUBLIC_NHANVIEN
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MANV,
        HOTEN,
        EMAIL,
        CONVERT(VARCHAR(100),
            DecryptByAsymKey(
                AsymKey_ID('AsymKey_NhanVien'),
                LUONG,
                @MK
            )
        ) AS LUONGCB
    FROM NHANVIEN
    WHERE TENDN = @TENDN
      AND DecryptByAsymKey(
            AsymKey_ID('AsymKey_NhanVien'),
            LUONG,
            @MK
          ) IS NOT NULL;
END;
GO






IF OBJECT_ID('SP_LOGIN_NHANVIEN', 'P') IS NOT NULL
    DROP PROCEDURE SP_LOGIN_NHANVIEN;
GO

CREATE PROCEDURE SP_LOGIN_NHANVIEN
    @MANV NVARCHAR(20),
    @MK NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HashedPassword VARBINARY(20)
    SET @HashedPassword = HASHBYTES('SHA1', @MK);

    SELECT MANV, HOTEN, EMAIL, TENDN, PUBKEY
    FROM NHANVIEN
    WHERE MANV = @MANV AND MATKHAU = @HashedPassword;
END;
GO







-- SP_GET_CLASSES
IF OBJECT_ID('SP_GET_CLASSES', 'P') IS NOT NULL
    DROP PROCEDURE SP_GET_CLASSES;
GO

CREATE PROCEDURE SP_GET_CLASSES
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MALOP, TENLOP, MANV FROM LOP;
END;
GO






IF OBJECT_ID('SP_GET_STUDENTS_BY_CLASS', 'P') IS NOT NULL
    DROP PROCEDURE SP_GET_STUDENTS_BY_CLASS;
GO

CREATE PROCEDURE SP_GET_STUDENTS_BY_CLASS
    @MALOP NVARCHAR(20),
    @MANV NVARCHAR(20)  
AS
BEGIN
    SET NOCOUNT ON;

    
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






-- Drop old procedure if exists
IF OBJECT_ID('SP_INSERT_GRADE', 'P') IS NOT NULL
    DROP PROCEDURE SP_INSERT_GRADE;
GO

-- Create correct procedure
CREATE PROCEDURE SP_INSERT_GRADE
    @MASV NVARCHAR(20),
    @MAHP NVARCHAR(20),
    @DIEMTHI FLOAT,
    @MANV NVARCHAR(20) -- Nhân viên đang đăng nhập
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PublicKey NVARCHAR(20);
    DECLARE @MALOP NVARCHAR(20);
    SET @PublicKey = @MANV;

    -- Lấy lớp của sinh viên
    SELECT @MALOP = MALOP
    FROM SINHVIEN
    WHERE MASV = @MASV;

    -- Nếu sinh viên không tồn tại hoặc chưa có lớp
    IF @MALOP IS NULL
    BEGIN
        RAISERROR(N'Sinh viên không tồn tại hoặc chưa có lớp.', 16, 1);
        RETURN;
    END

    -- Kiểm tra xem nhân viên có quản lý lớp này không
    IF NOT EXISTS (
        SELECT 1
        FROM LOP
        WHERE MALOP = @MALOP AND MANV = @MANV
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền nhập điểm cho sinh viên này.', 16, 1);
        RETURN;
    END

    -- Lấy Asymmetric Key ID cho nhân viên
    DECLARE @ASYM_KEY_ID INT;
    SET @ASYM_KEY_ID = AsymKey_ID(@PublicKey);

    IF @ASYM_KEY_ID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy khóa bất đối xứng của nhân viên.', 16, 1);
        RETURN;
    END

    -- Convert điểm thi sang NVARCHAR để mã hóa
    DECLARE @DIEMTHI_TEXT NVARCHAR(50);
    SET @DIEMTHI_TEXT = CAST(@DIEMTHI AS NVARCHAR(50));

    -- Mã hóa điểm thi
    DECLARE @ENCRYPTED_SCORE VARBINARY(MAX);
    SET @ENCRYPTED_SCORE = EncryptByAsymKey(@ASYM_KEY_ID, @DIEMTHI_TEXT);

    -- Insert chỉ MASV, MAHP, DIEMTHI vào bảng BANGDIEM
    INSERT INTO BANGDIEM (MASV, MAHP, DIEMTHI)
    VALUES (@MASV, @MAHP, @ENCRYPTED_SCORE);

    PRINT N'Đã nhập điểm thành công.';
END;
GO





-- Drop if exists
IF OBJECT_ID('SP_UPDATE_GRADE', 'P') IS NOT NULL
    DROP PROCEDURE SP_UPDATE_GRADE;
GO

-- Create procedure
CREATE PROCEDURE SP_UPDATE_GRADE
    @MASV NVARCHAR(20),
    @MAHP NVARCHAR(20),
    @DIEMTHI FLOAT,
    @MANV NVARCHAR(20)  -- Người đang login
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MALOP NVARCHAR(20);

    -- Lấy lớp của sinh viên
    SELECT @MALOP = MALOP FROM SINHVIEN WHERE MASV = @MASV;

    -- Nếu sinh viên không có lớp hoặc không tồn tại
    IF @MALOP IS NULL
    BEGIN
        RAISERROR(N'Sinh viên không tồn tại hoặc chưa có lớp.', 16, 1);
        RETURN;
    END

    -- Kiểm tra nhân viên có quản lý lớp này không
    IF NOT EXISTS (
        SELECT 1
        FROM LOP
        WHERE MALOP = @MALOP AND MANV = @MANV
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền cập nhật điểm sinh viên này.', 16, 1);
        RETURN;
    END

    -- Tiếp tục: Mã hóa điểm thi
    DECLARE @PublicKey NVARCHAR(20) = @MANV;
    DECLARE @ASYM_KEY_ID INT;
    SET @ASYM_KEY_ID = AsymKey_ID(@PublicKey);

    IF @ASYM_KEY_ID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy Asymmetric Key của nhân viên.', 16, 1);
        RETURN;
    END

    DECLARE @DIEMTHI_TEXT NVARCHAR(50);
    SET @DIEMTHI_TEXT = CAST(@DIEMTHI AS NVARCHAR(50));

    DECLARE @ENCRYPTED_SCORE VARBINARY(MAX);
    SET @ENCRYPTED_SCORE = EncryptByAsymKey(@ASYM_KEY_ID, @DIEMTHI_TEXT);

    -- Update vào BANGDIEM
    UPDATE BANGDIEM
    SET DIEMTHI = @ENCRYPTED_SCORE
    WHERE MASV = @MASV AND MAHP = @MAHP;
END;
GO



-- -- Drop if exists
-- IF OBJECT_ID('SP_SEL_PUBLIC_GRADE', 'P') IS NOT NULL
--     DROP PROCEDURE SP_SEL_PUBLIC_GRADE;
-- GO

-- -- Create procedure
-- CREATE PROCEDURE SP_SEL_PUBLIC_GRADE
-- AS
-- BEGIN
--     SET NOCOUNT ON;

--     DECLARE @PASSWORD NVARCHAR(100) = '22120429'; -- Password khi tạo MASTER KEY / ASYMMETRIC KEY

--     SELECT 
--         MASV,
--         MAHP,
--         CASE
--             WHEN DecryptByAsymKey(AsymKey_ID('AsymKey_NhanVien'), DIEMTHI, @PASSWORD) IS NOT NULL
--             THEN CONVERT(FLOAT, CONVERT(VARCHAR(50), DecryptByAsymKey(
--                 AsymKey_ID('AsymKey_NhanVien'),
--                 DIEMTHI,
--                 @PASSWORD
--             )))
--             ELSE NULL
--         END AS DIEMTHI_GIAIMA
--     FROM BANGDIEM;
-- END;
-- GO



-- Drop old procedure if exists
IF OBJECT_ID('SP_VIEW_SCORES_BY_TEACHER_V2', 'P') IS NOT NULL
    DROP PROCEDURE SP_VIEW_SCORES_BY_TEACHER_V2;
GO

-- Create new procedure
CREATE PROCEDURE SP_VIEW_SCORES_BY_TEACHER_V2
    @MANV NVARCHAR(20),        -- Mã nhân viên
    @Password NVARCHAR(100)    -- Password của Asymmetric Key
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        BD.MASV,
        SV.HOTEN AS TenSinhVien,
        BD.MAHP,
        HP.TENHP AS TenHocPhan,
        CASE
            WHEN BD.DIEMTHI IS NOT NULL
                 AND DecryptByAsymKey(AsymKey_ID(@MANV), BD.DIEMTHI, @Password) IS NOT NULL
            THEN CONVERT(FLOAT, CONVERT(NVARCHAR(50), DecryptByAsymKey(
                AsymKey_ID(@MANV),
                BD.DIEMTHI,
                @Password
            )))
            ELSE NULL
        END AS DIEMTHI_GIAIMA
    FROM 
        BANGDIEM BD
    INNER JOIN
        SINHVIEN SV ON SV.MASV = BD.MASV
    INNER JOIN
        HOCPHAN HP ON HP.MAHP = BD.MAHP
    INNER JOIN
        LOP L ON SV.MALOP = L.MALOP
    WHERE 
        L.MANV = @MANV; -- Chỉ cho xem điểm sinh viên do mình quản lý
END;
GO


-- ============================
-- INSERT SAMPLE DATA
-- ============================

-- Insert Employees using SP_INS_PUBLIC_NHANVIEN
EXEC SP_INS_PUBLIC_NHANVIEN 
    'NV01', N'Nguyen Van A', 'nva@fit.hcmus.edu.vn', '5000000', 'nva', 'abc123';

EXEC SP_INS_PUBLIC_NHANVIEN 
    'NV02', N'Tran Van B', 'tvb@fit.hcmus.edu.vn', '6000000', 'tvb', 'xyz789';

EXEC SP_INS_PUBLIC_NHANVIEN 
    'NV03', N'Pham Thoai', 'pt@fit.hcmus.edu.vn', '6000000', 'ptt', 'abc123';

EXEC SP_INS_PUBLIC_NHANVIEN 
    'NV04', N'Oh My Got', 'omg@fit.hcmus.edu.vn', '6000000', 'omg', 'abc123';

EXEC SP_INS_PUBLIC_NHANVIEN 
    'NV05', N'Khong Quan Trong', 'kqt@fit.hcmus.edu.vn', '6000000', 'kqt', 'abc123';

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