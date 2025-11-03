# Blazor DB Editor - Enhanced Features

## 🎉 What's New

This release adds powerful new features that transform the Blazor DB Editor into a complete **staged database server** for testing and development.

---

## ✨ New Features

### 1. **Modern Landing Page**

Beautiful, card-based landing page with:
- Quick navigation to all features
- Feature overview and descriptions
- Direct links to Swagger API documentation
- Visual hierarchy with gradient hero section

**Access:** `http://localhost:5000/`

---

### 2. **Pagination Support**

REST API now supports pagination for large datasets:

**Endpoint:** `GET /api/tables/{tableName}/rows?limit=20&offset=0`

**Parameters:**
- `limit` (default: 20) - Number of rows to return
- `offset` (default: 0) - Number of rows to skip

**Response:**
```json
{
  "data": [ /* array of rows */ ],
  "totalCount": 1000,
  "limit": 20,
  "offset": 0,
  "hasMore": true
}
```

**Example:**
```bash
# Get first 20 rows
curl "http://localhost:5000/api/tables/users/rows?limit=20&offset=0"

# Get next 20 rows
curl "http://localhost:5000/api/tables/users/rows?limit=20&offset=20"
```

---

### 3. **Data Editor UI**

Brand new page for viewing and editing data with a beautiful UI:

**Features:**
- ✅ Browse all loaded tables
- ✅ View data in paginated tables
- ✅ **Add new rows** with modal form
- ✅ **Edit existing rows** inline
- ✅ **Delete rows** with one click
- ✅ Real-time row count display
- ✅ Pagination controls (Previous/Next)

**Access:** `http://localhost:5000/data-editor`

**How to Use:**
1. Select a table from the left sidebar
2. Click "Add Row" to insert new data
3. Click the pencil icon (✏️) to edit a row
4. Click the trash icon (🗑️) to delete a row
5. Use Previous/Next buttons to navigate pages

---

### 4. **JOIN Query Support** 🔥

Execute JOIN queries between tables via REST API:

**Endpoint:** `POST /api/tables/query/join`

**Request Body:**
```json
{
  "leftTable": "orders",
  "leftColumn": "customer_id",
  "rightTable": "customers",
  "rightColumn": "id",
  "joinType": "INNER"
}
```

**Join Types:**
- `INNER` - Returns only matching rows
- `LEFT` - Returns all left table rows, with NULLs for non-matching right table rows

**Response:**
```json
[
  {
    "orders.id": "1",
    "orders.customer_id": "100",
    "orders.amount": "250.00",
    "customers.id": "100",
    "customers.name": "John Doe",
    "customers.email": "john@example.com"
  }
]
```

**Example:**
```bash
curl -X POST http://localhost:5000/api/tables/query/join \
  -H "Content-Type: application/json" \
  -d '{
    "leftTable": "orders",
    "leftColumn": "customer_id",
    "rightTable": "customers",
    "rightColumn": "id",
    "joinType": "INNER"
  }'
```

**Use Cases:**
- Test client applications with related data
- Verify foreign key relationships
- Simulate database JOINs without a live database
- Prototype complex queries

---

## 🚀 Complete Feature List

### **Offline Editor**
- Load PostgreSQL DDL files
- Add/remove columns dynamically
- Import CSV/JSON data
- Preview data before importing
- Generate SQL migration scripts
- Save/load workspaces

### **Data Editor** (NEW)
- Browse all tables
- Add/edit/delete rows
- Pagination support
- Modal forms for data entry
- Real-time updates

### **Migration Manager**
- Load multiple DDL snapshots
- Compare schemas across environments
- Generate ALTER statements
- Track schema changes

### **REST API**
- `GET /api/tables` - List all tables
- `GET /api/tables/{name}` - Get table metadata
- `GET /api/tables/{name}/rows` - Get rows (with pagination)
- `GET /api/tables/{name}/rows/{id}` - Get single row
- `POST /api/tables/{name}/rows` - Create row
- `PUT /api/tables/{name}/rows/{id}` - Update row
- `DELETE /api/tables/{name}/rows/{id}` - Delete row
- `POST /api/tables/{name}/query` - Query with filters
- `POST /api/tables/query/join` - JOIN two tables (NEW)

### **Swagger Documentation**
- Interactive API testing
- Request/response schemas
- Try endpoints directly in browser
- OpenAPI specification

---

## 📖 Usage Examples

### **Example 1: Load DDL and Add Data**

1. Go to **Offline Editor** (`/offline-editor`)
2. Click "Load DDL File" and select your PostgreSQL DDL
3. Select a table from the sidebar
4. Click "Add New Row" and fill in the form
5. Data is automatically available via API

### **Example 2: Edit Data via UI**

1. Go to **Data Editor** (`/data-editor`)
2. Select a table from the left sidebar
3. Click the pencil icon (✏️) next to any row
4. Modify the values in the modal
5. Click "Update" to save changes

### **Example 3: Test JOIN Queries**

