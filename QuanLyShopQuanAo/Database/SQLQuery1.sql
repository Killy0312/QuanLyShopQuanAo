USE master;
GO

-- Reset: Xoa database cu neu da ton tai de chay lai script tu dau
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'QuanLyCuaHangQuanAo')
BEGIN
    ALTER DATABASE QuanLyCuaHangQuanAo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyCuaHangQuanAo;
    PRINT '>> Da xoa database cu.';
END
GO

-- Tao moi database
CREATE DATABASE QuanLyCuaHangQuanAo;
GO
PRINT '>> Da tao database QuanLyCuaHangQuanAo.';
GO

USE QuanLyCuaHangQuanAo;
GO
-- PHAN 1: TAO CAC BANG (Tables)
-- Thu tu: Bang cha truoc, bang con sau (tranh loi FK)
-- NhanVien -> TaiKhoan
-- LoaiSanPham -> SanPham
-- NhanVien + SanPham -> HoaDon -> ChiTietHoaDon

-- 1. Bang NhanVien
CREATE TABLE NhanVien (
    MaNV        INT             IDENTITY(1,1)   NOT NULL,
    TenNV       NVARCHAR(100)   NOT NULL,
    GioiTinh    NVARCHAR(10)    NULL
                                CONSTRAINT CHK_NhanVien_GioiTinh
                                CHECK (GioiTinh IN (N'Nam', N'Nu', N'Khac')),
    NgaySinh    DATE            NULL,
    SDT         VARCHAR(15)     NULL,
    DiaChi      NVARCHAR(200)   NULL,
    NgayVaoLam  DATE            NOT NULL
                                CONSTRAINT DF_NhanVien_NgayVaoLam DEFAULT GETDATE(),

    CONSTRAINT PK_NhanVien PRIMARY KEY (MaNV)
);
GO

-- 2. Bang TaiKhoan (ĐÃ THÊM SoLanDangNhapSai)
CREATE TABLE TaiKhoan (
    MaTK                INT             IDENTITY(1,1)   NOT NULL,
    TenDangNhap         NVARCHAR(50)    NOT NULL,
    -- MatKhau luu duoi dang hash (BCrypt/SHA-256), toi thieu 255 ky tu
    MatKhau             VARCHAR(255)    NOT NULL,
    VaiTro              NVARCHAR(20)    NOT NULL
                                        CONSTRAINT DF_TaiKhoan_VaiTro    DEFAULT N'NhanVien'
                                        CONSTRAINT CHK_TaiKhoan_VaiTro
                                        CHECK (VaiTro IN (N'Admin', N'NhanVien')),
    -- 1 = Hoat dong, 0 = Bi khoa
    TrangThai           BIT             NOT NULL
                                        CONSTRAINT DF_TaiKhoan_TrangThai DEFAULT 1,
    -- THEM MOI: Theo doi so lan nhap sai mat khau
    SoLanDangNhapSai    INT             NOT NULL
                                        CONSTRAINT DF_TaiKhoan_SoLanSai  DEFAULT 0,
    MaNV                INT             NOT NULL,

    CONSTRAINT PK_TaiKhoan      PRIMARY KEY (MaTK),
    CONSTRAINT UQ_TaiKhoan_TenDangNhap UNIQUE  (TenDangNhap),
    -- Moi nhan vien chi duoc co 1 tai khoan
    CONSTRAINT UQ_TaiKhoan_MaNV UNIQUE  (MaNV),
    CONSTRAINT FK_TaiKhoan_NhanVien
        FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV)
        ON UPDATE CASCADE
        ON DELETE CASCADE   -- Xoa NV -> tu dong xoa TK lien quan
);
GO

-- 3. Bang LoaiSanPham
CREATE TABLE LoaiSanPham (
    MaLoai      INT             IDENTITY(1,1)   NOT NULL,
    TenLoai     NVARCHAR(100)   NOT NULL,
    MoTa        NVARCHAR(300)   NULL,

    CONSTRAINT PK_LoaiSanPham       PRIMARY KEY (MaLoai),
    CONSTRAINT UQ_LoaiSanPham_Ten   UNIQUE (TenLoai)
);
GO

