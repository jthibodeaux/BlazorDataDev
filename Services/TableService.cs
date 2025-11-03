namespace BlazorDbEditor.Services
{
    public class TableService : ITableService
    {
        private readonly IDynamicDbService _dynamicDb;

        public TableService(IDynamicDbService dynamicDb)
        {
            _dynamicDb = dynamicDb;
        }

        public async Task<List<string>> GetTablesAsync()
        {
            return await _dynamicDb.GetTablesAsync();
        }
    }
}
