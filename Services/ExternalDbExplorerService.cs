using System.Data;
using Npgsql;
using System.Text.Json;

namespace BlazorDataDev.Services;

public interface IExternalDbExplorerService
{
    Task<ConnectionResult> ConnectAsync(ExternalDbConfig config);
    Task<ConnectionResult> TestConnectionAsync(ExternalDbConfig config);
    Task<List<string>> GetSchemasAsync();
    Task<List<TableInfo>> GetTablesAsync(string schema);
    Task<ExportResult> ExportTableAsync(string schema, string tableName);
    Task<ExternalDbConfig> LoadSavedConnectionAsync();
    Task SaveConnectionAsync(ExternalDbConfig config);
}

public class ExternalDbExplorerService : IExternalDbExplorerService
{
    private readonly ILogger<ExternalDbExplorerService> _logger;
    private NpgsqlConnection? _connection;
    private ExternalDbConfig? _currentConfig;
    private const string ConfigFile = "external-db-config.json";
    private const string ExportFolder = "Loadables/external";

    public ExternalDbExplorerService(ILogger<ExternalDbExplorerService> logger)
    {
        _logger = logger;
    }

    public async Task<ConnectionResult> ConnectAsync(ExternalDbConfig config)
    {
        try
        {
      _connection = CreateConnection(config);
     await _connection.OpenAsync();
     
         _currentConfig = config;
          await SaveConnectionAsync(config);
   
   var schemas = await GetSchemasAsync();
          
      return new ConnectionResult 
      { 
    Success = true, 
        Schemas = schemas,
     Message = $"Connected successfully. Found {schemas.Count} schemas."
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to connect to database");
   return new ConnectionResult 
            { 
   Success = false, 
         Error = ex.Message 
        };
        }
    }

  public async Task<ConnectionResult> TestConnectionAsync(ExternalDbConfig config)
    {
  NpgsqlConnection? testConnection = null;
        try
        {
     testConnection = CreateConnection(config);
       await testConnection.OpenAsync();
            
            return new ConnectionResult 
 { 
     Success = true, 
    Message = "Connection successful!" 
  };
        }
        catch (Exception ex)
        {
      _logger.LogError(ex, "Connection test failed");
            return new ConnectionResult 
   { 
      Success = false, 
     Error = ex.Message 
      };
        }
        finally
        {
    testConnection?.Dispose();
        }
    }

    public async Task<List<string>> GetSchemasAsync()
    {
        if (_connection == null || _connection.State != ConnectionState.Open)
      throw new InvalidOperationException("Not connected to database");

var schemas = new List<string>();

    using var command = _connection.CreateCommand();
  
        command.CommandText = 
            "SELECT schema_name FROM information_schema.schemata " +
   "WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast') " +
      "ORDER BY schema_name";

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
   schemas.Add(reader.GetString(0));
        }

 return schemas;
    }

    public async Task<List<TableInfo>> GetTablesAsync(string schema)
    {
      if (_connection == null || _connection.State != ConnectionState.Open)
            throw new InvalidOperationException("Not connected to database");

     var tables = new List<TableInfo>();

    using var command = _connection.CreateCommand();
        
   command.CommandText = @"
 SELECT 
    t.table_name,
                COUNT(c.column_name) as column_count,
                pg_class.reltuples::bigint as estimated_row_count
   FROM information_schema.tables t
            LEFT JOIN information_schema.columns c 
    ON t.table_schema = c.table_schema 
                AND t.table_name = c.table_name
            LEFT JOIN pg_class 
       ON pg_class.relname = t.table_name
       WHERE t.table_schema = @schema
AND t.table_type = 'BASE TABLE'
        GROUP BY t.table_name, pg_class.reltuples
    ORDER BY t.table_name";

        var parameter = command.CreateParameter();
        parameter.ParameterName = "@schema";
    parameter.Value = schema;
        command.Parameters.Add(parameter);

        using var reader = await command.ExecuteReaderAsync();
   while (await reader.ReadAsync())
 {
         tables.Add(new TableInfo
            {
                Name = reader.GetString(0),
    Schema = schema,
         ColumnCount = reader.GetInt32(1),
      EstimatedRowCount = reader.IsDBNull(2) ? null : reader.GetInt64(2)
            });
        }

        return tables;
 }

