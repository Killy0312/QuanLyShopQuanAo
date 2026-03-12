using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using QuanLyShopQuanAo.DTO;

namespace QuanLyShopQuanAo.BUS
{
    internal class GioHangBUS
    {
        public List<ChiTietHoaDon> gioHang = new List<ChiTietHoaDon>();
        // Thêm sản phẩm vào giỏ hàng
        public void ThemSanPham(ChiTietHoaDon sp)
        {
            gioHang.Add(sp);
        }
        // Tính tổng tiền
        public double TongTien()
        {
            double tong = 0;

            foreach (var item in gioHang)
            {
                tong += item.ThanhTien;
            }

            return tong;
        }

        // Xóa sản phẩm
        public void XoaSanPham(int index)
        {
            if (index >= 0 && index < gioHang.Count)
            {
                gioHang.RemoveAt(index);
            }
        }

        // Xóa toàn bộ giỏ hàng
        public void XoaTatCa()
        {
            gioHang.Clear();
        }
    }
}
