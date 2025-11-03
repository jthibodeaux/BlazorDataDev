namespace BlazorDbEditor.Services
{
    public interface ITableService
    {
        Task<List<string>> GetTablesAsync();
    }
}
