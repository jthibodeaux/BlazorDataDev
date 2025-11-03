# Blazor DB Editor - REST API Mode

## Overview

The Blazor DB Editor now includes a **REST API mode** that exposes dynamic CRUD endpoints for all tables loaded in the Offline Editor. This allows you to test your client applications against modified database schemas without connecting to a live database.

## Key Features

- ✅ **Dynamic CRUD endpoints** - Automatically available for all loaded tables
- ✅ **In-memory data store** - Data persists during the application session
- ✅ **Swagger/OpenAPI documentation** - Interactive API testing interface
- ✅ **Schema metadata** - Get detailed table information including columns, types, and keys
- ✅ **Query with filters** - Search rows with multiple field comparisons (AND logic)
- ✅ **No database required** - Works completely offline

## Getting Started

### 1. Load Your DDL

1. Navigate to the **Offline Editor** page
2. Click "Load DDL File" and select your PostgreSQL DDL file
3. The tables and schemas are automatically loaded into the API

### 2. Add Test Data (Optional)

You can add test data in three ways:

- **Manual Entry**: Use the "Add Row" button in the Offline Editor
- **CSV Import**: Import CSV files exported from DBeaver
- **JSON Import**: Import JSON arrays of objects

All data is automatically synced to the API endpoints.

### 3. Access the API

The API is available at: `http://localhost:5000/api/tables`

Swagger documentation: `http://localhost:5000/swagger`

## API Endpoints

### Get All Tables

```http
GET /api/tables
```

**Response:**
```json
[
  "users",
  "orders",
  "products"
]
```

---

### Get Table Metadata

```http
GET /api/tables/{tableName}
```

**Example:** `GET /api/tables/users`

**Response:**
```json
{
  "tableName": "users",
  "columns": [
    {
      "name": "id",
      "type": "int",
      "nullable": false,
      "isPrimaryKey": true,
      "foreignKey": null
    },
    {
      "name": "username",
      "type": "varchar(255)",
      "nullable": false,
      "isPrimaryKey": false,
      "foreignKey": null
    },
    {
      "name": "email",
      "type": "varchar(255)",
      "nullable": true,
      "isPrimaryKey": false,
      "foreignKey": null
    }
  ],
  "rowCount": 5
}
```

---

### Get All Rows

```http
GET /api/tables/{tableName}/rows
```

**Example:** `GET /api/tables/users/rows`

**Response:**
```json
[
  {
    "id": "1",
    "username": "john_doe",
    "email": "john@example.com"
  },
  {
    "id": "2",
    "username": "jane_smith",
    "email": "jane@example.com"
  }
]
```

---

### Get Single Row by ID

```http
GET /api/tables/{tableName}/rows/{id}
```

**Example:** `GET /api/tables/users/rows/1`

**Response:**
```json
{
  "id": "1",
  "username": "john_doe",
  "email": "john@example.com"
}
```

---

### Create New Row

```http
POST /api/tables/{tableName}/rows
Content-Type: application/json

{
  "username": "new_user",
  "email": "newuser@example.com"
}
```

**Response:** `201 Created`
```json
{
  "id": "3",
  "username": "new_user",
  "email": "newuser@example.com"
}
```

**Note:** If you don't provide an ID, one will be auto-generated.

---

### Update Row

```http
PUT /api/tables/{tableName}/rows/{id}
Content-Type: application/json

{
  "id": "1",
  "username": "john_doe_updated",
  "email": "john.updated@example.com"
}
```

**Response:** `200 OK`
```json
{
  "id": "1",
  "username": "john_doe_updated",
  "email": "john.updated@example.com"
}
```

---

### Delete Row

```http
DELETE /api/tables/{tableName}/rows/{id}
```

**Example:** `DELETE /api/tables/users/rows/1`

**Response:** `204 No Content`

---

### Query Rows with Filters

```http
POST /api/tables/{tableName}/query
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com"
}
```

**Response:**
```json
[
  {
    "id": "1",
    "username": "john_doe",
    "email": "john@example.com"
  }
]
```

**Filter Logic:**
- All filters use **AND logic** (not OR)
- String comparisons are case-insensitive
- Empty filter object returns all rows

## Usage Examples

### Using cURL

