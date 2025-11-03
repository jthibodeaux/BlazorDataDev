using Dapper;
using Npgsql;
using System.Data;

namespace BlazorDbEditor.Services
{
    public interface IDynamicDbService
    {
        Task<List<string>> GetTablesAsync();
        Task<List<ColumnInfo>> GetColumnsAsync(string tableName);
        Task<List<DynamicRow>> GetDataAsync(string tableName, int limit = 100, int offset = 0);
        Task<int> GetRowCountAsync(string tableName);
        Task ExecuteAsync(string sql);
    }

    public class DynamicDbService : IDynamicDbService
    {
        private readonly IConfiguration _configuration;

        public DynamicDbService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        private IDbConnection GetConnection()
        {
            var connectionString = _configuration.GetConnectionString("PostgreSQL");
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new InvalidOperationException("PostgreSQL connection string not configured");
            }
            return new NpgsqlConnection(connectionString);
        }

        public async Task<List<string>> GetTablesAsync()
        {
            try
            {
                using var connection = GetConnection();
                var tables = await connection.QueryAsync<string>(@"
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'dbo' 
                    AND table_type = 'BASE TABLE'
                    ORDER BY table_name
                ");
                return tables.ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error fetching tables: {ex.Message}");
                return new List<string>();
            }
        }

        public async Task<List<ColumnInfo>> GetColumnsAsync(string tableName)
        {
            try
            {
                using var connection = GetConnection();
                var columns = await connection.QueryAsync<ColumnInfo>(@"
                    SELECT 
                        column_name as Name,
                        data_type as Type,
                        CASE WHEN is_nullable = 'YES' THEN true ELSE false END as Nullable,
                        column_default as DefaultValue
                    FROM information_schema.columns 
                    WHERE table_schema = 'dbo' 
                    AND table_name = @tableName
                    ORDER BY ordinal_position
                ", new { tableName });
                return columns.ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error fetching columns for {tableName}: {ex.Message}");
                return new List<ColumnInfo>();
            }
        }

        public async Task<List<DynamicRow>> GetDataAsync(string tableName, int limit = 100, int offset = 0)
        {
            try
            {
                // Get column metadata first
                var columns = await GetColumnsAsync(tableName);
                
                using var connection = GetConnection();
                var sql = $"SELECT * FROM dbo.{tableName} LIMIT @limit OFFSET @offset";
                
                using var reader = await connection.ExecuteReaderAsync(sql, new { limit, offset });
                
                var results = new List<DynamicRow>();
                while (reader.Read())
                {
                    var rowData = new Dictionary<string, object?>();
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        var value = reader.GetValue(i);
                        rowData[reader.GetName(i)] = value == DBNull.Value ? null : value;
                    }
                    results.Add(new DynamicRow(rowData, columns));
                }
                return results;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error fetching data from {tableName}: {ex.Message}");
                return new List<DynamicRow>();
            }
        }

        public async Task<int> GetRowCountAsync(string tableName)
        {
            try
            {
                using var connection = GetConnection();
                var sql = $"SELECT COUNT(*) FROM dbo.{tableName}";
                return await connection.ExecuteScalarAsync<int>(sql);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting row count for {tableName}: {ex.Message}");
                return 0;
            }
        }

        public async Task ExecuteAsync(string sql)
        {
            using var connection = GetConnection();
            await connection.ExecuteAsync(sql);
        }
    }
}