-- 4. Bang SanPham
CREATE TABLE SanPham (
    MaSP        INT             IDENTITY(1,1)   NOT NULL,
    TenSP       NVARCHAR(150)   NOT NULL,
    MaLoai      INT             NOT NULL,
    -- KichCo thay vi Size (Size la tu co the gay nham lan)
    KichCo      NVARCHAR(10)    NULL,
    MauSac      NVARCHAR(50)    NULL,
    GiaBan      DECIMAL(18,2)   NOT NULL
                                CONSTRAINT CHK_SanPham_GiaBan CHECK (GiaBan > 0),
    -- SoLuong ton kho khong duoc am
    SoLuong     INT             NOT NULL
                                CONSTRAINT DF_SanPham_SoLuong   DEFAULT 0
                                CONSTRAINT CHK_SanPham_SoLuong  CHECK (SoLuong >= 0),
    HinhAnh     NVARCHAR(300)   NULL,
    -- 1 = Dang ban, 0 = Ngung ban
    TrangThai   BIT             NOT NULL
                                CONSTRAINT DF_SanPham_TrangThai DEFAULT 1,

    CONSTRAINT PK_SanPham PRIMARY KEY (MaSP),
    CONSTRAINT FK_SanPham_LoaiSanPham
        FOREIGN KEY (MaLoai) REFERENCES LoaiSanPham(MaLoai)
        ON UPDATE CASCADE
        ON DELETE NO ACTION      
);
GO

-- 5. Bang HoaDon
CREATE TABLE HoaDon (
    MaHD        INT             IDENTITY(1,1)   NOT NULL,
    MaNV        INT             NOT NULL,
    NgayLap     DATETIME        NOT NULL
                                CONSTRAINT DF_HoaDon_NgayLap DEFAULT GETDATE(),
    TongTien    DECIMAL(18,2)   NOT NULL
                                CONSTRAINT CHK_HoaDon_TongTien CHECK (TongTien >= 0),
    GhiChu      NVARCHAR(300)   NULL,

    CONSTRAINT PK_HoaDon PRIMARY KEY (MaHD),
    CONSTRAINT FK_HoaDon_NhanVien
        FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV)
        ON UPDATE CASCADE
        ON DELETE NO ACTION    
);
GO

-- 6. Bang ChiTietHoaDon
CREATE TABLE ChiTietHoaDon (
    MaHD        INT             NOT NULL,
    MaSP        INT             NOT NULL,
    SoLuong     INT             NOT NULL
                                CONSTRAINT CHK_CTHD_SoLuong CHECK (SoLuong > 0),
    -- DonGia luu gia tai thoi diem mua (de phong gia SP thay doi sau nay)
    DonGia      DECIMAL(18,2)   NOT NULL
                                CONSTRAINT CHK_CTHD_DonGia  CHECK (DonGia > 0),
    -- Computed column: tu dong tinh, khong the nhap sai
    ThanhTien   AS (CAST(SoLuong AS DECIMAL(18,2)) * DonGia) PERSISTED,

    CONSTRAINT PK_ChiTietHoaDon PRIMARY KEY (MaHD, MaSP),
    CONSTRAINT FK_CTHD_HoaDon
        FOREIGN KEY (MaHD) REFERENCES HoaDon(MaHD)
        ON DELETE CASCADE,      -- Xoa HD -> tu dong xoa ChiTiet
    CONSTRAINT FK_CTHD_SanPham
        FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP)
        ON DELETE NO ACTION     -- Khong xoa SP khi con CTHD
);
GO

PRINT '>> Da tao xong 6 bang.';
GO

-- PHAN 2: TAO INDEX (Tang toc truy van)

-- Tim kiem san pham theo loai
CREATE INDEX IX_SanPham_MaLoai
    ON SanPham(MaLoai);

-- Tim kiem san pham theo ten
CREATE INDEX IX_SanPham_TenSP
    ON SanPham(TenSP);

