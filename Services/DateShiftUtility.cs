using System.Text.RegularExpressions;

namespace BlazorDataDev.Services;

/// <summary>
/// Utility for shifting dates in imported data to be relative to today
/// </summary>
public static class DateShiftUtility
{
    private static readonly string[] DateColumnPatterns = new[]
    {
        "date", "time", "timestamp", "created", "modified", "updated",
        "start", "end", "effective", "expire", "day", "month", "year"
    };

    /// <summary>
    /// Detect if a column name likely contains date/time data
    /// </summary>
    public static bool IsDateColumn(string columnName)
    {
        var lowerName = columnName.ToLower();
        return DateColumnPatterns.Any(pattern => lowerName.Contains(pattern));
    }

    /// <summary>
    /// Try to parse a value as a DateTime
    /// </summary>
    public static bool TryParseDateTime(object? value, out DateTime dateTime)
    {
        dateTime = DateTime.MinValue;

        if (value == null)
            return false;

        var stringValue = value.ToString();
        if (string.IsNullOrWhiteSpace(stringValue))
            return false;

        // Try standard DateTime parsing
        if (DateTime.TryParse(stringValue, out dateTime))
            return true;

        // Try ISO 8601 format (common in JSON)
        if (DateTime.TryParseExact(stringValue, new[]
        {
            "yyyy-MM-dd",
            "yyyy-MM-ddTHH:mm:ss",
            "yyyy-MM-ddTHH:mm:ss.fff",
            "yyyy-MM-ddTHH:mm:ss.fffZ",
            "yyyy-MM-dd HH:mm:ss",
            "MM/dd/yyyy",
            "MM/dd/yyyy HH:mm:ss"
        }, null, System.Globalization.DateTimeStyles.None, out dateTime))
        {
            return true;
        }

        return false;
    }

    /// <summary>
    /// Find the most recent date in a collection of rows
    /// </summary>
    public static DateTime? FindMostRecentDate(List<Dictionary<string, object?>> rows, List<string> dateColumns)
    {
        DateTime? maxDate = null;

        foreach (var row in rows)
        {
            foreach (var column in dateColumns)
            {
                if (row.TryGetValue(column, out var value) && TryParseDateTime(value, out var date))
                {
                    if (!maxDate.HasValue || date > maxDate.Value)
                    {
                        maxDate = date;
                    }
                }
            }
        }

        return maxDate;
    }

    /// <summary>
    /// Calculate the number of days to shift dates to make the most recent date equal to today
    /// </summary>
    public static int CalculateDayOffset(DateTime mostRecentDate)
    {
        var today = DateTime.Today;
        var daysDiff = (today - mostRecentDate.Date).Days;
        return daysDiff;
    }

    /// <summary>
    /// Shift all date columns in a row by the specified number of days
    /// </summary>
    public static void ShiftDatesInRow(Dictionary<string, object?> row, List<string> dateColumns, int dayOffset)
    {
        foreach (var column in dateColumns)
        {
            if (row.TryGetValue(column, out var value) && TryParseDateTime(value, out var date))
            {
                var shiftedDate = date.AddDays(dayOffset);
                
                // Preserve the original format if possible
                if (value?.ToString()?.Contains("T") == true)
                {
                    // ISO 8601 format
                    row[column] = shiftedDate.ToString("yyyy-MM-ddTHH:mm:ss");
                }
                else if (value?.ToString()?.Contains(":") == true)
                {
                    // DateTime with time
                    row[column] = shiftedDate.ToString("yyyy-MM-dd HH:mm:ss");
                }
                else
                {
                    // Date only
                    row[column] = shiftedDate.ToString("yyyy-MM-dd");
                }
            }
        }
    }

    /// <summary>
    /// Shift all dates in a collection of rows to be relative to today
    /// </summary>
    public static (List<Dictionary<string, object?>> shiftedRows, int dayOffset, DateTime? originalMaxDate) 
        ShiftDatesToToday(List<Dictionary<string, object?>> rows, List<string> dateColumns)
    {
        if (rows.Count == 0 || dateColumns.Count == 0)
        {
            return (rows, 0, null);
        }

        // Find the most recent date in the data
        var mostRecentDate = FindMostRecentDate(rows, dateColumns);
        if (!mostRecentDate.HasValue)
        {
            return (rows, 0, null);
        }

        // Calculate offset to shift to today
        var dayOffset = CalculateDayOffset(mostRecentDate.Value);

        // Shift all dates
        foreach (var row in rows)
        {
            ShiftDatesInRow(row, dateColumns, dayOffset);
        }

        return (rows, dayOffset, mostRecentDate.Value);
    }

    /// <summary>
    /// Detect date columns from a schema
    /// </summary>
    public static List<string> DetectDateColumns(List<ColumnInfo> schema)
    {
        var dateColumns = new List<string>();

        foreach (var column in schema)
        {
            // Check by data type
            var lowerType = column.Type.ToLower();
            if (lowerType.Contains("date") || 
                lowerType.Contains("time") || 
                lowerType.Contains("timestamp"))
            {
                dateColumns.Add(column.Name);
                continue;
            }

            // Check by column name
            if (IsDateColumn(column.Name))
            {
                dateColumns.Add(column.Name);
            }
        }

        return dateColumns;
    }

    /// <summary>
    /// Shift dates in SQL INSERT statements
    /// </summary>
    public static string ShiftDatesInSql(string sql, int dayOffset)
    {
        if (dayOffset == 0)
            return sql;

        // Pattern to match date literals in SQL
        // Matches: '2024-10-18', '2024-10-18 09:00:00', '2024-10-18T09:00:00'
        var datePattern = @"'(\d{4}-\d{2}-\d{2}(?:[T\s]\d{2}:\d{2}:\d{2}(?:\.\d{3})?)?)'";
        
        return Regex.Replace(sql, datePattern, match =>
        {
            var dateString = match.Groups[1].Value;
            if (TryParseDateTime(dateString, out var date))
            {
                var shiftedDate = date.AddDays(dayOffset);
                
                // Preserve format
                if (dateString.Contains("T"))
                {
                    return $"'{shiftedDate:yyyy-MM-ddTHH:mm:ss}'";
                }
                else if (dateString.Contains(":"))
                {
                    return $"'{shiftedDate:yyyy-MM-dd HH:mm:ss}'";
                }
                else
                {
                    return $"'{shiftedDate:yyyy-MM-dd}'";
                }
            }
            return match.Value;
        });
    }
}
