namespace BlazorDataDev.Services
{
    public interface ITableService
    {
        Task<List<string>> GetTablesAsync();
    }
}
