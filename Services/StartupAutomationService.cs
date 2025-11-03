using System.Text.Json;
using System.Text;
using Microsoft.JSInterop;

namespace BlazorDbEditor.Services;

public interface IStartupAutomationService
{
    Task<StartupResult> ExecuteStartupWorkflowAsync();
    Task<bool> CheckForExistingWorkspaceAsync();
    Task<StartupResult> LoadWorkspaceAsync(string workspacePath);
}

public class StartupAutomationService : IStartupAutomationService
{
    private readonly ILogger<StartupAutomationService> _logger;
    private readonly IInMemoryDataStore _dataStore;
    private readonly ISqliteQueryService _sqliteService;
    private readonly IConfiguration _configuration;
    private const string ConfigFileName = "startup-config.json";
    private const string LoadablesFolder = "Loadables";

    public StartupAutomationService(
        ILogger<StartupAutomationService> logger,
        IInMemoryDataStore dataStore,
        ISqliteQueryService sqliteService,
    IConfiguration configuration)
    {
        _logger = logger;
        _dataStore = dataStore;
        _sqliteService = sqliteService;
   _configuration = configuration;
    }

    public async Task<StartupResult> ExecuteStartupWorkflowAsync()
    {
        var result = new StartupResult();
        
        try
     {
_logger.LogInformation("Starting automated startup workflow...");

    // Check if Loadables folder exists
          var loadablesPath = Path.Combine(Directory.GetCurrentDirectory(), LoadablesFolder);
            if (!Directory.Exists(loadablesPath))
            {
           _logger.LogWarning("Loadables folder not found at: {Path}", loadablesPath);
      Directory.CreateDirectory(loadablesPath);
     result.AddMessage("Created Loadables folder. Please add your DDL and CSV files.");
     return result;
    }

            // Step 1: Load DDL file - check root and ddls/ subfolder
     var ddlSearchPaths = new[] { loadablesPath, Path.Combine(loadablesPath, "ddls"), Path.Combine(loadablesPath, "ddl") };
   string? ddlFile = null;
            
            foreach (var searchPath in ddlSearchPaths)
   {
          if (Directory.Exists(searchPath))
  {
         ddlFile = Directory.GetFiles(searchPath, "*.sql", SearchOption.AllDirectories).FirstOrDefault();
        if (ddlFile != null)
              {
             _logger.LogInformation("Found DDL file in: {Path}", searchPath);
          break;
                }
  }
            }
     
          if (ddlFile == null)
        {
       result.AddError("No DDL file (.sql) found in Loadables/, Loadables/ddls/, or Loadables/ddl/");
       return result;
       }

       _logger.LogInformation("Loading DDL from: {File}", ddlFile);
            var ddlContent = await File.ReadAllTextAsync(ddlFile);
            var tableSchemas = ParseDDL(ddlContent);
            
 result.DdlContent = ddlContent;
            result.TableSchemas = tableSchemas;
  result.AddMessage($"? Loaded DDL: {tableSchemas.Count} tables found");

         // Sync schemas to data store
            SyncSchemasToDataStore(tableSchemas);
       result.AddMessage($"? Synced {tableSchemas.Count} table schemas to API");

            // Step 2: Auto-load CSV files - check root and csv/ subfolder
 var csvSearchPaths = new[] { loadablesPath, Path.Combine(loadablesPath, "csv"), Path.Combine(loadablesPath, "csvs") };
   var csvFiles = new List<string>();
      
     foreach (var searchPath in csvSearchPaths)
            {
     if (Directory.Exists(searchPath))
     {
          var files = Directory.GetFiles(searchPath, "*.csv", SearchOption.AllDirectories);
      csvFiles.AddRange(files);
               if (files.Any())
    {
 _logger.LogInformation("Found {Count} CSV files in: {Path}", files.Length, searchPath);
        }
       }
  }
            
     _logger.LogInformation("Total CSV files found: {Count}", csvFiles.Count);

     var generatedSQL = new StringBuilder();
            int totalRows = 0;

 foreach (var csvFile in csvFiles)
     {
      try
 {
      var fileName = Path.GetFileNameWithoutExtension(csvFile);
          var tableName = fileName; // CSV filename = table name
           
   if (!tableSchemas.ContainsKey(tableName))
            {
      _logger.LogWarning("Table {Table} not found in DDL, skipping CSV: {File}", tableName, csvFile);
    result.AddWarning($"Skipped {fileName}.csv - table not in DDL");
      continue;
 }

          _logger.LogInformation("Loading CSV: {File} ? {Table}", csvFile, tableName);

 var csvContent = await File.ReadAllTextAsync(csvFile);
         var (sql, rowData) = ParseCsvToInserts(csvContent, tableName);
  
     generatedSQL.AppendLine($"-- Data from {fileName}.csv");
    generatedSQL.AppendLine(sql);
            generatedSQL.AppendLine();
        
              // Sync to data store for API
         foreach (var row in rowData)
        {
         _dataStore.AddRow(tableName, row.ToDictionary(kvp => kvp.Key, kvp => (object?)kvp.Value));
      }
     
        // Load into SQLite for queries
              var sqliteRows = rowData.Select(r => r.ToDictionary(kvp => kvp.Key, kvp => (object?)kvp.Value)).ToList();
          _sqliteService.LoadData(tableName, sqliteRows);

   totalRows += rowData.Count;
          result.AddMessage($"? Loaded {fileName}.csv: {rowData.Count} rows ? {tableName}");
       }
    catch (Exception ex)
        {
       _logger.LogError(ex, "Error loading CSV: {File}", csvFile);
           result.AddError($"Failed to load {Path.GetFileName(csvFile)}: {ex.Message}");
                }
     }

   result.GeneratedSQL = generatedSQL.ToString();
  result.TotalRowsLoaded = totalRows;
result.AddMessage($"? Total: {totalRows} rows loaded from {csvFiles.Count} CSV files");

          // Step 3: Generate SQL script file
 var outputPath = Path.Combine(loadablesPath, "output");
       Directory.CreateDirectory(outputPath);
     
        var sqlFileName = Path.Combine(outputPath, $"generated_inserts_{DateTime.Now:yyyyMMdd_HHmmss}.sql");
       await File.WriteAllTextAsync(sqlFileName, result.GeneratedSQL);
         result.SqlScriptPath = sqlFileName;
result.AddMessage($"? Generated SQL saved: {Path.GetFileName(sqlFileName)}");

  // Step 4: Save workspace
            var workspaceData = new WorkspaceData
       {
  DdlContent = ddlContent,
      TableSchemas = tableSchemas.ToDictionary(
              kvp => kvp.Key,
   kvp => kvp.Value.Select(c => new ColumnDefinition
            {
             Name = c.Name,
             Type = c.Type,
        Nullable = c.Nullable,
      IsNew = false
  }).ToList()
             ),
    OriginalSchemas = tableSchemas.ToDictionary(
        kvp => kvp.Key,
         kvp => kvp.Value.Select(c => new ColumnDefinition
         {
   Name = c.Name,
 Type = c.Type,
   Nullable = c.Nullable,
     IsNew = false
  }).ToList()
          ),
    SelectedTable = "",
    SavedAt = DateTime.Now,
        TableCount = tableSchemas.Count
       };

            var workspaceJson = JsonSerializer.Serialize(workspaceData, new JsonSerializerOptions { WriteIndented = true });
            var workspacePath = Path.Combine(outputPath, $"auto_workspace_{DateTime.Now:yyyyMMdd_HHmmss}.json");
            await File.WriteAllTextAsync(workspacePath, workspaceJson);
      result.WorkspacePath = workspacePath;
  result.AddMessage($"? Workspace saved: {Path.GetFileName(workspacePath)}");

  result.Success = true;
    result.AddMessage("?? Startup workflow completed successfully!");
  
        _logger.LogInformation("Startup workflow completed: {Tables} tables, {Rows} rows", tableSchemas.Count, totalRows);
 
            return result;
    }
        catch (Exception ex)
        {
          _logger.LogError(ex, "Error in startup workflow");
result.AddError($"Startup workflow failed: {ex.Message}");
         return result;
   }
    }

