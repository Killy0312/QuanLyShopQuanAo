using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;

namespace QuanLyShopQuanAo.DAL
{
    public class DataProvider
    {
        // Đọc từ App.config, không hard-code
        private static string connectionString =
            ConfigurationManager.ConnectionStrings["QuanLyShopQuanAo"]
                                .ConnectionString;

        // Singleton instance (dùng chung 1 object)
        private static DataProvider instance;
        public static DataProvider Instance
        {
            get
            {
                if (instance == null)
                    instance = new DataProvider();
                return instance;
            }
        }
        private DataProvider() { }

        // Tạo và mở kết nối 
        private SqlConnection GetConnection()
        {
            return new SqlConnection(connectionString);
        }

        // ExecuteQuery: SELECT → trả về DataTable
        // Dùng SqlParameter[] chống SQL Injection
        // Có try/catch xử lý lỗi SQL
        public DataTable ExecuteQuery(
            string query,
            SqlParameter[] parameters = null)
        {
            DataTable dt = new DataTable();
            try
            {
                using (SqlConnection conn = GetConnection())
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.CommandType = CommandType.Text;
                        if (parameters != null)
                            cmd.Parameters.AddRange(parameters);

                        using (SqlDataAdapter adapter = new SqlDataAdapter(cmd))
                        {
                            adapter.Fill(dt);
                        }
                    }
                }
            }
            catch (SqlException ex)
            {
                // Lỗi từ SQL Server (sai query, mất kết nối...)
                throw new Exception("Lỗi truy vấn CSDL: " + ex.Message, ex);
            }
            catch (Exception ex)
            {
                // Lỗi khác (null, config sai...)
                throw new Exception("Lỗi hệ thống: " + ex.Message, ex);
            }
            return dt;
        }

        // ExecuteNonQuery: INSERT/UPDATE/DELETE 
        // Trả về số dòng bị ảnh hưởng (-1 nếu lỗi)
        public int ExecuteNonQuery(
            string query,
            SqlParameter[] parameters = null)
        {
            try
            {
                using (SqlConnection conn = GetConnection())
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.CommandType = CommandType.Text;
                        if (parameters != null)
                            cmd.Parameters.AddRange(parameters);

                        return cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (SqlException ex)
            {
                throw new Exception("Lỗi thực thi lệnh CSDL: " + ex.Message, ex);
            }
            catch (Exception ex)
            {
                throw new Exception("Lỗi hệ thống: " + ex.Message, ex);
            }
        }

        // ExecuteScalar: trả về 1 giá trị duy nhất
        // Dùng cho: COUNT(*), SUM(), MAX(), SCOPE_IDENTITY()
        public object ExecuteScalar(
            string query,
            SqlParameter[] parameters = null)
        {
            try
            {
                using (SqlConnection conn = GetConnection())
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.CommandType = CommandType.Text;
                        if (parameters != null)
                            cmd.Parameters.AddRange(parameters);

                        return cmd.ExecuteScalar();
                    }
                }
            }
            catch (SqlException ex)
            {
                throw new Exception("Lỗi truy vấn giá trị CSDL: " + ex.Message, ex);
            }
            catch (Exception ex)
            {
                throw new Exception("Lỗi hệ thống: " + ex.Message, ex);
            }
        }

        // Dùng khi khởi động app để báo lỗi sớm
        public bool KiemTraKetNoi()
        {
            try
            {
                using (SqlConnection conn = GetConnection())
                {
                    conn.Open();
                    return true;
                }
            }
            catch
            {
                return false;
            }
        }
    }
}
