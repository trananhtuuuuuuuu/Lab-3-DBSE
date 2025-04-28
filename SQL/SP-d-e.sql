
USE QLSVNhom;
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







-- DROP IF EXISTS + CREATE SP_GET_CLASSES
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


ALTER PROCEDURE SP_UPDATE_GRADE
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

    IF @MALOP IS NULL
    BEGIN
        RAISERROR(N'Sinh viên không tồn tại hoặc chưa có lớp.', 16, 1);
        RETURN;
    END

    -- Kiểm tra quyền nhân viên quản lý lớp
    IF NOT EXISTS (
        SELECT 1
        FROM LOP
        WHERE MALOP = @MALOP AND MANV = @MANV
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền cập nhật điểm sinh viên này.', 16, 1);
        RETURN;
    END

    -- ⚡ Thêm kiểm tra mới: Sinh viên có đăng ký học phần không?
    IF NOT EXISTS (
        SELECT 1
        FROM BANGDIEM
        WHERE MASV = @MASV AND MAHP = @MAHP
    )
    BEGIN
        RAISERROR(N'Sinh viên này chưa đăng ký học phần này.', 16, 1);
        RETURN;
    END

    -- Nếu mọi thứ ok, tiếp tục mã hóa và update điểm
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

    UPDATE BANGDIEM
    SET DIEMTHI = @ENCRYPTED_SCORE
    WHERE MASV = @MASV AND MAHP = @MAHP;
END;
GO







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

