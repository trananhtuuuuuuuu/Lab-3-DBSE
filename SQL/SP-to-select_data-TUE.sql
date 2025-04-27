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
