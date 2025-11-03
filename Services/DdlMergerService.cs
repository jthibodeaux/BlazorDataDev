using System.Text;
using System.Text.RegularExpressions;

namespace BlazorDataDev.Services;

public interface IDdlMergerService
{
    Task<MergeResult> MergeAsync(MergeRequest request);
    Task<SaveResult> SaveToLoadablesAsync(string fileName, string content);
}

public class DdlMergerService : IDdlMergerService
{
    private readonly ILogger<DdlMergerService> _logger;
    private const string LoadablesFolder = "Loadables/ddls";

    public DdlMergerService(ILogger<DdlMergerService> logger)
    {
  _logger = logger;
    }

    public async Task<MergeResult> MergeAsync(MergeRequest request)
    {
        try
  {
      var merged = new StringBuilder();
     var tablesSeen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
 var duplicatesRemoved = 0;
   var tablesFound = 0;

            merged.AppendLine("-- Merged DDL File");
      merged.AppendLine($"-- Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
  merged.AppendLine($"-- Source files: {request.Files.Count}");
merged.AppendLine();

       foreach (var file in request.Files)
            {
  _logger.LogInformation("Processing DDL file: {FileName}", file.FileName);

       if (request.AddSourceComments)
     {
       merged.AppendLine($"-- ==========================================");
          merged.AppendLine($"-- Source: {file.FileName}");
   merged.AppendLine($"-- ==========================================");
   merged.AppendLine();
   }

     var tables = ExtractTables(file.Content);
    tablesFound += tables.Count;

            foreach (var table in tables)
   {
 if (request.RemoveDuplicates && tablesSeen.Contains(table.TableName))
  {
  _logger.LogWarning("Duplicate table found: {TableName} (keeping first occurrence)", table.TableName);
    duplicatesRemoved++;
   continue;
         }

   tablesSeen.Add(table.TableName);

      if (request.AddSourceComments)
    {
     merged.AppendLine($"-- Table: {table.TableName}");
  merged.AppendLine($"-- From: {file.FileName}");
   }

       merged.AppendLine(table.Ddl);
  merged.AppendLine();
     }
            }

   var result = new MergeResult
  {
         Success = true,
 MergedContent = merged.ToString(),
Statistics = new MergeStatistics
       {
   FilesProcessed = request.Files.Count,
       TablesFound = tablesFound,
    DuplicatesRemoved = duplicatesRemoved,
         OutputSize = merged.Length
    }
   };

    await Task.CompletedTask;
  return result;
        }
        catch (Exception ex)
 {
      _logger.LogError(ex, "Failed to merge DDL files");
     return new MergeResult
      {
     Success = false,
   Error = ex.Message
      };
  }
    }

    public async Task<SaveResult> SaveToLoadablesAsync(string fileName, string content)
 {
        try
        {
   Directory.CreateDirectory(LoadablesFolder);

       if (!fileName.EndsWith(".sql", StringComparison.OrdinalIgnoreCase))
    {
       fileName += ".sql";
 }

       var filePath = Path.Combine(LoadablesFolder, fileName);
  await File.WriteAllTextAsync(filePath, content);

 _logger.LogInformation("Saved merged DDL to: {FilePath}", filePath);

 return new SaveResult
 {
 Success = true,
        FilePath = filePath
     };
}
        catch (Exception ex)
 {
      _logger.LogError(ex, "Failed to save DDL file");
      return new SaveResult
   {
      Success = false,
  Error = ex.Message
   };
        }
    }

    private List<ExtractedTable> ExtractTables(string ddl)
    {
 var tables = new List<ExtractedTable>();

        // Regex to match CREATE TABLE statements (multi-line)
        var pattern = @"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:dbo\.)?([a-zA-Z0-9_]+)\s*\((.*?)\);";
      var regex = new Regex(pattern, RegexOptions.IgnoreCase | RegexOptions.Singleline);

     var matches = regex.Matches(ddl);

        foreach (Match match in matches)
        {
 var tableName = match.Groups[1].Value;
   var ddlStatement = match.Value;

  tables.Add(new ExtractedTable
    {
   TableName = tableName,
       Ddl = ddlStatement
   });
        }

        return tables;
    }

    private class ExtractedTable
    {
        public string TableName { get; set; } = "";
        public string Ddl { get; set; } = "";
  }
}

// Models
public class MergeRequest
{
    public List<DdlFile> Files { get; set; } = new();
    public bool RemoveDuplicates { get; set; } = true;
    public bool AddSourceComments { get; set; } = true;
}

public class DdlFile
{
    public string FileName { get; set; } = "";
    public string Content { get; set; } = "";
}

public class MergeResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string? MergedContent { get; set; }
    public MergeStatistics? Statistics { get; set; }
}

public class MergeStatistics
{
    public int FilesProcessed { get; set; }
    public int TablesFound { get; set; }
    public int DuplicatesRemoved { get; set; }
    public int OutputSize { get; set; }
}

public class SaveResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string? FilePath { get; set; }
}