    public async Task<bool> CheckForExistingWorkspaceAsync()
    {
        var loadablesPath = Path.Combine(Directory.GetCurrentDirectory(), LoadablesFolder, "output");
        if (!Directory.Exists(loadablesPath))
            return false;

        var workspaceFiles = Directory.GetFiles(loadablesPath, "auto_workspace_*.json");
        return workspaceFiles.Any();
    }

    public async Task<StartupResult> LoadWorkspaceAsync(string workspacePath)
  {
        var result = new StartupResult();
      
     try
 {
       _logger.LogInformation("Loading workspace from: {Path}", workspacePath);
       
            var json = await File.ReadAllTextAsync(workspacePath);
            var workspace = JsonSerializer.Deserialize<WorkspaceData>(json);
            
    if (workspace == null)
        {
  result.AddError("Invalid workspace file");
         return result;
  }

      // Convert to ColumnInfo and sync
  var tableSchemas = new Dictionary<string, List<ColumnInfo>>();
            foreach (var kvp in workspace.TableSchemas)
            {
       tableSchemas[kvp.Key] = kvp.Value.Select(c => new ColumnInfo
        {
      Name = c.Name,
         Type = c.Type,
            Nullable = c.Nullable
 }).ToList();
            }

       result.DdlContent = workspace.DdlContent;
   result.TableSchemas = tableSchemas;
   
            // Sync to data store
            SyncSchemasToDataStore(tableSchemas);
         
            result.Success = true;
        result.AddMessage($"? Workspace loaded: {workspace.TableCount} tables");
  result.AddMessage($"? Saved at: {workspace.SavedAt:yyyy-MM-dd HH:mm:ss}");
  result.AddMessage("??  Import CSV files separately if needed");
     
            return result;
        }
        catch (Exception ex)
        {
          _logger.LogError(ex, "Error loading workspace");
          result.AddError($"Failed to load workspace: {ex.Message}");
       return result;
        }
    }

