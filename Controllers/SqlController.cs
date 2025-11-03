using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BlazorDataDev.Services;

namespace BlazorDataDev.Controllers;

[ApiController]
[Route("api/sql")]
[Authorize(Roles = "LoggedIn,Viewer,User,Editor,Admin")]
public class SqlController : ControllerBase
{
    private readonly ISqliteQueryService _queryService;
    private readonly ILogger<SqlController> _logger;

    public SqlController(ISqliteQueryService queryService, ILogger<SqlController> logger)
    {
        _queryService = queryService;
        _logger = logger;
    }

    /// <summary>
    /// Execute a read-only SQL query
    /// </summary>
    [HttpPost("execute")]
    public async Task<ActionResult<SqlExecutionResponse>> ExecuteQuery([FromBody] SqlExecutionRequest request)
    {
        try
        {
            // Validate query is read-only
            if (!_queryService.IsReadOnlyQuery(request.Query))
            {
                return BadRequest(new { error = "Only SELECT queries are allowed" });
            }

            var results = await _queryService.ExecuteQueryAsync(request.Query, request.Parameters);

            return Ok(new SqlExecutionResponse
            {
                Success = true,
                RowCount = results.Count,
                Data = results,
                ExecutedAt = DateTime.UtcNow
            });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid SQL operation");
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing SQL query");
            return StatusCode(500, new { error = "Error executing query", details = ex.Message });
        }
    }

    /// <summary>
    /// Get database status
    /// </summary>
    [HttpGet("status")]
    public ActionResult<object> GetStatus()
    {
        return Ok(new
        {
            status = "ready",
            message = "SQLite in-memory database is ready for queries",
            allowedOperations = new[] { "SELECT" },
            maxResultRows = 10000,
            queryTimeout = 30
        });
    }
}

public class SqlExecutionRequest
{
    public string Query { get; set; } = "";
    public Dictionary<string, object?>? Parameters { get; set; }
}

public class SqlExecutionResponse
{
    public bool Success { get; set; }
    public int RowCount { get; set; }
    public List<Dictionary<string, object?>> Data { get; set; } = new();
    public DateTime ExecutedAt { get; set; }
}
