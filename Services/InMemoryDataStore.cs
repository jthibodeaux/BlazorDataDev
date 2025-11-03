using System.Collections.Concurrent;

namespace BlazorDataDev.Services;

/// <summary>
/// In-memory data store for offline testing.
/// Stores table schemas and row data loaded from DDL and manual edits.
/// </summary>
public interface IInMemoryDataStore
{
    // Schema management
    void LoadSchema(string tableName, List<ColumnInfo> columns);
    List<string> GetTableNames();
    List<ColumnInfo>? GetTableSchema(string tableName);
    
    // Data management
    void AddRow(string tableName, Dictionary<string, object?> row);
    List<Dictionary<string, object?>> GetAllRows(string tableName);
    Dictionary<string, object?>? GetRow(string tableName, object id);
    bool UpdateRow(string tableName, object id, Dictionary<string, object?> row);
    bool DeleteRow(string tableName, object id);
    List<Dictionary<string, object?>> QueryRows(string tableName, Dictionary<string, object?> filters);
    
    // Utility
    void Clear();
    void ClearAll();
    int GetRowCount(string tableName);
}

public class InMemoryDataStore : IInMemoryDataStore
{
    private readonly ConcurrentDictionary<string, List<ColumnInfo>> _schemas = new();
    private readonly ConcurrentDictionary<string, ConcurrentDictionary<string, Dictionary<string, object?>>> _data = new();
    private readonly object _lock = new();

    public void LoadSchema(string tableName, List<ColumnInfo> columns)
    {
        _schemas[tableName] = columns;
        
        // Initialize data storage for this table if not exists
        if (!_data.ContainsKey(tableName))
        {
            _data[tableName] = new ConcurrentDictionary<string, Dictionary<string, object?>>();
        }
    }

    public List<string> GetTableNames()
    {
        return _schemas.Keys.OrderBy(k => k).ToList();
    }

    public List<ColumnInfo>? GetTableSchema(string tableName)
    {
        return _schemas.TryGetValue(tableName, out var schema) ? schema : null;
    }

    public void AddRow(string tableName, Dictionary<string, object?> row)
    {
        if (!_data.ContainsKey(tableName))
        {
            _data[tableName] = new ConcurrentDictionary<string, Dictionary<string, object?>>();
        }

        // Generate ID if not provided
        var idColumn = GetPrimaryKeyColumn(tableName);
        if (idColumn != null && !row.ContainsKey(idColumn))
        {
            row[idColumn] = GenerateId(tableName);
        }

        var id = row[idColumn ?? "id"]?.ToString() ?? Guid.NewGuid().ToString();
        _data[tableName][id] = row;
    }

    public List<Dictionary<string, object?>> GetAllRows(string tableName)
    {
        if (!_data.TryGetValue(tableName, out var tableData))
        {
            return new List<Dictionary<string, object?>>();
        }

        return tableData.Values.ToList();
    }

    public Dictionary<string, object?>? GetRow(string tableName, object id)
    {
        if (!_data.TryGetValue(tableName, out var tableData))
        {
            return null;
        }

        var idStr = id.ToString() ?? "";
        return tableData.TryGetValue(idStr, out var row) ? row : null;
    }

    public bool UpdateRow(string tableName, object id, Dictionary<string, object?> row)
    {
        if (!_data.TryGetValue(tableName, out var tableData))
        {
            return false;
        }

        var idStr = id.ToString() ?? "";
        if (!tableData.ContainsKey(idStr))
        {
            return false;
        }

        tableData[idStr] = row;
        return true;
    }

    public bool DeleteRow(string tableName, object id)
    {
        if (!_data.TryGetValue(tableName, out var tableData))
        {
            return false;
        }

        var idStr = id.ToString() ?? "";
        return tableData.TryRemove(idStr, out _);
    }

    public List<Dictionary<string, object?>> QueryRows(string tableName, Dictionary<string, object?> filters)
    {
        var allRows = GetAllRows(tableName);
        
        if (filters == null || !filters.Any())
        {
            return allRows;
        }

        // Apply AND logic for all filters
        return allRows.Where(row =>
        {
            foreach (var filter in filters)
            {
                if (!row.ContainsKey(filter.Key))
                {
                    return false;
                }

                var rowValue = row[filter.Key];
                var filterValue = filter.Value;

                // Handle null comparisons
                if (rowValue == null && filterValue == null)
                {
                    continue;
                }
                if (rowValue == null || filterValue == null)
                {
                    return false;
                }

                // Compare values (case-insensitive for strings)
                if (rowValue is string strValue && filterValue is string strFilter)
                {
                    if (!strValue.Equals(strFilter, StringComparison.OrdinalIgnoreCase))
                    {
                        return false;
                    }
                }
                else if (!rowValue.Equals(filterValue))
                {
                    return false;
                }
            }
            return true;
        }).ToList();
    }

    public void Clear()
    {
        _schemas.Clear();
        _data.Clear();
    }

    public void ClearAll()
    {
        _schemas.Clear();
        _data.Clear();
    }

    public int GetRowCount(string tableName)
    {
        if (_data.TryGetValue(tableName, out var tableData))
        {
            return tableData.Count;
        }
        return 0;
    }

    private string? GetPrimaryKeyColumn(string tableName)
    {
        var schema = GetTableSchema(tableName);
        return schema?.FirstOrDefault(c => c.IsPrimaryKey)?.Name ?? "id";
    }

    private object GenerateId(string tableName)
    {
        lock (_lock)
        {
            var existingIds = _data[tableName].Keys
                .Select(k => int.TryParse(k, out var num) ? num : 0)
                .Where(n => n > 0)
                .ToList();

            return existingIds.Any() ? existingIds.Max() + 1 : 1;
        }
    }
}