1. Load DDL with related tables (e.g., `orders` and `customers`)
2. Add data to both tables
3. Use Swagger UI (`/swagger`) to test the JOIN endpoint
4. Or use cURL:

```bash
curl -X POST http://localhost:5000/api/tables/query/join \
  -H "Content-Type: application/json" \
  -d '{
    "leftTable": "orders",
    "leftColumn": "customer_id",
    "rightTable": "customers",
    "rightColumn": "id",
    "joinType": "LEFT"
  }'
```

### **Example 4: Paginate Large Datasets**

```javascript
// JavaScript example
async function fetchAllData(tableName) {
  const limit = 20;
  let offset = 0;
  let allData = [];
  let hasMore = true;

  while (hasMore) {
    const response = await fetch(
      `http://localhost:5000/api/tables/${tableName}/rows?limit=${limit}&offset=${offset}`
    );
    const result = await response.json();
    
    allData = allData.concat(result.data);
    hasMore = result.hasMore;
    offset += limit;
  }

  return allData;
}
```

---

## 🎯 Typical Workflow

1. **Load Schema**
   - Open Offline Editor
   - Load your PostgreSQL DDL file
   - Tables appear in sidebar

2. **Add Test Data**
   - Use Data Editor to add rows manually
   - Or import CSV/JSON files in Offline Editor
   - Data syncs automatically to API

3. **Test Your Client**
   - Use Swagger UI to explore endpoints
   - Test CRUD operations
   - Test JOIN queries
   - Test pagination

4. **Iterate**
   - Modify schemas in Offline Editor
   - Add/edit/delete data in Data Editor
   - Re-test your client application

5. **Generate SQL**
   - Download migration scripts from Offline Editor
   - Apply to your real database when ready

---

## 🔧 Technical Details

### **Architecture**

```
┌─────────────────────────────────────────┐
│         Blazor Pages (UI)               │
│  - Index (Landing)                      │
│  - Offline Editor (DDL + Data)          │
│  - Data Editor (CRUD UI)                │
│  - Migration Manager (Schema Compare)   │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│    InMemoryDataStore (Singleton)        │
│  - Table schemas (ColumnInfo)           │
│  - Row data (Dictionary)                │
│  - CRUD operations                      │
│  - Query with filters                   │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│      TablesController (REST API)        │
│  - GET/POST/PUT/DELETE endpoints        │
│  - Pagination support                   │
│  - JOIN query support                   │
│  - Swagger documentation                │
└─────────────────────────────────────────┘
```

### **Data Flow**

1. **DDL Loading** → Parses schema → Stores in `InMemoryDataStore`
2. **Data Import** → Parses CSV/JSON → Stores rows in `InMemoryDataStore`
3. **API Requests** → Reads from `InMemoryDataStore` → Returns JSON
4. **UI Edits** → Updates `InMemoryDataStore` → Reflects in API immediately

### **Key Components**

- **InMemoryDataStore.cs** - Singleton service for data storage
- **TablesController.cs** - REST API endpoints
- **OfflineEditor.razor** - DDL loading and data import
- **DataEditor.razor** - CRUD UI for data management
- **Index.razor** - Landing page with navigation

---

## 🐛 Known Limitations

- **JOIN Performance:** O(n*m) complexity - not optimized for large datasets
- **No Transactions:** Each operation is independent
- **No Complex Queries:** No GROUP BY, aggregates, or subqueries
- **In-Memory Only:** Data lost on restart (use workspace save/load)
- **String Comparisons:** Case-insensitive in query filters

---

## 🚀 Future Enhancements

Potential features for future releases:
- [ ] Save/restore API data in workspace files
- [ ] Support for RIGHT and FULL OUTER JOINs
- [ ] Query builder UI for complex filters
- [ ] Export data to CSV/JSON
- [ ] Import SQL INSERT statements directly
- [ ] Real-time collaboration features
- [ ] Database connection for live testing

---

## 📝 Changelog

### Version 2.0 (Current)

**Added:**
- Modern landing page with navigation cards
- Pagination support for API endpoints
- Data Editor UI with add/edit/delete functionality
- JOIN query support (INNER and LEFT)
- Enhanced Swagger documentation

**Fixed:**
- Duplicate `ColumnInfo` class definition
- Workspace loading now syncs schemas to API
- Navigation menu updated with Data Editor link

**Improved:**
- API response structure with pagination metadata
- Error handling in CRUD operations
- UI/UX with Bootstrap modals and icons

---

## 🤝 Contributing

This is a development tool. Feel free to extend it with:
- Additional JOIN types (RIGHT, FULL OUTER)
- Query optimization
- More complex filter logic
- Export/import features
- Database connection pooling

---

## 📄 License

MIT License - Use freely for development and testing.

---

## 🎉 Happy Testing!

You now have a complete **staged database server** for testing client applications without needing a live database connection. Load your schemas, add test data, and start testing via REST API or the UI.

For questions or issues, refer to the main `README.md` or `API_README.md` files.
