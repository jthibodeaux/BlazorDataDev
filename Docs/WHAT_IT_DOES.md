# ?? TC Energy Data Platform - What It Actually Does

## **The Core Purpose (In One Sentence)**
**This platform acts as a PostgreSQL-compatible database server that runs in-memory, letting you load schemas/data offline and expose them via REST API for testing applications without needing a real database.**

---

## ?? **4 Primary Functions**

### **1. ?? Offline Database Server**
**What it does:** Acts like a PostgreSQL database but runs entirely in-memory with no actual database required.

**How it works:**
1. Load DDL files (CREATE TABLE statements)
2. Import data from CSV/JSON files
3. Platform creates in-memory SQLite database
4. Exposes full REST API with CRUD operations
5. Your application connects to the API instead of a real database

**Use case:** Test your application without connecting to production/staging databases.

---

### **2. ?? External Database Integration**
**What it does:** Connects to external PostgreSQL/Redshift databases to extract schemas and data for offline use.

**How it works:**
1. Connect to AWS Redshift or PostgreSQL
2. Browse available schemas and tables
3. Export DDL (CREATE TABLE statements)
4. Export sample data (CSV files, first 1000 rows)
5. Load exported files into offline database server
6. Test locally with real production schemas

**Use case:** Pull production schemas from AWS Redshift, test changes locally, then push back when ready.

---

### **3. ?? Data Management & Editing**
**What it does:** Provides web-based UI to manage tables and data like phpMyAdmin or pgAdmin.

**How it works:**
1. Browse all loaded tables
2. Add/edit/delete rows with forms
3. Import bulk data from CSV
4. Export data to CSV/JSON
5. Modify table schemas (add/remove columns)
6. Generate SQL migration scripts

**Use case:** Create test data for your application, modify schemas visually, export for sharing.

---

### **4. ?? Schema Migration & Comparison**
**What it does:** Compares database schemas between environments and generates migration scripts.

**How it works:**
1. Load schema from Development environment
2. Load schema from Production environment
3. Platform shows differences (missing tables, columns, indexes)
4. Generate ALTER TABLE statements to sync schemas
5. Apply migrations or export as SQL scripts

**Use case:** Keep Dev/Staging/Prod databases in sync, plan migrations safely.

---

## ?? **Key Features Breakdown**

### **Startup Wizard** (`/startup`)
- Automates loading DDL and CSV files on app start
- Configure which files to load from `Loadables/` folder
- JSON-based configuration (`startup-config.json`)
- One-click "Start Auto-Load" button

### **Schema Editor** (`/offline-editor`)
- Load DDL files
- View/edit table schemas
- Add/remove columns
- Generate SQL scripts
- Works entirely offline

### **Data Editor** (`/data-editor`)
- Browse all tables
- Add/edit/delete rows
- Import CSV/JSON data
- Export data to files
- Search and filter

### **External DB Explorer** (`/external-explorer`)
- Connect to PostgreSQL/Redshift
- Browse schemas and tables
- Export DDL, CSV, and metadata
- Save connection configs
- Bulk export multiple tables

### **SQL Query Tool** (`/sql-query`)
- Execute SQL queries against in-memory database
- Supports SELECT, INSERT, UPDATE, DELETE
- JOIN multiple tables
- Export query results
- Save favorite queries

### **REST API** (`/swagger`)
- Dynamic CRUD endpoints for all loaded tables
- Standard HTTP methods (GET, POST, PUT, DELETE)
- Query with filters, sorting, pagination
- JOIN operations
- Full Swagger documentation

---

## ?? **Common Use Cases**

### **Use Case 1: Testing Client Applications**
```
Developer Workflow:
1. Load production DDL into platform
2. Import sample data from CSV
3. Application connects to platform API
4. Test application without hitting real database
5. Make changes, reload data, test again
```

### **Use Case 2: Schema Development**
```
Database Developer Workflow:
1. Load current schema from DDL
2. Modify tables in Schema Editor
3. Test changes with sample data
4. Generate ALTER TABLE scripts
5. Apply to staging/production when ready
```

### **Use Case 3: AWS Redshift Extraction**
```
Data Engineer Workflow:
1. Connect to AWS Redshift cluster
2. Browse available schemas
3. Export tables (DDL + sample data)
4. Load into local platform
5. Test queries and transformations offline
6. Push changes back when validated
```

### **Use Case 4: API Development**
```
Backend Developer Workflow:
1. Load schema from DDL
2. Add test data via Data Editor
3. Generate REST API automatically
4. Frontend developer uses Swagger docs
5. Test API endpoints with realistic data
6. No database setup required
```

---

## ??? **Technical Architecture**

