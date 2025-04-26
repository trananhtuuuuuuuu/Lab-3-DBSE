-- Drop if exists
IF OBJECT_ID('SP_SEL_PUBLIC_GRADE', 'P') IS NOT NULL
    DROP PROCEDURE SP_SEL_PUBLIC_GRADE;
GO

-- Create procedure
CREATE PROCEDURE SP_SEL_PUBLIC_GRADE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PASSWORD NVARCHAR(100) = '22120429'; -- Password khi tạo MASTER KEY / ASYMMETRIC KEY

    SELECT 
        MASV,
        MAHP,
        CASE
            WHEN DecryptByAsymKey(AsymKey_ID('AsymKey_NhanVien'), DIEMTHI, @PASSWORD) IS NOT NULL
            THEN CONVERT(FLOAT, CONVERT(VARCHAR(50), DecryptByAsymKey(
                AsymKey_ID('AsymKey_NhanVien'),
                DIEMTHI,
                @PASSWORD
            )))
            ELSE NULL
        END AS DIEMTHI_GIAIMA
    FROM BANGDIEM;
END;
GO




EXEC SP_SEL_PUBLIC_GRADE;