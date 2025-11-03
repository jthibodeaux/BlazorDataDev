# ColumnInfo Class Consolidation

## Overview

The `ColumnInfo` class has been consolidated into a single, shared definition to eliminate duplication and improve maintainability.

## Location

**File:** `Services/ColumnInfo.cs`  
**Namespace:** `BlazorDbEditor.Services`

## Purpose

The `ColumnInfo` class represents metadata about a database table column and is used throughout the application for:

- **Schema Management** - Storing and managing table structure information
- **API Responses** - Providing column metadata in REST API responses
- **Data Validation** - Validating data types and constraints
- **SQL Generation** - Creating DDL and DML statements
- **Date Detection** - Identifying date columns for date shifting features

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `Name` | `string` | The name of the column |
| `Type` | `string` | The data type (e.g., varchar, int, timestamp) |
| `Nullable` | `bool` | Whether the column allows NULL values |
| `DefaultValue` | `string?` | The default value for the column, if any |
| `IsPrimaryKey` | `bool` | Whether this column is a primary key |
| `ForeignKeyTable` | `string?` | The foreign key table name, if applicable |
| `ForeignKeyColumn` | `string?` | The foreign key column name, if applicable |

## Usage Across the Application

### 1. In-Memory Data Store
```csharp
// Storing schema information
DataStore.LoadSchema(tableName, List<ColumnInfo> columns);
List<ColumnInfo>? schema = DataStore.GetTableSchema(tableName);
```

### 2. SQLite Query Service
```csharp
// Loading schemas into SQLite
SqliteService.LoadSchema(Dictionary<string, List<ColumnInfo>> tableSchemas);
```

### 3. Dynamic Database Service
```csharp
// Fetching column information from PostgreSQL
List<ColumnInfo> columns = await DynamicDbService.GetColumnsAsync(tableName);
```

### 4. Offline Editor (Blazor Component)
```csharp
// Converting from internal ColumnDefinition to ColumnInfo
var columnInfos = tableSchemas[selectedTable].Select(c => new ColumnInfo
{
    Name = c.Name,
    Type = c.Type,
    Nullable = c.Nullable,
    IsPrimaryKey = c.Name.Equals("id", StringComparison.OrdinalIgnoreCase)
}).ToList();
```

### 5. Date Shift Utility
```csharp
// Detecting date columns from schema
List<string> dateColumns = DateShiftUtility.DetectDateColumns(List<ColumnInfo> schema);
```

### 6. API Controllers
```csharp
// Returning column metadata in API responses
var columns = DataStore.GetTableSchema(tableName);
return Ok(new { tableName, columns, rowCount });
```

## Benefits of Consolidation

### ? **Single Source of Truth**
- One definition ensures consistency across all modules
- Changes to the schema structure only need to be made in one place

### ? **Improved Maintainability**
- Easier to add new properties or modify existing ones
- Reduces risk of inconsistencies between different definitions

### ? **Better IntelliSense**
- IDE provides accurate autocomplete and documentation
- Easier for developers to discover available properties

### ? **Simplified Refactoring**
- Renaming or restructuring is straightforward
- Compilation errors immediately highlight all usages

### ? **Enhanced Documentation**
- Centralized XML comments explain the purpose of each property
- Easier to maintain and update documentation

## Migration Notes

### Before Consolidation
`ColumnInfo` was previously defined as a nested class inside:
- `DynamicDbService.cs` (namespace: `BlazorDbEditor.Services.DynamicDbService`)

### After Consolidation
`ColumnInfo` is now a standalone class in:
- `Services/ColumnInfo.cs` (namespace: `BlazorDbEditor.Services`)

### No Breaking Changes
Since the class remains in the same namespace (`BlazorDbEditor.Services`), no changes are required in consuming code. All existing references continue to work without modification.

## Related Classes

### ColumnDefinition (Internal to OfflineEditor)
The `OfflineEditor.razor` component maintains its own internal `ColumnDefinition` class for UI-specific needs:
- Includes an `IsNew` property to track newly added columns
- Used for schema editing and ALTER TABLE generation
- Converted to `ColumnInfo` when syncing to data store or SQLite

This is intentional and appropriate, as `ColumnDefinition` serves a different purpose than `ColumnInfo`.

## Future Enhancements

Potential additions to `ColumnInfo`:

- **MaxLength** - For varchar columns
- **Precision/Scale** - For numeric columns
- **IsUnique** - For unique constraints
- **CheckConstraints** - For validation rules
- **IsIndexed** - For index information
- **ComputedExpression** - For computed columns

## Testing

After consolidation, verify:
1. ? Build succeeds without errors
2. ? Offline Editor can load DDL files
3. ? Data can be imported and synced to data store
4. ? API endpoints return correct column metadata
5. ? SQLite queries work with loaded schemas
6. ? Date shifting detects date columns correctly

## Summary

The `ColumnInfo` class consolidation provides a clean, maintainable foundation for schema management across the entire application. This change improves code quality, reduces duplication, and makes future enhancements easier to implement.

---

**Consolidated in:** Version 2.1  
**Status:** ? Complete
