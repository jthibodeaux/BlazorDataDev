# TC Energy Data Platform

> **In-memory PostgreSQL-compatible database server with REST API and web UI**

**Load schemas from AWS Redshift, test locally, deploy with confidence.**

---

## 🎯 What Is This?

A Blazor-based platform that:
1. **Extracts schemas** from AWS Redshift/PostgreSQL
2. **Loads them locally** into an in-memory database
3. **Exposes REST API** for your applications to test against
4. **Provides web UI** to manage data and schemas

**No PostgreSQL installation required.** Everything runs in-memory.

---

## 🚀 Quick Start (30 Seconds)

```bash
# 1. Run the application
dotnet run

# 2. Open in browser
http://localhost:5000

# 3. Use Startup Wizard
http://localhost:5000/startup
# Click "Start Auto-Load" to load pre-configured schemas

# 4. View API
http://localhost:5000/swagger
```

**Your app can now connect to:** `http://localhost:5000/api/tables/`

---

## 📋 Primary Workflow: AWS Redshift → Local Testing

### **Step 1: Extract from AWS Redshift**
```
1. Navigate to: External DB Explorer (/external-explorer)
2. Enter Redshift connection details
3. Browse schemas and tables
4. Select tables to export
5. Click "Export" → Creates DDL + sample data files
```

**Output:** `Loadables/external/{database}/ddls/*.sql`

### **Step 2: Load into Platform**
```
1. Navigate to: Startup Wizard (/startup)
2. Select the exported DDL files
3. Click "Load Selected Files"
4. Platform creates in-memory database
```

**Result:** Tables available via API and web UI

### **Step 3: Add Test Data (Optional)**
```
1. Navigate to: Data Editor (/data-editor)
2. Select a table
3. Import CSV or manually add rows
4. Data syncs to API automatically
```

### **Step 4: Test Your Application**
```
1. Point your app to: http://localhost:5000/api/
2. Use Swagger docs: http://localhost:5000/swagger
3. Available endpoints:
   - GET    /api/tables/{tableName}/rows
   - POST   /api/tables/{tableName}/rows
   - PUT    /api/tables/{tableName}/rows/{id}
   - DELETE /api/tables/{tableName}/rows/{id}
```

---

## 🔑 Key Features

### **🌐 External Database Explorer**
- Connect to AWS Redshift, PostgreSQL
- Browse schemas and tables
- Export DDL (CREATE TABLE statements)
- Export sample data (CSV, first 1000 rows)
- Bulk export multiple tables

### **🎭 In-Memory Database Server**
- No PostgreSQL installation needed
- SQLite backend (in-memory)
- Full SQL query support
- JOIN operations supported

### **🚀 REST API**
- Auto-generated CRUD endpoints
- Dynamic table operations
- Query with filters, sorting, pagination
- Full Swagger documentation

### **✏️ Data Management UI**
- Web-based table/data editor
- Import CSV/JSON files
- Export data to files
- Schema modifications
- SQL query interface

### **🔄 Schema Migration**
- Compare schemas between environments
- Generate ALTER TABLE scripts
- Migration planning

---

## 📊 Use Cases

### **1. Testing Applications Offline**
Extract production schemas from Redshift, load locally, test your application without connecting to live databases.

### **2. Schema Development**
Modify schemas in the UI, test changes with sample data, generate migration scripts when ready.

### **3. Frontend Development**
Backend developers export schemas, frontend developers use the REST API without needing database access.

### **4. CI/CD Integration**
Load schemas in CI pipelines, run integration tests against the in-memory API.

---

## 📁 Folder Structure

```
BlazorDbEditor/
├── Loadables/         # Data files directory
│   ├── ddls/    # DDL files (CREATE TABLE statements)
│   ├── csv/       # CSV data files
│   ├── json/        # JSON data files
│└── external/                 # Exported from external databases
│       └── {database_name}/
│           ├── ddls/      # Exported DDL files
│    ├── csv/              # Exported sample data
│        └── metadata/         # Table metadata (JSON)
│
├── startup-config.json     # Auto-load configuration
├── livedata-config.json          # Live data sync configuration
└── external-db-config.json       # Saved database connections
```

