using System;
using QuanLyShopQuanAo.DAL;
using System.Data;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace QuanLyShopQuanAo
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            try
            {

                DataTable dt = DataProvider.Instance.ExecuteQuery("SELECT * FROM SanPham");


                if (dt != null)
                {
                    MessageBox.Show($"Kết nối Database THÀNH CÔNG! Đã lấy được {dt.Rows.Count} sản phẩm.", "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"KẾT NỐI THẤT BẠI!\nChi tiết lỗi: {ex.Message}", "Báo lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void dataGridView1_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {

        }
    }
}