using Microsoft.Data.Sqlite;
using System.Data;
using System.Text.RegularExpressions;

namespace BlazorDataDev.Services;

public interface ISqliteQueryService
{
    void LoadSchema(Dictionary<string, List<ColumnInfo>> tableSchemas);
    void LoadData(string tableName, List<Dictionary<string, object?>> rows);
    void ClearAll();
    Task<List<Dictionary<string, object?>>> ExecuteQueryAsync(string query, Dictionary<string, object?>? parameters = null);
    bool IsReadOnlyQuery(string query);
}

public class SqliteQueryService : ISqliteQueryService, IDisposable
{
    private SqliteConnection? _connection;
    private readonly ILogger<SqliteQueryService> _logger;
    private const int MaxResultRows = 10000;
    private const int QueryTimeoutSeconds = 30;

    public SqliteQueryService(ILogger<SqliteQueryService> logger)
    {
        _logger = logger;
    }

    private void EnsureConnection()
    {
        if (_connection == null)
        {
            _connection = new SqliteConnection("Data Source=:memory:");
            _connection.Open();
            _logger.LogInformation("SQLite in-memory database created");
        }
    }

    public void LoadSchema(Dictionary<string, List<ColumnInfo>> tableSchemas)
    {
        EnsureConnection();

        foreach (var (tableName, columns) in tableSchemas)
        {
            try
            {
                // Drop table if exists
                var dropCmd = _connection!.CreateCommand();
                dropCmd.CommandText = $"DROP TABLE IF EXISTS \"{tableName}\"";
                dropCmd.ExecuteNonQuery();

                // Create table
                var columnDefs = columns.Select(c =>
                {
                    var sqliteType = MapPostgresToSqliteType(c.Type);
                    var nullable = c.Nullable ? "" : " NOT NULL";
                    var pk = c.IsPrimaryKey ? " PRIMARY KEY" : "";
                    return $"\"{c.Name}\" {sqliteType}{nullable}{pk}";
                });

                var createTableSql = $"CREATE TABLE \"{tableName}\" ({string.Join(", ", columnDefs)})";
                
                var createCmd = _connection.CreateCommand();
                createCmd.CommandText = createTableSql;
                createCmd.ExecuteNonQuery();

                _logger.LogInformation("Created table {TableName} with {ColumnCount} columns", tableName, columns.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating table {TableName}", tableName);
                throw;
            }
        }
    }

    public void LoadData(string tableName, List<Dictionary<string, object?>> rows)
    {
        if (_connection == null || rows.Count == 0)
            return;

        try
        {
            using var transaction = _connection.BeginTransaction();

            foreach (var row in rows)
            {
                var columns = string.Join(", ", row.Keys.Select(k => $"\"{k}\""));
                var parameters = string.Join(", ", row.Keys.Select((k, i) => $"@p{i}"));
                
                var insertSql = $"INSERT INTO \"{tableName}\" ({columns}) VALUES ({parameters})";
                
                var cmd = _connection.CreateCommand();
                cmd.CommandText = insertSql;
                cmd.Transaction = transaction;

                int paramIndex = 0;
                foreach (var (key, value) in row)
                {
                    var param = cmd.CreateParameter();
                    param.ParameterName = $"@p{paramIndex}";
                    param.Value = value ?? DBNull.Value;
                    cmd.Parameters.Add(param);
                    paramIndex++;
                }

                cmd.ExecuteNonQuery();
            }

            transaction.Commit();
            _logger.LogInformation("Loaded {RowCount} rows into table {TableName}", rows.Count, tableName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading data into table {TableName}", tableName);
            throw;
        }
    }

    public void ClearAll()
    {
        if (_connection != null)
        {
            _connection.Close();
            _connection.Dispose();
            _connection = null;
            _logger.LogInformation("SQLite database cleared");
        }
    }

    public bool IsReadOnlyQuery(string query)
    {
        var upperQuery = query.Trim().ToUpper();
        
        // Block any write operations
        var writeKeywords = new[] { "INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER", "TRUNCATE" };
        
        foreach (var keyword in writeKeywords)
        {
            if (upperQuery.StartsWith(keyword))
                return false;
        }

        return upperQuery.StartsWith("SELECT") || upperQuery.StartsWith("WITH");
    }

    public async Task<List<Dictionary<string, object?>>> ExecuteQueryAsync(
        string query, 
        Dictionary<string, object?>? parameters = null)
    {
        if (_connection == null)
        {
            throw new InvalidOperationException("Database not initialized. Load schema first.");
        }

        // Security: Only allow SELECT queries
        if (!IsReadOnlyQuery(query))
        {
            throw new InvalidOperationException("Only SELECT queries are allowed");
        }

        try
        {
            // Translate PostgreSQL syntax to SQLite
            var translatedQuery = TranslatePostgresToSqlite(query);

            var cmd = _connection.CreateCommand();
            cmd.CommandText = translatedQuery;
            cmd.CommandTimeout = QueryTimeoutSeconds;

            // Bind parameters
            if (parameters != null)
            {
                foreach (var (key, value) in parameters)
                {
                    var param = cmd.CreateParameter();
                    // Handle both @param and $param syntax
                    param.ParameterName = key.StartsWith("@") || key.StartsWith("$") ? key : $"@{key}";
                    param.Value = value ?? DBNull.Value;
                    cmd.Parameters.Add(param);
                }
            }

            var results = new List<Dictionary<string, object?>>();

            using var reader = await cmd.ExecuteReaderAsync();
            
            while (await reader.ReadAsync())
            {
                if (results.Count >= MaxResultRows)
                {
                    _logger.LogWarning("Query result truncated at {MaxRows} rows", MaxResultRows);
                    break;
                }

                var row = new Dictionary<string, object?>();
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    var columnName = reader.GetName(i);
                    var value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                    row[columnName] = value;
                }
                results.Add(row);
            }

            _logger.LogInformation("Query executed successfully, returned {RowCount} rows", results.Count);
            return results;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing query: {Query}", query);
            throw;
        }
    }

    private string TranslatePostgresToSqlite(string query)
    {
        // PostgreSQL to SQLite syntax translation
        var translated = query;

        // 1. Type casting: ::date, ::timestamp, etc. → DATE(), DATETIME()
        translated = Regex.Replace(translated, @"::date\b", "", RegexOptions.IgnoreCase);
        translated = Regex.Replace(translated, @"::timestamp\b", "", RegexOptions.IgnoreCase);
        translated = Regex.Replace(translated, @"::time\b", "", RegexOptions.IgnoreCase);

        // 2. EXTRACT(field FROM column) → strftime()
        translated = Regex.Replace(translated, 
            @"EXTRACT\s*\(\s*hour\s+FROM\s+(\w+)\s*\)", 
            "CAST(strftime('%H', $1) AS INTEGER)", 
            RegexOptions.IgnoreCase);
        
        translated = Regex.Replace(translated, 
            @"EXTRACT\s*\(\s*minute\s+FROM\s+(\w+)\s*\)", 
            "CAST(strftime('%M', $1) AS INTEGER)", 
            RegexOptions.IgnoreCase);

        translated = Regex.Replace(translated, 
            @"EXTRACT\s*\(\s*day\s+FROM\s+(\w+)\s*\)", 
            "CAST(strftime('%d', $1) AS INTEGER)", 
            RegexOptions.IgnoreCase);

        // 3. COALESCE is supported in both
        // 4. NULLIF is supported in both

        // 5. NOW(), CURRENT_DATE, GETUTCDATE() → datetime('now')
        translated = Regex.Replace(translated, @"\bNOW\s*\(\s*\)", "datetime('now')", RegexOptions.IgnoreCase);
        translated = Regex.Replace(translated, @"\bCURRENT_DATE\b", "date('now')", RegexOptions.IgnoreCase);
        translated = Regex.Replace(translated, @"\bGETUTCDATE\s*\(\s*\)", "datetime('now')", RegexOptions.IgnoreCase);

        // 6. Parameter syntax: @param → $param (SQLite prefers $)
        // But we'll support both in parameter binding

        return translated;
    }

    private string MapPostgresToSqliteType(string postgresType)
    {
        var lowerType = postgresType.ToLower();

        if (lowerType.Contains("int") || lowerType.Contains("serial"))
            return "INTEGER";
        
        if (lowerType.Contains("numeric") || lowerType.Contains("decimal") || 
            lowerType.Contains("float") || lowerType.Contains("double") || lowerType.Contains("real"))
            return "REAL";
        
        if (lowerType.Contains("bool"))
            return "INTEGER"; // SQLite uses 0/1 for boolean
        
        if (lowerType.Contains("date") || lowerType.Contains("time"))
            return "TEXT"; // SQLite stores dates as text
        
        // Default to TEXT for varchar, text, char, etc.
        return "TEXT";
    }

    public void Dispose()
    {
        ClearAll();
    }
}
