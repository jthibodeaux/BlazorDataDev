using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using BlazorDataDev.Services;

namespace BlazorDataDev.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // All endpoints require authentication
public class TablesController : ControllerBase
{
    private readonly IInMemoryDataStore _dataStore;
    private readonly ILogger<TablesController> _logger;

    public TablesController(IInMemoryDataStore dataStore, ILogger<TablesController> logger)
    {
        _dataStore = dataStore;
        _logger = logger;
    }

    /// <summary>
    /// Get list of all loaded table names
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "LoggedIn,Viewer,User,Editor,Admin")] // Anyone logged in can view
    [ProducesResponseType(typeof(List<string>), StatusCodes.Status200OK)]
    public ActionResult<List<string>> GetTables()
    {
        var tables = _dataStore.GetTableNames();
        return Ok(tables);
    }

    /// <summary>
    /// Get detailed metadata for a specific table
    /// </summary>
    [HttpGet("{tableName}")]
    [Authorize(Roles = "LoggedIn,Viewer,User,Editor,Admin")] // Anyone logged in can view
    [ProducesResponseType(typeof(TableMetadata), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<TableMetadata> GetTableMetadata(string tableName)
    {
        var schema = _dataStore.GetTableSchema(tableName);
        if (schema == null)
        {
            return NotFound(new { message = $"Table '{tableName}' not found" });
        }

        var metadata = new TableMetadata
        {
            TableName = tableName,
            Columns = schema.Select(c => new ColumnMetadata
            {
                Name = c.Name,
                Type = c.Type,
                Nullable = c.Nullable,
                IsPrimaryKey = c.IsPrimaryKey,
                ForeignKey = c.ForeignKeyTable != null ? new ForeignKeyInfo
                {
                    ReferencedTable = c.ForeignKeyTable,
                    ReferencedColumn = c.ForeignKeyColumn ?? "id"
                } : null
            }).ToList(),
            RowCount = _dataStore.GetRowCount(tableName)
        };

        return Ok(metadata);
    }

    /// <summary>
    /// Get all rows from a table with pagination
    /// </summary>
    [HttpGet("{tableName}/rows")]
    [Authorize(Roles = "LoggedIn,Viewer,User,Editor,Admin")] // Anyone logged in can view
    [ProducesResponseType(typeof(PaginatedResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<PaginatedResponse> GetRows(
        string tableName, 
        [FromQuery] int limit = 20, 
        [FromQuery] int offset = 0)
    {
        var schema = _dataStore.GetTableSchema(tableName);
        if (schema == null)
        {
            return NotFound(new { message = $"Table '{tableName}' not found" });
        }

        var allRows = _dataStore.GetAllRows(tableName);
        var totalCount = allRows.Count;
        var paginatedRows = allRows.Skip(offset).Take(limit).ToList();
        
        var response = new PaginatedResponse
        {
            Data = paginatedRows,
            TotalCount = totalCount,
            Limit = limit,
            Offset = offset,
            HasMore = (offset + limit) < totalCount
        };

        return Ok(response);
    }

    /// <summary>
    /// Get a single row by ID
    /// </summary>
    [HttpGet("{tableName}/rows/{id}")]
    [Authorize(Roles = "LoggedIn,Viewer,User,Editor,Admin")] // Anyone logged in can view
    [ProducesResponseType(typeof(Dictionary<string, object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<Dictionary<string, object?>> GetRowById(string tableName, string id)
    {
        var schema = _dataStore.GetTableSchema(tableName);
        if (schema == null)
        {
            return NotFound(new { message = $"Table '{tableName}' not found" });
        }

        var row = _dataStore.GetRow(tableName, id);
        if (row == null)
        {
            return NotFound(new { message = $"Row with id '{id}' not found in table '{tableName}'" });
        }

        return Ok(row);
    }

    /// <summary>
    /// Create a new row in a table
    /// </summary>
    [HttpPost("{tableName}/rows")]
    [Authorize(Roles = "Editor,Admin")] // Only editors and admins can create
    [ProducesResponseType(typeof(Dictionary<string, object?>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<Dictionary<string, object?>> CreateRow(string tableName, [FromBody] Dictionary<string, object?> row)
    {
        var schema = _dataStore.GetTableSchema(tableName);
        if (schema == null)
        {
            return NotFound(new { message = $"Table '{tableName}' not found" });
        }

        try
        {
            _dataStore.AddRow(tableName, row);
            
            // Get the ID that was assigned
            var pkColumn = schema.FirstOrDefault(c => c.IsPrimaryKey)?.Name ?? "id";
            var id = row.ContainsKey(pkColumn) ? row[pkColumn] : null;
            
            return CreatedAtAction(
                nameof(GetRowById),
                new { tableName, id = id?.ToString() },
                row
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating row in table {TableName}", tableName);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Update an existing row by ID
    /// </summary>
    [HttpPut("{tableName}/rows/{id}")]
    [Authorize(Roles = "Editor,Admin")] // Only editors and admins can update
    [ProducesResponseType(typeof(Dictionary<string, object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public ActionResult<Dictionary<string, object?>> UpdateRow(string tableName, string id, [FromBody] Dictionary<string, object?> row)
    {
        var schema = _dataStore.GetTableSchema(tableName);
        if (schema == null)
        {
            return NotFound(new { message = $"Table '{tableName}' not found" });
        }

        try
        {
            var success = _dataStore.UpdateRow(tableName, id, row);
            if (!success)
            {
                return NotFound(new { message = $"Row with id '{id}' not found in table '{tableName}'" });
            }

            return Ok(row);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating row {Id} in table {TableName}", id, tableName);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Delete a row by ID
    /// </summary>
    [HttpDelete("{tableName}/rows/{id}")]
    [Authorize(Roles = "Admin")] // Only admins can delete
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult DeleteRow(string tableName, string id)
    {
        var schema = _dataStore.GetTableSchema(tableName);
        if (schema == null)
        {
            return NotFound(new { message = $"Table '{tableName}' not found" });
        }

        var success = _dataStore.DeleteRow(tableName, id);
        if (!success)
        {
            return NotFound(new { message = $"Row with id '{id}' not found in table '{tableName}'" });
        }

        return NoContent();
    }    /// <summary>
    /// Query rows with filters (AND logic)
    /// </summary>
    [HttpPost("{tableName}/query")]
    [Authorize(Roles = "LoggedIn,Viewer,User,Editor,Admin")] // Anyone logged in can query
    [ProducesResponseType(typeof(List<Dictionary<string, object?>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<List<Dictionary<string, object?>>> QueryRows(
        string tableName,
        [FromBody] Dictionary<string, object?> filters)
    {
        var schema = _dataStore.GetTableSchema(tableName);
        if (schema == null)
        {
            return NotFound(new { message = $"Table '{tableName}' not found" });
        }

        var results = _dataStore.QueryRows(tableName, filters);
        return Ok(results);
    }

    /// <summary>
    /// Execute a JOIN query between two tables
    /// </summary>
    [HttpPost("query/join")]
    [Authorize(Roles = "LoggedIn,Viewer,User,Editor,Admin")] // Anyone logged in can query
    [ProducesResponseType(typeof(List<Dictionary<string, object?>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public ActionResult<List<Dictionary<string, object?>>> JoinQuery([FromBody] JoinQueryRequest request)
    {
        // Validate tables exist
        var leftSchema = _dataStore.GetTableSchema(request.LeftTable);
        var rightSchema = _dataStore.GetTableSchema(request.RightTable);
        
        if (leftSchema == null)
        {
            return NotFound(new { message = $"Table '{request.LeftTable}' not found" });
        }
        if (rightSchema == null)
        {
            return NotFound(new { message = $"Table '{request.RightTable}' not found" });
        }

        // Get all rows from both tables
        var leftRows = _dataStore.GetAllRows(request.LeftTable);
        var rightRows = _dataStore.GetAllRows(request.RightTable);

        var results = new List<Dictionary<string, object?>>();

        // Perform JOIN
        foreach (var leftRow in leftRows)
        {
            var leftValue = leftRow.ContainsKey(request.LeftColumn) ? leftRow[request.LeftColumn] : null;
            
            foreach (var rightRow in rightRows)
            {
                var rightValue = rightRow.ContainsKey(request.RightColumn) ? rightRow[request.RightColumn] : null;
                
                // Check if values match
                bool match = (leftValue == null && rightValue == null) || 
                            (leftValue != null && leftValue.Equals(rightValue));
                
                if (match || (request.JoinType == "LEFT" && leftValue != null))
                {
                    var joinedRow = new Dictionary<string, object?>();
                    
                    // Add left table columns with prefix
                    foreach (var kvp in leftRow)
                    {
                        joinedRow[$"{request.LeftTable}.{kvp.Key}"] = kvp.Value;
                    }
                    
                    // Add right table columns with prefix (or NULL for LEFT JOIN with no match)
                    if (match)
                    {
                        foreach (var kvp in rightRow)
                        {
                            joinedRow[$"{request.RightTable}.{kvp.Key}"] = kvp.Value;
                        }
                    }
                    else if (request.JoinType == "LEFT")
                    {
                        foreach (var column in rightSchema)
                        {
                            joinedRow[$"{request.RightTable}.{column.Name}"] = null;
                        }
                    }
                    
                    results.Add(joinedRow);
                    
                    // For INNER JOIN, only one match per left row
                    if (match && request.JoinType == "INNER") break;
                }
            }
        }

        return Ok(results);
    }
}///TOs for API responses
public class TableMetadata
{
    public string TableName { get; set; } = "";
    public List<ColumnMetadata> Columns { get; set; } = new();
    public int RowCount { get; set; }
}

public class ColumnMetadata
{
    public string Name { get; set; } = "";
    public string Type { get; set; } = "";
    public bool Nullable { get; set; }
    public bool IsPrimaryKey { get; set; }
    public ForeignKeyInfo? ForeignKey { get; set; }
}

public class ForeignKeyInfo
{
    public string ReferencedTable { get; set; } = "";
    public string ReferencedColumn { get; set; } = "";
}

public class PaginatedResponse
{
    public List<Dictionary<string, object?>> Data { get; set; } = new();
    public int TotalCount { get; set; }
    public int Limit { get; set; }
    public int Offset { get; set; }
    public bool HasMore { get; set; }
}

public class JoinQueryRequest
{
    public string LeftTable { get; set; } = "";
    public string LeftColumn { get; set; } = "";
    public string RightTable { get; set; } = "";
    public string RightColumn { get; set; } = "";
    public string JoinType { get; set; } = "INNER"; // INNER or LEFT
}