    private Dictionary<string, List<ColumnInfo>> ParseDDL(string ddlContent)
    {
      var schemas = new Dictionary<string, List<ColumnInfo>>();
    var lines = ddlContent.Split('\n');
      string? currentTable = null;
        List<ColumnInfo>? currentColumns = null;
   bool inTableDef = false;

        foreach (var line in lines)
        {
            var trimmed = line.Trim();

     if (trimmed.StartsWith("CREATE TABLE", StringComparison.OrdinalIgnoreCase))
     {
    var parts = trimmed.Split(new[] { ' ', '(' }, StringSplitOptions.RemoveEmptyEntries);
              if (parts.Length >= 3)
     {
                  currentTable = parts[2].Replace("dbo.", "").Replace(";", "");
          currentColumns = new List<ColumnInfo>();
           schemas[currentTable] = currentColumns;
       inTableDef = true;
           }
      }
            else if (inTableDef && !trimmed.StartsWith("CONSTRAINT") && !trimmed.StartsWith(");") && !trimmed.StartsWith("--") && !trimmed.StartsWith("CREATE INDEX"))
    {
       if (trimmed.Contains(" ") && !string.IsNullOrWhiteSpace(trimmed))
     {
           var parts = trimmed.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length >= 2 && !parts[0].StartsWith("--"))
      {
      var colName = parts[0].Trim('"', ',');
        var colType = parts[1].Trim(',');
       var nullable = !trimmed.Contains("NOT NULL", StringComparison.OrdinalIgnoreCase);

           currentColumns?.Add(new ColumnInfo
      {
        Name = colName,
Type = colType,
  Nullable = nullable
  });
        }
       }
   }
          else if (trimmed.StartsWith(");") || trimmed.StartsWith("CREATE INDEX"))
            {
           inTableDef = false;
  }
        }

