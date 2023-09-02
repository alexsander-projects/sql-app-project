using Azure.Core;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Newtonsoft.Json;
using sqlapp.Models;
using StackExchange.Redis;
using System.Data.SqlClient;

namespace sqlapp.Services
{

    public class ProductService : IProductService
    {
        private readonly IConnectionMultiplexer _redis;
        public ProductService(IConnectionMultiplexer redis)
        {
            _redis = redis;
        }
        private SqlConnection GetConnection()
        {
            string keyvaultUrl = "YOUR_KEY_VAULT_URI";
            string secretName = "SecretNameForConnectionString";

            TokenCredential tokenCredential = new DefaultAzureCredential();
            SecretClient secretClient = new SecretClient(new Uri(keyvaultUrl), tokenCredential);

            var secret = secretClient.GetSecret(secretName);

            string connectionString = secret.Value.Value;


            return new SqlConnection(connectionString);
        }
        public async Task<List<Product>> GetProducts()
        {
            List<Product> _product_lst = new List<Product>();
            IDatabase database = _redis.GetDatabase();
            string key = "productlist";

            if (await database.KeyExistsAsync(key))
            {
                long listLenght = database.ListLength(key);
                for (int i = 0; i < listLenght; i++)
                {
                    string value = database.ListGetByIndex(key, i);
                    Product product = JsonConvert.DeserializeObject<Product>(value);
                    _product_lst.Add(product);
                }
                return _product_lst;
            }
            else
            {
                string _statement = "SELECT ProductId,ProductName,Quantity from Products";
                SqlConnection _connection = GetConnection();

                _connection.Open();

                SqlCommand _sqlCommand = new SqlCommand(_statement, _connection);

                using (SqlDataReader _reader = _sqlCommand.ExecuteReader())
                {
                    while (_reader.Read())
                    {
                        Product _product = new Product()
                        {
                            ProductID = _reader.GetInt32(0),
                            ProductName = _reader.GetString(1),
                            Quantity = _reader.GetInt32(2)
                        };
                        database.ListRightPush(key, JsonConvert.SerializeObject(_product));
                        _product_lst.Add(_product);
                    }
                }
                _connection.Close();
                return _product_lst;
            }
        }
    }
};