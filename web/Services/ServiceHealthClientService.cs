using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Net.Http;
using Newtonsoft.Json;

namespace aspnet_core_dotnet_core
{
    public interface IServiceHealthClientService
    {
        Task<List<ServiceHealthDto>> GetDataAsync();
    }

    public class ServiceHealthClientService: IServiceHealthClientService
    {
        public ServiceHealthClientService()
        {
        }

        public async Task<List<ServiceHealthDto>> GetDataAsync()
        {
            var results = new List<ServiceHealthDto>();

            string baseUrl = "";
            using (HttpClient client = new HttpClient())
            using (HttpResponseMessage response = await client.GetAsync(baseUrl))
            using (HttpContent content = response.Content)
            {
                string data = await content.ReadAsStringAsync();
                if (data != null)
                {
                    results = JsonConvert.DeserializeObject<List<ServiceHealthDto>>(data);
                }
            }

            return results.OrderBy(s=> s.ServiceName).ToList();
        }

    }
}
