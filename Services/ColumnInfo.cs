namespace BlazorDataDev.Services;

/// <summary>
/// Represents metadata about a database table column.
/// Used across the application for schema management, API responses, and data validation.
/// </summary>
public class ColumnInfo
{
    /// <summary>
    /// The name of the column
    /// </summary>
    public string Name { get; set; } = "";
    
    /// <summary>
    /// The data type of the column (e.g., varchar, int, timestamp)
  /// </summary>
    public string Type { get; set; } = "";
    
    /// <summary>
    /// Whether the column allows NULL values
    /// </summary>
    public bool Nullable { get; set; }
    
    /// <summary>
    /// The default value for the column, if any
    /// </summary>
    public string? DefaultValue { get; set; }
    
    /// <summary>
    /// Whether this column is a primary key
    /// </summary>
    public bool IsPrimaryKey { get; set; } = false;
    
    /// <summary>
    /// The name of the foreign key table, if this column is a foreign key
    /// </summary>
    public string? ForeignKeyTable { get; set; }
    
    /// <summary>
    /// The name of the foreign key column, if this column is a foreign key
    /// </summary>
    public string? ForeignKeyColumn { get; set; }
}
