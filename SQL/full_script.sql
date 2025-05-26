USE QLSVNhom;
GO

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