```bash
# Get all tables
curl http://localhost:5000/api/tables

# Get table metadata
curl http://localhost:5000/api/tables/users

# Get all rows
curl http://localhost:5000/api/tables/users/rows

# Create a new row
curl -X POST http://localhost:5000/api/tables/users/rows \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user","email":"test@example.com"}'

# Query with filters
curl -X POST http://localhost:5000/api/tables/users/query \
  -H "Content-Type: application/json" \
  -d '{"username":"john_doe"}'
```

### Using JavaScript/Fetch

```javascript
// Get all tables
const tables = await fetch('http://localhost:5000/api/tables')
  .then(r => r.json());

// Get table metadata
const metadata = await fetch('http://localhost:5000/api/tables/users')
  .then(r => r.json());

// Create a new row
const newRow = await fetch('http://localhost:5000/api/tables/users/rows', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'test_user',
    email: 'test@example.com'
  })
}).then(r => r.json());

// Query with filters
const results = await fetch('http://localhost:5000/api/tables/users/query', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'john_doe'
  })
}).then(r => r.json());
```

### Using Python/Requests

```python
import requests

base_url = "http://localhost:5000/api/tables"

# Get all tables
tables = requests.get(base_url).json()

# Get table metadata
metadata = requests.get(f"{base_url}/users").json()

# Create a new row
new_row = requests.post(
    f"{base_url}/users/rows",
    json={"username": "test_user", "email": "test@example.com"}
).json()

# Query with filters
results = requests.post(
    f"{base_url}/users/query",
    json={"username": "john_doe"}
).json()
```

## Testing Workflow

### Recommended Testing Workflow

1. **Load DDL** - Import your database schema
2. **Add/Modify Columns** - Make schema changes in the Offline Editor
3. **Import Test Data** - Load CSV/JSON files or add rows manually
4. **Test API** - Use Swagger UI or your client application
5. **Iterate** - Make changes and test again
6. **Generate SQL** - Download migration scripts when ready

### Using Swagger UI

1. Navigate to `http://localhost:5000/swagger`
2. Expand any endpoint to see details
3. Click "Try it out" to test the endpoint
4. Fill in parameters and request body
5. Click "Execute" to see the response

## Data Persistence

- **In-Memory Storage**: Data is stored in memory during the application session
- **Session Scope**: Data persists until you restart the application
- **Workspace Save/Load**: Use the workspace feature to save your schemas and data

## Limitations

- **No OR Logic**: Query filters only support AND logic
- **No Complex Queries**: No JOIN, GROUP BY, or aggregate functions
- **No Transactions**: Each operation is independent
- **In-Memory Only**: Data is lost when the application restarts
- **String Comparisons**: All string comparisons are case-insensitive

## CORS Configuration

If you need to access the API from a different origin (e.g., a separate frontend application), you may need to enable CORS in `Program.cs`:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

// ...

app.UseCors("AllowAll");
```

## Troubleshooting

### API Returns Empty Results

- Make sure you've loaded a DDL file in the Offline Editor
- Check that you've added data (manually or via import)
- Verify the table name is correct (case-sensitive)

### Table Not Found

- Ensure the DDL has been parsed successfully
- Check the table name spelling
- Use `GET /api/tables` to see all available tables

### Data Not Syncing

- Make sure you're using the Offline Editor to add data
- Check the browser console for errors
- Restart the application and reload your workspace

## Architecture

```
┌─────────────────────────────────────────────────┐
│           Blazor Offline Editor                 │
│  (Load DDL, Add Columns, Import Data)           │
└────────────────┬────────────────────────────────┘
                 │
                 │ Syncs schemas & data
                 ▼
┌─────────────────────────────────────────────────┐
│         InMemoryDataStore (Singleton)           │
│  - Table schemas with column metadata           │
│  - Row data (Dictionary<string, object?>)       │
└────────────────┬────────────────────────────────┘
                 │
                 │ Serves data
                 ▼
┌─────────────────────────────────────────────────┐
│         TablesController (REST API)             │
│  - GET /api/tables                              │
│  - GET /api/tables/{name}                       │
│  - CRUD operations on rows                      │
│  - Query with filters                           │
└─────────────────────────────────────────────────┘
```

## Next Steps

- Test your client application against the API
- Add more test data as needed
- Modify schemas and test compatibility
- Generate migration scripts when ready
- Deploy to a real database

## Support

For issues or questions, please refer to the main README.md file.
