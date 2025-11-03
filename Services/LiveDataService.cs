using Npgsql;
using System.Data;

namespace BlazorDataDev.Services;

public interface ILiveDataService
{
    Task<bool> TestConnectionAsync(string connectionString);
    Task<List<string>> GetTablesAsync(string connectionString, string schema = "dbo");
    Task<LiveDataResult> LoadTableDataAsync(string connectionString, string tableName, LoadOptions options);
    Task<LiveDataResult> LoadMultipleTablesAsync(string connectionString, List<string> tableNames, LoadOptions options);
}

public class LiveDataService : ILiveDataService
{
    private readonly ILogger<LiveDataService> _logger;
    private readonly IInMemoryDataStore _dataStore;
    private readonly ISqliteQueryService _sqliteService;

    public LiveDataService(
        ILogger<LiveDataService> logger,
        IInMemoryDataStore dataStore,
    ISqliteQueryService sqliteService)
    {
        _logger = logger;
        _dataStore = dataStore;
        _sqliteService = sqliteService;
    }

    public async Task<bool> TestConnectionAsync(string connectionString)
    {
        try
    {
            using var connection = new NpgsqlConnection(connectionString);
         await connection.OpenAsync();
            _logger.LogInformation("Connection test successful");
       return true;
        }
      catch (Exception ex)
    {
  _logger.LogError(ex, "Connection test failed");
            return false;
      }
    }

    public async Task<List<string>> GetTablesAsync(string connectionString, string schema = "dbo")
    {
   try
        {
      using var connection = new NpgsqlConnection(connectionString);
            await connection.OpenAsync();

    var query = @"
       SELECT table_name 
         FROM information_schema.tables 
          WHERE table_schema = @schema 
         AND table_type = 'BASE TABLE'
        ORDER BY table_name";

     using var cmd = new NpgsqlCommand(query, connection);
       cmd.Parameters.AddWithValue("schema", schema);

   var tables = new List<string>();
 using var reader = await cmd.ExecuteReaderAsync();
  while (await reader.ReadAsync())
        {
       tables.Add(reader.GetString(0));
       }

       _logger.LogInformation("Found {Count} tables in schema {Schema}", tables.Count, schema);
      return tables;
        }
        catch (Exception ex)
        {
         _logger.LogError(ex, "Error getting tables from database");
    throw;
      }
    }

    public async Task<LiveDataResult> LoadTableDataAsync(
   string connectionString, 
   string tableName, 
        LoadOptions options)
    {
  var result = new LiveDataResult { TableName = tableName };

        try
{
         using var connection = new NpgsqlConnection(connectionString);
   await connection.OpenAsync();

     // Get column info
        var columns = await GetColumnInfoAsync(connection, tableName, options.Schema);
            result.Columns = columns;

            // Detect date column for filtering
      var dateColumn = DetectDateColumn(columns, options.DateColumnHint);

  // Build query
       var query = BuildQuery(tableName, options.Schema, dateColumn, options);

       _logger.LogInformation("Executing query: {Query}", query);

       using var cmd = new NpgsqlCommand(query, connection);
        
            // Add parameters
      if (dateColumn != null && options.DaysBack > 0)
       {
  cmd.Parameters.AddWithValue("startDate", DateTime.Today.AddDays(-options.DaysBack));
   }
  if (options.MaxRows > 0)
     {
       cmd.Parameters.AddWithValue("maxRows", options.MaxRows);
            }

   // Load data
      var rows = new List<Dictionary<string, object?>>();
            using var reader = await cmd.ExecuteReaderAsync();
   
       while (await reader.ReadAsync())
            {
                var row = new Dictionary<string, object?>();
      for (int i = 0; i < reader.FieldCount; i++)
    {
        var columnName = reader.GetName(i);
      var value = reader.IsDBNull(i) ? null : reader.GetValue(i);
         row[columnName] = value;
      }
                rows.Add(row);
 }

   result.RowsLoaded = rows.Count;
    result.Success = true;

            // Sync to data store
       _dataStore.LoadSchema(tableName, columns);
  foreach (var row in rows)
      {
  _dataStore.AddRow(tableName, row);
        }

        // Load into SQLite for queries
 _sqliteService.LoadData(tableName, rows);

   _logger.LogInformation("Loaded {Count} rows from {Table}", rows.Count, tableName);

            return result;
   }
        catch (Exception ex)
        {
      _logger.LogError(ex, "Error loading data from table {Table}", tableName);
            result.Success = false;
   result.ErrorMessage = ex.Message;
    return result;
        }
    }