---

## 🛠️ Configuration

### **Auto-Load on Startup**
Edit `startup-config.json` to configure which files load automatically:

```json
{
  "autoLoadEnabled": true,
  "ddlFiles": [
    "Loadables/ddls/my_schema.sql"
  ],
  "csvFiles": [
    {
      "tableName": "users",
      "filePath": "Loadables/csv/users.csv"
    }
  ]
}
```

### **External Database Connection**
Connections saved in `external-db-config.json` (no passwords stored).

---

## 📚 Documentation

- **[Startup Automation Guide](Docs/STARTUP_AUTOMATION_GUIDE.md)** - Auto-load configuration
- **[External Database Guide](Docs/AWS_DATA_LOADING_GUIDE.md)** - Connecting to AWS Redshift
- **[Live Data Feature](Docs/LIVE_DATA_FEATURE.md)** - Real-time data sync
- **[DDL Cleanup Guide](Docs/DDL_CLEANUP_GUIDE.md)** - Preparing DDL files
- **[Flexible Folder Structure](Docs/FLEXIBLE_FOLDER_STRUCTURE.md)** - Loadables organization
- **[What It Does](Docs/WHAT_IT_DOES.md)** - Comprehensive feature overview

---

## 🔧 Technical Stack

- **.NET 8** - Runtime
- **Blazor Server** - Web UI framework
- **SQLite** - In-memory database engine
- **Npgsql** - PostgreSQL/Redshift connectivity
- **Dapper** - Data access
- **Swagger/OpenAPI** - API documentation

---

## 🚀 Advanced Features

### **SQL Query Tool** (`/sql-query`)
Execute SQL queries directly against loaded tables. Supports SELECT, INSERT, UPDATE, DELETE, and JOIN operations.

### **Migration Manager** (`/migration-manager`)
Compare schemas between environments, identify differences, generate ALTER TABLE scripts.

### **Live Data Sync** (`/live-data`)
Connect to real databases and sync data in real-time for testing scenarios.

---

## 📊 API Examples

### **Get All Tables**
```bash
GET http://localhost:5000/api/tables
```

### **Get Rows from Table**
```bash
GET http://localhost:5000/api/tables/users/rows?pageSize=10&pageNumber=1
```

### **Create Row**
```bash
POST http://localhost:5000/api/tables/users/rows
Content-Type: application/json

{
  "username": "john.doe",
  "email": "john@example.com"
}
```

### **Query with Filters**
```bash
POST http://localhost:5000/api/tables/users/query
Content-Type: application/json

{
  "filters": [
    { "column": "email", "operator": "LIKE", "value": "%@example.com" }
  ],
  "orderBy": "username",
  "pageSize": 10
}
```

---

## 🤝 Contributing

Contributions welcome! This is an internal TC Energy tool for database testing and development workflows.

---

## 📞 Support

- **Swagger API Docs:** http://localhost:5000/swagger
- **In-App Documentation:** http://localhost:5000/documentation
- **GitHub Repository:** [Your Repo URL]

---

## ⚡ Quick Tips

- **Startup Wizard** is the fastest way to get started
- **External DB Explorer** connects to AWS Redshift (requires VPN/network access)
- **Swagger UI** provides interactive API testing
- All data is **in-memory** - restart clears everything (unless auto-loaded)
- CSV files must match table column names exactly

---

**Version:** 2.0.0  
**Status:** Production Ready  
**License:** TC Energy Internal Use

---

## 🎯 TL;DR

```bash
# Extract from Redshift
/external-explorer → Connect → Export

# Load locally
/startup → Load DDL → Ready

# Test your app
http://localhost:5000/api/tables/your_table/rows
```

**That's it!** 🚀
