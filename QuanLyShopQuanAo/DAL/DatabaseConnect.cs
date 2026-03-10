using System;
using System.Data;
using System.Data.SqlClient;

namespace QuanLyShopQuanAo.DAL
{
    public class DatabaseConnect
    {
        private string connectionString =
         "Data Source=.;Initial Catalog=QuanLyCuaHangQuanAo;Integrated Security=True";
        public SqlConnection GetConnection()
        {
            return new SqlConnection(connectionString);
        }

        public DataTable ExecuteQuery(string query)
        {
            using (SqlConnection conn = GetConnection())
            {
                conn.Open();
                SqlDataAdapter adapter = new SqlDataAdapter(query, conn);
                DataTable dt = new DataTable();
                adapter.Fill(dt);
                return dt;
            }
        }

        public int ExecuteNonQuery(string query)
        {
            using (SqlConnection conn = GetConnection())
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand(query, conn);
                return cmd.ExecuteNonQuery();
            }
        }

        public object ExecuteScalar(string query)
        {
            using (SqlConnection conn = GetConnection())
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand(query, conn);
                return cmd.ExecuteScalar();
            }
        }
    }
}