    public async Task<LiveDataResult> LoadMultipleTablesAsync(
        string connectionString, 
        List<string> tableNames, 
        LoadOptions options)
    {
        var result = new LiveDataResult { TableName = "Multiple Tables" };
        var results = new List<LiveDataResult>();

  foreach (var tableName in tableNames)
        {
  var tableResult = await LoadTableDataAsync(connectionString, tableName, options);
            results.Add(tableResult);
        result.RowsLoaded += tableResult.RowsLoaded;
        }

        result.Success = results.All(r => r.Success);
     result.ErrorMessage = string.Join("; ", results.Where(r => !r.Success).Select(r => $"{r.TableName}: {r.ErrorMessage}"));
   result.Details = results;

        return result;
    }

    private async Task<List<ColumnInfo>> GetColumnInfoAsync(NpgsqlConnection connection, string tableName, string schema)
    {
        var query = @"
 SELECT 
     column_name,
     data_type,
         is_nullable,
        column_default
    FROM information_schema.columns 
   WHERE table_schema = @schema 
 AND table_name = @tableName
  ORDER BY ordinal_position";

        using var cmd = new NpgsqlCommand(query, connection);
     cmd.Parameters.AddWithValue("schema", schema);
      cmd.Parameters.AddWithValue("tableName", tableName);

  var columns = new List<ColumnInfo>();
     using var reader = await cmd.ExecuteReaderAsync();
  
        while (await reader.ReadAsync())
        {
   columns.Add(new ColumnInfo
  {
                Name = reader.GetString(0),
        Type = reader.GetString(1),
     Nullable = reader.GetString(2) == "YES",
   DefaultValue = reader.IsDBNull(3) ? null : reader.GetString(3),
       IsPrimaryKey = false // Could enhance to detect PKs
   });
    }

   return columns;
    }

    private string? DetectDateColumn(List<ColumnInfo> columns, string? hint)
    {
        // If hint provided, use it
        if (!string.IsNullOrEmpty(hint) && columns.Any(c => c.Name.Equals(hint, StringComparison.OrdinalIgnoreCase)))
   {
    return hint;
        }

        // Common date column names
        var dateColumnNames = new[] { "timestamp", "created_at", "created_date", "date", "flowdate", "gasday" };
      
    foreach (var name in dateColumnNames)
        {
            var match = columns.FirstOrDefault(c => 
             c.Name.Equals(name, StringComparison.OrdinalIgnoreCase) && 
      (c.Type.Contains("timestamp") || c.Type.Contains("date")));

   if (match != null)
            return match.Name;
        }

        // Fallback: first date/timestamp column
     var dateCol = columns.FirstOrDefault(c => c.Type.Contains("timestamp") || c.Type.Contains("date"));
        return dateCol?.Name;
    }

    private string BuildQuery(string tableName, string schema, string? dateColumn, LoadOptions options)
    {
        var query = $"SELECT * FROM {schema}.{tableName}";

var whereClauses = new List<string>();

        // Date filter
        if (dateColumn != null && options.DaysBack > 0)
  {
            whereClauses.Add($"{dateColumn} >= @startDate");
    }

        // Custom where clause
     if (!string.IsNullOrEmpty(options.WhereClause))
        {
        whereClauses.Add($"({options.WhereClause})");
        }

  if (whereClauses.Any())
{
            query += " WHERE " + string.Join(" AND ", whereClauses);
        }

        // Order by date column descending (most recent first)
   if (dateColumn != null)
        {
            query += $" ORDER BY {dateColumn} DESC";
        }

    // Limit rows
        if (options.MaxRows > 0)
     {
        query += " LIMIT @maxRows";
 }

        return query;
    }
}

public class LoadOptions
{
    public string Schema { get; set; } = "dbo";
  public int DaysBack { get; set; } = 1; // Load last N days
    public int MaxRows { get; set; } = 10000; // Max rows per table
    public string? DateColumnHint { get; set; } // Hint for date column name
 public string? WhereClause { get; set; } // Custom filter
}

public class LiveDataResult
{
    public bool Success { get; set; }
    public string TableName { get; set; } = "";
    public int RowsLoaded { get; set; }
    public string? ErrorMessage { get; set; }
    public List<ColumnInfo>? Columns { get; set; }
    public List<LiveDataResult>? Details { get; set; } // For multiple tables
}