### **Core Components:**
```
???????????????????????????????????????????
?   Blazor Web UI (Server-Side)          ?
???????????????????????????????????????????
?   REST API Controllers          ?
?   - CRUD endpoints            ?
?   - Dynamic table operations             ?
???????????????????????????????????????????
?   Services Layer       ?
?   - InMemoryDataStore (holds table data)?
?   - SqliteQueryService (SQL engine)      ?
?   - DynamicDbService (schema management) ?
?   - ExternalDbExplorerService (AWS conn)?
???????????????????????????????????????????
?   Data Layer     ?
?   - In-Memory SQLite Database          ?
?   - JSON/CSV file storage    ?
???????????????????????????????????????????
```

### **Data Flow:**
```
DDL Files ? Schema Parser ? In-Memory Tables
CSV Files ? Data Importer ? In-Memory Rows
API Requests ? Query Engine ? In-Memory Results
UI Actions ? Service Layer ? Data Store ? UI Update
External DB ? Export ? Local Files ? Load
```

---

## ?? **What You DON'T Need**

? **No PostgreSQL installation required**  
? **No connection to production databases**  
? **No Docker containers**  
? **No cloud resources**  
? **No database credentials for testing**  

Everything runs locally in the .NET application process.

---

## ?? **Documentation Structure (Simplified)**

### **Essential Docs (Keep):**
1. **README.md** - Quick start guide (5 minutes to running)
2. **STARTUP_AUTOMATION_GUIDE.md** - How to configure auto-load
3. **EXTERNAL_DB_GUIDE.md** - Connecting to AWS/External DBs
4. **API_REFERENCE.md** - REST API endpoints

### **Reference Docs (Keep but simplify):**
5. **SCHEMA_MANAGEMENT.md** - DDL loading and editing
6. **DATA_IMPORT_EXPORT.md** - CSV/JSON operations
7. **MIGRATION_GUIDE.md** - Schema comparison and migrations

### **Technical Docs (For developers):**
8. **ARCHITECTURE.md** - How it works internally
9. **DEVELOPMENT_GUIDE.md** - Contributing and extending

### **Docs to Archive/Remove:**
- All the "FIX" and "SUMMARY" documents
- Step-by-step transformation guides
- Feature implementation details
- Should be in Git history, not user docs

---

## ?? **Quick Start (30 seconds)**

```bash
# 1. Run the app
dotnet run

# 2. Open browser
http://localhost:5000

# 3. Go to Startup Wizard
http://localhost:5000/startup

# 4. Click "Start Auto-Load"
# (Loads pre-configured DDL and CSV files)

# 5. View API
http://localhost:5000/swagger

# 6. Query your data
GET http://localhost:5000/api/tables/your_table/rows
```

**That's it!** No database setup, no configuration, just run and go.

---

## ?? **Key Benefits**

### **For Developers:**
- Test without database
- Realistic API for frontend development
- Safe experimentation with schemas
- Offline development capability

### **For QA/Testing:**
- Consistent test data across team
- Fast environment setup
- No dependency on shared databases
- Easy data reset (reload files)

### **For Data Engineers:**
- Extract production schemas safely
- Test transformations offline
- Generate migration scripts
- Compare schemas visually

### **For DevOps:**
- No database in CI/CD pipelines
- Fast integration tests
- Containerize just the app
- Simple deployment

---

## ?? **What Makes This Unique**

**Unlike traditional database tools:**
- No actual database required
- Schema and data are files (portable)
- REST API auto-generated from schema
- Full UI for management
- Connects to real databases to extract data

**It's like:**
- json-server (but for SQL databases)
- SQLite (but with REST API and UI)
- pgAdmin (but with API and offline mode)
- Postman (but serves data, not just requests)

---

## ?? **When to Use This Platform**

? **Use When:**
- Testing applications without database
- Developing against production-like schemas
- Need REST API for frontend development
- Comparing schemas between environments
- Creating test data sets
- Learning SQL without database setup
- CI/CD pipelines need data

? **Don't Use When:**
- Need actual production database
- Require millions of rows (in-memory limits)
- Need database-specific features (stored procedures, triggers)
- Need concurrent multi-user writes
- Require ACID guarantees for production

---

## ?? **Summary**

**This platform is:**
1. An **in-memory database server** that runs without PostgreSQL
2. A **REST API generator** for any schema you load
3. A **data management UI** like phpMyAdmin
4. An **external DB connector** to extract from AWS/Redshift
5. A **schema comparison tool** for migrations

**In simpler terms:**
*"Load DDL files, get instant REST API + database UI, test your app offline"*

---

**That's what it actually does!** ??

No fluff, no over-complicated explanations. Just a practical tool that solves real development problems.
