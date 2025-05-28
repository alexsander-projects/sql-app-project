using sqlapp.Models;
using Microsoft.Data.SqlClient; // Changed from System.Data.SqlClient

namespace sqlapp.Services
{
    public class ProductService : IProductService
    {
        private readonly string _connectionString;

        public ProductService(string connectionString)
        {
            _connectionString = connectionString;
        }

        public async Task<List<Product>> GetProducts()
        {
            List<Product> _product_lst = new List<Product>();
            string _statement = "SELECT ProductId,ProductName,Quantity from Products";

            // Using statement ensures the connection is disposed of properly
            using (SqlConnection _connection = new SqlConnection(_connectionString))
            {
                await _connection.OpenAsync(); // Use async open

                SqlCommand _sqlCommand = new SqlCommand(_statement, _connection);

                using (SqlDataReader _reader = await _sqlCommand.ExecuteReaderAsync()) // SqlDataReader is already in a using block, which is good
                {
                    while (await _reader.ReadAsync()) // Use async read
                    {
                        Product _product = new Product()
                        {
                            ProductID = _reader.GetInt32(0),
                            ProductName = _reader.GetString(1),
                            Quantity = _reader.GetInt32(2)
                        };
                        _product_lst.Add(_product);
                    }
                }
                // No need to explicitly call _connection.Close() due to the using statement
            }
            return _product_lst;
        }
    }
}