    public async Task<ExportResult> ExportTableAsync(string schema, string tableName)
    {
        try
    {
          // 1. Export DDL
        var ddl = await GenerateDDL(schema, tableName);
 var ddlPath = Path.Combine(ExportFolder, _currentConfig!.Database, "ddls", $"{tableName}.sql");
            Directory.CreateDirectory(Path.GetDirectoryName(ddlPath)!);
            await File.WriteAllTextAsync(ddlPath, ddl);

            // 2. Export sample data (first 1000 rows) as CSV
            var csvPath = Path.Combine(ExportFolder, _currentConfig.Database, "csv", $"{tableName}.csv");
            Directory.CreateDirectory(Path.GetDirectoryName(csvPath)!);
    await ExportDataToCsv(schema, tableName, csvPath);

         // 3. Export metadata as JSON
     var metadata = await GetTableMetadata(schema, tableName);
            var metadataPath = Path.Combine(ExportFolder, _currentConfig.Database, "metadata", $"{tableName}.json");
   Directory.CreateDirectory(Path.GetDirectoryName(metadataPath)!);
   await File.WriteAllTextAsync(metadataPath, JsonSerializer.Serialize(metadata, new JsonSerializerOptions { WriteIndented = true }));

    return new ExportResult
          {
           Success = true,
DdlPath = ddlPath,
    CsvPath = csvPath,
  MetadataPath = metadataPath
          };
        }
catch (Exception ex)
        {
          _logger.LogError(ex, "Failed to export table {Schema}.{Table}", schema, tableName);
            return new ExportResult
            {
        Success = false,
              Error = ex.Message
      };
   }
    }

    private async Task<string> GenerateDDL(string schema, string tableName)
    {
        var ddl = new System.Text.StringBuilder();
        ddl.AppendLine($"-- DDL for {schema}.{tableName}");
        ddl.AppendLine($"-- Exported from: {_currentConfig!.ConnectionType} - {_currentConfig.Host}");
        ddl.AppendLine($"-- Export date: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");
   ddl.AppendLine();
        ddl.AppendLine($"CREATE TABLE dbo.{tableName} (");

   using var command = _connection!.CreateCommand();
        command.CommandText = @"
 SELECT 
       column_name,
   data_type,
                character_maximum_length,
    numeric_precision,
              numeric_scale,
 is_nullable
   FROM information_schema.columns
        WHERE table_schema = @schema
    AND table_name = @tableName
       ORDER BY ordinal_position";

        var schemaParam = command.CreateParameter();
    schemaParam.ParameterName = "@schema";
 schemaParam.Value = schema;
        command.Parameters.Add(schemaParam);

   var tableParam = command.CreateParameter();
        tableParam.ParameterName = "@tableName";
        tableParam.Value = tableName;
        command.Parameters.Add(tableParam);

        var columns = new List<string>();
    using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var columnName = reader.GetString(0);
            var dataType = reader.GetString(1).ToUpper();
            var maxLength = reader.IsDBNull(2) ? (int?)null : reader.GetInt32(2);
          var precision = reader.IsDBNull(3) ? (int?)null : reader.GetInt32(3);
            var scale = reader.IsDBNull(4) ? (int?)null : reader.GetInt32(4);
 var isNullable = reader.GetString(5) == "YES";

            var columnDef = $"  {columnName} {dataType}";
            
            if (maxLength.HasValue && dataType.Contains("CHAR"))
   columnDef += $"({maxLength})";
      else if (precision.HasValue && scale.HasValue)
          columnDef += $"({precision},{scale})";

      if (!isNullable)
     columnDef += " NOT NULL";

            columns.Add(columnDef);
        }

        ddl.AppendLine(string.Join(",\n", columns));
        ddl.AppendLine(");");

