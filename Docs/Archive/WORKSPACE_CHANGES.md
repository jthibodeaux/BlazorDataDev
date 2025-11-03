# Workspace Save/Load Changes

## 🎯 What Changed

The workspace save/load functionality has been **restructured** to separate schema from data, making files cleaner, more readable, and easier to version control.

---

## **Before vs After**

### **Before (Old Format)**
```json
{
  "DdlContent": "CREATE TABLE...",
  "TableSchemas": { ... },
  "OriginalSchemas": { ... },
  "GeneratedSQL": "INSERT INTO ... (1000+ lines)",  // ❌ Huge
  "SelectedTable": "users",
  "ScriptAlterCount": 5,
  "ScriptRowCount": 1037
}
```

**Problems:**
- ❌ Huge files with thousands of INSERT statements
- ❌ Hard to read and diff
- ❌ Mixes schema with data
- ❌ Not version control friendly

---

### **After (New Format)**
```json
{
  "DdlContent": "CREATE TABLE...",
  "TableSchemas": { ... },
  "OriginalSchemas": { ... },
  "SelectedTable": "users",
  "SavedAt": "2025-01-15T10:30:00",
  "TableCount": 17
}
```

**Benefits:**
- ✅ Clean, readable JSON (indented)
- ✅ Only schema and settings
- ✅ Small file size
- ✅ Version control friendly
- ✅ Reusable across environments

---

## **New Workflow**

### **Saving Work**

1. **Save Workspace** → Saves `workspace_YYYYMMDD_HHMMSS.json`
   - DDL content
   - Table schemas
   - Original schemas
   - Selected table
   - Metadata (timestamp, table count)
   - **NO generated SQL**

2. **Download Script** → Saves generated SQL separately
   - All INSERT statements
   - All ALTER statements
   - Ready to execute

### **Loading Work**

1. **Load Workspace** → Loads schema and settings
   - Restores DDL
   - Restores table schemas
   - **Does NOT load data**
   - Status message: "Workspace loaded successfully! (17 tables found, saved at 2025-01-15 10:30:00). Import data separately if needed."

2. **Import Data** (Optional) → Import CSV/JSON if needed
   - Use "Import Data" button
   - Auto-detects table name from JSON
   - Adds to generated SQL

---

## **Use Cases**

### **Use Case 1: Schema-Only Work**

**Scenario:** You want to modify table schemas without data.

**Workflow:**
1. Load DDL
2. Modify schemas (add/remove columns)
3. Save workspace
4. Download ALTER script
5. Share workspace file with team

**Result:** Clean, small workspace file with just schema changes.

---

### **Use Case 2: Schema + Data Testing**

**Scenario:** You want to test with sample data.

**Workflow:**
1. Load workspace (schema only)
2. Import CSV/JSON data
3. Test via API
4. Download INSERT script separately
5. Don't save workspace again (keeps it clean)

**Result:** Workspace stays clean, data is separate.

---

### **Use Case 3: Version Control**

**Scenario:** You want to track schema changes in Git.

**Workflow:**
1. Load DDL
2. Modify schemas
3. Save workspace
4. Commit `workspace_*.json` to Git
5. Team members can load and see changes

**Result:** Readable diffs in Git, no noise from INSERT statements.

---

## **File Structure**

### **Workspace File** (workspace_20250115_103000.json)
```json
{
  "DdlContent": "CREATE TABLE users (\n  id serial PRIMARY KEY,\n  name varchar(100)\n);",
  "TableSchemas": {
    "users": [
      {
        "Name": "id",
        "DataType": "serial",
        "IsNullable": false,
        "IsPrimaryKey": true,
        "IsNew": false
      },
      {
        "Name": "name",
        "DataType": "varchar(100)",
        "IsNullable": true,
        "IsPrimaryKey": false,
        "IsNew": false
      }
    ]
  },
  "OriginalSchemas": {
    "users": [ /* same structure */ ]
  },
  "SelectedTable": "users",
  "SavedAt": "2025-01-15T10:30:00",
  "TableCount": 1
}
```

