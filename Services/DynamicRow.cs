namespace BlazorDataDev.Services
{
    /// <summary>
    /// Wrapper around Dictionary that provides type-safe access to row data
    /// Makes it feel like working with a typed class while keeping dynamic flexibility
    /// </summary>
    public class DynamicRow
    {
        private readonly Dictionary<string, object?> _data;
        private readonly List<ColumnInfo> _columns;

        public DynamicRow(Dictionary<string, object?> data, List<ColumnInfo> columns)
        {
            _data = data;
            _columns = columns;
        }

        /// <summary>
        /// Get a value with type safety
        /// Example: var name = row.Get<string>("ap_compressor");
        /// </summary>
        public T? Get<T>(string columnName)
        {
            if (!_data.ContainsKey(columnName))
            {
                throw new KeyNotFoundException($"Column '{columnName}' not found in row data");
            }

            var value = _data[columnName];
            
            // Handle NULL values
            if (value == null || value == DBNull.Value)
            {
                return default(T);
            }

            // Handle type conversion
            try
            {
                return (T)Convert.ChangeType(value, typeof(T));
            }
            catch (Exception ex)
            {
                throw new InvalidCastException(
                    $"Cannot convert column '{columnName}' value '{value}' to type {typeof(T).Name}", ex);
            }
        }

        /// <summary>
        /// Set a value with type checking
        /// Example: row.Set("ap_compressor", "Unit1");
        /// </summary>
        public void Set<T>(string columnName, T? value)
        {
            if (!_data.ContainsKey(columnName))
            {
                throw new KeyNotFoundException($"Column '{columnName}' not found in row data");
            }

            _data[columnName] = value;
        }

        /// <summary>
        /// Get raw value without type conversion (returns object?)
        /// </summary>
        public object? GetRaw(string columnName)
        {
            return _data.ContainsKey(columnName) ? _data[columnName] : null;
        }

        /// <summary>
        /// Check if a column exists
        /// </summary>
        public bool HasColumn(string columnName)
        {
            return _data.ContainsKey(columnName);
        }

        /// <summary>
        /// Check if a value is NULL
        /// </summary>
        public bool IsNull(string columnName)
        {
            var value = GetRaw(columnName);
            return value == null || value == DBNull.Value;
        }

        /// <summary>
        /// Get all column names in this row
        /// </summary>
        public IEnumerable<string> ColumnNames => _data.Keys;

        /// <summary>
        /// Get column metadata
        /// </summary>
        public ColumnInfo? GetColumnInfo(string columnName)
        {
            return _columns.FirstOrDefault(c => c.Name == columnName);
        }

        /// <summary>
        /// Get all columns metadata
        /// </summary>
        public List<ColumnInfo> Columns => _columns;

        /// <summary>
        /// Convert back to dictionary (for serialization, etc.)
        /// </summary>
        public Dictionary<string, object?> ToDictionary()
        {
            return new Dictionary<string, object?>(_data);
        }

        /// <summary>
        /// Indexer for quick access: row["column_name"]
        /// </summary>
        public object? this[string columnName]
        {
            get => GetRaw(columnName);
            set => _data[columnName] = value;
        }

        /// <summary>
        /// Get a formatted string representation of a value
        /// Handles dates, numbers, nulls nicely
        /// </summary>
        public string GetFormatted(string columnName)
        {
            var value = GetRaw(columnName);
            
            if (value == null || value == DBNull.Value)
                return "NULL";
            
            if (value is DateTime dt)
                return dt.ToString("yyyy-MM-dd HH:mm:ss");
            
            if (value is double d)
                return d.ToString("F2");
            
            if (value is float f)
                return f.ToString("F2");
            
            if (value is decimal dec)
                return dec.ToString("F2");
            
            return value.ToString() ?? "";
        }
    }
}