-- Thong ke doanh thu theo ngay/thang
CREATE INDEX IX_HoaDon_NgayLap
    ON HoaDon(NgayLap);

-- Thong ke doanh so theo nhan vien
CREATE INDEX IX_HoaDon_MaNV
    ON HoaDon(MaNV);

-- Tim kiem tai khoan khi dang nhap
CREATE INDEX IX_TaiKhoan_TenDangNhap
    ON TaiKhoan(TenDangNhap);

PRINT '>> Da tao xong 5 index.';
GO

-- PHAN 3: STORED PROCEDURES

-- SP 1: Dang nhap - Xac thuc tai khoan
CREATE PROCEDURE sp_DangNhap
    @TenDangNhap    NVARCHAR(50),
    @MatKhau        VARCHAR(255)   -- Truyen vao hash da ma hoa tu tang BUS (C#)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        tk.MaTK,
        tk.TenDangNhap,
        tk.VaiTro,
        tk.TrangThai,
        nv.MaNV,
        nv.TenNV
    FROM TaiKhoan tk
    INNER JOIN NhanVien nv ON tk.MaNV = nv.MaNV
    WHERE tk.TenDangNhap = @TenDangNhap
      AND tk.MatKhau     = @MatKhau
      AND tk.TrangThai   = 1;  -- Chi cho dang nhap khi TK dang hoat dong
END
GO

-- SP 2: Cap nhat ton kho sau khi ban hang
CREATE PROCEDURE sp_CapNhatTonKho
    @MaSP       INT,
    @SoLuongBan INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiem tra ton kho truoc khi tru
    IF (SELECT SoLuong FROM SanPham WHERE MaSP = @MaSP) < @SoLuongBan
    BEGIN
        RAISERROR(N'Khong du hang trong kho!', 16, 1);
        RETURN;
    END

    UPDATE SanPham
    SET SoLuong = SoLuong - @SoLuongBan
    WHERE MaSP = @MaSP;
END
GO

-- SP 3: Lap hoa don (dung Transaction dam bao toan ven)
CREATE PROCEDURE sp_LapHoaDon
    @MaNV       INT,
    @TongTien   DECIMAL(18,2),
    @GhiChu     NVARCHAR(300),
    @MaHD_Out   INT OUTPUT  -- Tra ve MaHD vua tao
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO HoaDon (MaNV, TongTien, GhiChu)
            VALUES (@MaNV, @TongTien, @GhiChu);

            SET @MaHD_Out = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        PRINT N'>> Lap hoa don thanh cong. MaHD = ' + CAST(@MaHD_Out AS VARCHAR);
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- SP 4: Thong ke doanh thu theo thang trong nam
CREATE PROCEDURE sp_ThongKeDoanhThuTheo_Thang
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        MONTH(NgayLap)          AS Thang,
        COUNT(MaHD)             AS SoHoaDon,
        SUM(TongTien)           AS TongDoanhThu,
        AVG(TongTien)           AS DoanhThuTrungBinh,
        MAX(TongTien)           AS HoaDonLonNhat
    FROM HoaDon
    WHERE YEAR(NgayLap) = @Nam
    GROUP BY MONTH(NgayLap)
    ORDER BY Thang;
END
GO

PRINT '>> Da tao xong 4 Stored Procedures.';
GO

-- PHAN 4: DU LIEU MAU (Sample Data)

-- Nhan vien
INSERT INTO NhanVien (TenNV, GioiTinh, NgaySinh, SDT, DiaChi)
VALUES
    (N'Nguyen Van An',  N'Nam', '1990-05-15', '0901234567', N'123 Nguyen Hue, Q1, TP.HCM'),
    (N'Tran Thi Bich',  N'Nu',  '1995-08-20', '0912345678', N'45 Le Loi, Q3, TP.HCM'),
    (N'Le Van Cuong',   N'Nam', '1992-11-30', '0923456789', N'78 Hai Ba Trung, Q1, TP.HCM');
GO

-- Tai khoan (1 NV = 1 TK) (ĐÃ CẬP NHẬT SoLanDangNhapSai = 0)
INSERT INTO TaiKhoan (TenDangNhap, MatKhau, VaiTro, MaNV, SoLanDangNhapSai)
VALUES
    ('admin',       'e10adc3949ba59abbe56e057f20f883e', N'Admin',     1, 0),
    ('nhanvien01',  '96e79218965eb72c92a549dd5a330112', N'NhanVien',  2, 0),
    ('nhanvien02',  '96e79218965eb72c92a549dd5a330112', N'NhanVien',  3, 0);
GO

-- Loai san pham
INSERT INTO LoaiSanPham (TenLoai, MoTa)
VALUES
    (N'Ao',         N'Cac loai ao: thun, so mi, khoac...'),
    (N'Quan',       N'Cac loai quan: jean, kaki, short...'),
    (N'Vay',        N'Cac loai vay: midi, mini, maxi...'),
    (N'Phu kien',   N'Non, that lung, tui xach...');
GO

-- San pham
INSERT INTO SanPham (TenSP, MaLoai, KichCo, MauSac, GiaBan, SoLuong)
VALUES
    (N'Ao thun nam co tron',    1, 'M',   N'Trang',       150000, 50),
    (N'Ao so mi nam tay ngan',  1, 'L',   N'Xanh nhat',   250000, 30),
    (N'Ao khoac nu form rong',  1, 'S',   N'Den',         450000, 20),
    (N'Quan jean nu ong rong',  2, 'S',   N'Xanh dam',    350000, 40),
    (N'Quan kaki nam',          2, 'M',   N'Be',          280000, 35),
    (N'Vay midi hoa nho',       3, 'M',   N'Hong nhat',   320000, 25),
    (N'Non bucket trai',        4, NULL,  N'Kem',          95000, 60);
GO

-- Hoa don mau
INSERT INTO HoaDon (MaNV, TongTien, GhiChu)
VALUES
    (2, 500000,  N'Khach le'),
    (2, 280000,  NULL),
    (3, 1020000, N'Khach quen - giam 5%');
GO

-- Chi tiet hoa don
INSERT INTO ChiTietHoaDon (MaHD, MaSP, SoLuong, DonGia)
VALUES
    (1, 1, 2, 150000),   -- HD1: 2 ao thun
    (1, 4, 1, 350000),   -- HD1: 1 quan jean
    (2, 5, 1, 280000),   -- HD2: 1 quan kaki
    (3, 2, 1, 250000),   -- HD3: 1 ao so mi
    (3, 3, 1, 450000),   -- HD3: 1 ao khoac
    (3, 6, 1, 320000);   -- HD3: 1 vay midi
GO

PRINT '>> Da them du lieu mau thanh cong.';
GO

--PHAN 5: KIEM TRA KET QUA

SELECT 'NhanVien'           AS BangDuLieu, COUNT(*) AS SoBanGhi FROM NhanVien
UNION ALL
SELECT 'TaiKhoan',          COUNT(*) FROM TaiKhoan
UNION ALL
SELECT 'LoaiSanPham',       COUNT(*) FROM LoaiSanPham
UNION ALL
SELECT 'SanPham',           COUNT(*) FROM SanPham
UNION ALL
SELECT 'HoaDon',            COUNT(*) FROM HoaDon
UNION ALL
SELECT 'ChiTietHoaDon',     COUNT(*) FROM ChiTietHoaDon;
GO

-- Kiem tra ThanhTien computed column
SELECT
    hd.MaHD,
    nv.TenNV,
    hd.NgayLap,
    sp.TenSP,
    ct.SoLuong,
    ct.DonGia,
    ct.ThanhTien,   
    hd.TongTien
FROM ChiTietHoaDon ct
INNER JOIN HoaDon   hd ON ct.MaHD = hd.MaHD
INNER JOIN SanPham  sp ON ct.MaSP = sp.MaSP
INNER JOIN NhanVien nv ON hd.MaNV = nv.MaNV
ORDER BY hd.MaHD;
GO

PRINT '>> Hoan tat! Database san sang su dung.';
GO