**Formatted with indentation** for readability!

---

### **Generated SQL File** (separate)

Use "Download Script" button to save:

```sql
-- Generated SQL Script
-- Generated at: 2025-01-15 10:30:00

-- ALTER Statements (5)
ALTER TABLE users ADD COLUMN email varchar(255);
ALTER TABLE users ADD COLUMN created_at timestamp;

-- INSERT Statements (1037)
INSERT INTO users (id, name, email) VALUES (1, 'John', 'john@example.com');
INSERT INTO users (id, name, email) VALUES (2, 'Jane', 'jane@example.com');
...
```

---

## **Migration Guide**

### **If You Have Old Workspace Files**

Old workspace files with `GeneratedSQL` will still load, but:

1. The `GeneratedSQL` field will be **ignored**
2. You'll see: "Workspace loaded successfully! (17 tables found). Import data separately if needed."
3. Import your data again via CSV/JSON if needed

### **Recommended Action**

1. Load your old workspace
2. Save it again → Creates new clean format
3. Delete old workspace file
4. Use new format going forward

---

## **Benefits Summary**

| Feature | Before | After |
|---------|--------|-------|
| **File Size** | Large (MBs) | Small (KBs) |
| **Readability** | Poor (minified) | Excellent (indented) |
| **Version Control** | Noisy diffs | Clean diffs |
| **Separation** | Mixed | Clean separation |
| **Reusability** | Limited | High |
| **Load Time** | Slow | Fast |

---

## **Technical Details**

### **WorkspaceData Class (New)**

```csharp
private class WorkspaceData
{
    public string DdlContent { get; set; } = "";
    public Dictionary<string, List<ColumnDefinition>> TableSchemas { get; set; } = new();
    public Dictionary<string, List<ColumnDefinition>> OriginalSchemas { get; set; } = new();
    public string SelectedTable { get; set; } = "";
    public DateTime SavedAt { get; set; } = DateTime.Now;
    public int TableCount { get; set; }
}
```

**Removed:**
- `GeneratedSQL` (was storing huge INSERT blocks)
- `ScriptAlterCount` (can be calculated)
- `ScriptRowCount` (can be calculated)

**Added:**
- `SavedAt` (timestamp for tracking)
- `TableCount` (quick metadata)

---

### **Serialization**

```csharp
var json = JsonSerializer.Serialize(workspace, new JsonSerializerOptions { 
    WriteIndented = true  // ✅ Formatted with indentation
});
```

---

## **FAQ**

### **Q: What happens to my generated SQL?**

**A:** Use the "Download Script" button to save it separately. The workspace no longer stores it.

---

### **Q: Can I still import data?**

**A:** Yes! Use the "Import Data" button to import CSV/JSON after loading a workspace.

---

### **Q: Will old workspace files still work?**

**A:** Yes, they'll load but the `GeneratedSQL` field will be ignored. Re-save to get the new format.

---

### **Q: How do I share schemas with my team?**

**A:** Save workspace, commit to Git, team loads workspace, imports their own test data.

---

### **Q: Can I version control the workspace file?**

**A:** Yes! The new format is clean, indented JSON that works great with Git.

---

## **Example Workflow**

```bash
# 1. Load DDL and modify schemas
# 2. Save workspace
→ Downloads: workspace_20250115_103000.json (5 KB)

# 3. Import test data
# 4. Download generated SQL
→ Downloads: generated_script_20250115_103000.sql (500 KB)

# 5. Commit workspace to Git
git add workspace_20250115_103000.json
git commit -m "Added email column to users table"

# 6. Team member loads workspace
# 7. Team member imports their own test data
# 8. Team member tests via API
```

---

## **Conclusion**

The new workspace format is:
- ✅ **Cleaner** - No huge INSERT blocks
- ✅ **Readable** - Indented JSON
- ✅ **Smaller** - KBs instead of MBs
- ✅ **Reusable** - Share schemas easily
- ✅ **Git-friendly** - Clean diffs

Use "Download Script" to save generated SQL separately when needed!