   return schemas;
    }

    private (string sql, List<Dictionary<string, string>> data) ParseCsvToInserts(string csvContent, string tableName)
    {
        var lines = csvContent.Split('\n').Where(l => !string.IsNullOrWhiteSpace(l)).ToList();
        if (lines.Count < 2)
     throw new Exception("CSV must have header and at least one data row");

        var headers = ParseCsvLine(lines[0]);
   var sqlBuilder = new StringBuilder();
        var rowData = new List<Dictionary<string, string>>();

     for (int i = 1; i < lines.Count; i++)
        {
     var values = ParseCsvLine(lines[i]);
            if (values.Count != headers.Count)
         continue;

            var row = new Dictionary<string, string>();
    var formattedValues = new List<string>();

          for (int j = 0; j < values.Count; j++)
       {
   row[headers[j]] = values[j];
  
      if (string.IsNullOrEmpty(values[j]) || values[j].Equals("NULL", StringComparison.OrdinalIgnoreCase))
  {
           formattedValues.Add("NULL");
    }
         else
     {
          formattedValues.Add($"'{values[j].Replace("'", "''")}'");
      }
            }

            rowData.Add(row);
sqlBuilder.AppendLine($"INSERT INTO dbo.{tableName} ({string.Join(", ", headers)}) VALUES ({string.Join(", ", formattedValues)});");
        }

  return (sqlBuilder.ToString(), rowData);
  }

    private List<string> ParseCsvLine(string line)
    {
      var values = new List<string>();
        var current = new StringBuilder();
        bool inQuotes = false;

  for (int i = 0; i < line.Length; i++)
        {
 char c = line[i];
            if (c == '"')
            {
              if (inQuotes && i + 1 < line.Length && line[i + 1] == '"')
            {
          current.Append('"');
    i++;
                }
      else
     {
           inQuotes = !inQuotes;
     }
            }
   else if (c == ',' && !inQuotes)
      {
          values.Add(current.ToString());
     current.Clear();
    }
      else
            {
             current.Append(c);
 }
        }
        values.Add(current.ToString());
        return values;
    }

    private void SyncSchemasToDataStore(Dictionary<string, List<ColumnInfo>> schemas)
    {
        foreach (var kvp in schemas)
        {
    _dataStore.LoadSchema(kvp.Key, kvp.Value);
        }
        
        // Also load into SQLite
        _sqliteService.LoadSchema(schemas);
    }
}

public class StartupResult
{
    public bool Success { get; set; }
    public string DdlContent { get; set; } = "";
    public Dictionary<string, List<ColumnInfo>> TableSchemas { get; set; } = new();
    public string GeneratedSQL { get; set; } = "";
  public int TotalRowsLoaded { get; set; }
 public string? SqlScriptPath { get; set; }
    public string? WorkspacePath { get; set; }
 public List<string> Messages { get; set; } = new();
    public List<string> Warnings { get; set; } = new();
    public List<string> Errors { get; set; } = new();

    public void AddMessage(string message) => Messages.Add(message);
    public void AddWarning(string warning) => Warnings.Add(warning);
    public void AddError(string error) => Errors.Add(error);
}

public class WorkspaceData
{
    public string DdlContent { get; set; } = "";
    public Dictionary<string, List<ColumnDefinition>> TableSchemas { get; set; } = new();
    public Dictionary<string, List<ColumnDefinition>> OriginalSchemas { get; set; } = new();
    public string SelectedTable { get; set; } = "";
    public DateTime SavedAt { get; set; }
    public int TableCount { get; set; }
}

public class ColumnDefinition
{
    public string Name { get; set; } = "";
    public string Type { get; set; } = "";
    public bool Nullable { get; set; }
    public bool IsNew { get; set; }
}