     return ddl.ToString();
    }

    private async Task ExportDataToCsv(string schema, string tableName, string csvPath)
    {
        using var command = _connection!.CreateCommand();
  command.CommandText = $"SELECT * FROM {schema}.{tableName} LIMIT 1000";

     using var reader = await command.ExecuteReaderAsync();
        using var writer = new StreamWriter(csvPath);

        // Write headers
        var headers = new List<string>();
    for (int i = 0; i < reader.FieldCount; i++)
    {
            headers.Add(reader.GetName(i));
        }
await writer.WriteLineAsync(string.Join(",", headers));

     // Write data
        while (await reader.ReadAsync())
        {
            var values = new List<string>();
      for (int i = 0; i < reader.FieldCount; i++)
            {
          var value = reader.IsDBNull(i) ? "" : reader.GetValue(i)?.ToString() ?? "";
     // Escape commas and quotes
              if (value.Contains(",") || value.Contains("\""))
                {
    value = $"\"{value.Replace("\"", "\"\"")}\"";
          }
values.Add(value);
            }
  await writer.WriteLineAsync(string.Join(",", values));
}
    }

    private async Task<TableMetadata> GetTableMetadata(string schema, string tableName)
    {
        var metadata = new TableMetadata
   {
            SchemaName = schema,
            TableName = tableName,
       DatabaseType = _currentConfig!.ConnectionType,
            ExportedAt = DateTime.UtcNow,
            Columns = new List<ColumnMetadata>()
        };

        using var command = _connection!.CreateCommand();
      command.CommandText = @"
       SELECT 
column_name,
          data_type,
     is_nullable,
         column_default,
          character_maximum_length,
      numeric_precision,
  numeric_scale
      FROM information_schema.columns
     WHERE table_schema = @schema
  AND table_name = @tableName
    ORDER BY ordinal_position";

        var schemaParam = command.CreateParameter();
        schemaParam.ParameterName = "@schema";
        schemaParam.Value = schema;
        command.Parameters.Add(schemaParam);

        var tableParam = command.CreateParameter();
     tableParam.ParameterName = "@tableName";
   tableParam.Value = tableName;
        command.Parameters.Add(tableParam);

        using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
        {
      metadata.Columns.Add(new ColumnMetadata
    {
       ColumnName = reader.GetString(0),
                DataType = reader.GetString(1),
       IsNullable = reader.GetString(2) == "YES",
   DefaultValue = reader.IsDBNull(3) ? null : reader.GetString(3),
             MaxLength = reader.IsDBNull(4) ? null : reader.GetInt32(4),
   Precision = reader.IsDBNull(5) ? null : reader.GetInt32(5),
                Scale = reader.IsDBNull(6) ? null : reader.GetInt32(6)
       });
   }

        return metadata;
    }

    public async Task<ExternalDbConfig> LoadSavedConnectionAsync()
    {
        if (File.Exists(ConfigFile))
        {
            var json = await File.ReadAllTextAsync(ConfigFile);
            return JsonSerializer.Deserialize<ExternalDbConfig>(json) ?? new ExternalDbConfig();
        }
        return new ExternalDbConfig();
    }

    public async Task SaveConnectionAsync(ExternalDbConfig config)
    {
        // Don't save password
   var configToSave = new ExternalDbConfig
        {
        ConnectionType = config.ConnectionType,
            Host = config.Host,
    Port = config.Port,
       Database = config.Database,
   Username = config.Username,
        UseSsl = config.UseSsl
      };

        var json = JsonSerializer.Serialize(configToSave, new JsonSerializerOptions { WriteIndented = true });
        await File.WriteAllTextAsync(ConfigFile, json);
    }

    private NpgsqlConnection CreateConnection(ExternalDbConfig config)
    {
        var builder = new NpgsqlConnectionStringBuilder
        {
  Host = config.Host,
            Port = config.Port,
            Database = config.Database,
  Username = config.Username,
   Password = config.Password,
    SslMode = config.UseSsl ? SslMode.Require : SslMode.Prefer,
            Timeout = 30
        };

        return new NpgsqlConnection(builder.ToString());
    }
}

// Models
public class ExternalDbConfig
{
    public string ConnectionType { get; set; } = "PostgreSQL";
    public string Host { get; set; } = "";
    public int Port { get; set; } = 5432;
    public string Database { get; set; } = "";
    public string Username { get; set; } = "";
  public string Password { get; set; } = "";
    public bool UseSsl { get; set; } = true;
}

public class ConnectionResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string? Message { get; set; }
    public List<string>? Schemas { get; set; }
}

public class TableInfo
{
    public string Name { get; set; } = "";
    public string Schema { get; set; } = "";
    public int ColumnCount { get; set; }
    public long? EstimatedRowCount { get; set; }
}

public class ExportResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
  public string? DdlPath { get; set; }
    public string? CsvPath { get; set; }
    public string? MetadataPath { get; set; }
}

public class TableMetadata
{
    public string SchemaName { get; set; } = "";
    public string TableName { get; set; } = "";
    public string DatabaseType { get; set; } = "";
    public DateTime ExportedAt { get; set; }
    public List<ColumnMetadata> Columns { get; set; } = new();
}

public class ColumnMetadata
{
    public string ColumnName { get; set; } = "";
    public string DataType { get; set; } = "";
    public bool IsNullable { get; set; }
    public string? DefaultValue { get; set; }
    public int? MaxLength { get; set; }
    public int? Precision { get; set; }
    public int? Scale { get; set; }
}
