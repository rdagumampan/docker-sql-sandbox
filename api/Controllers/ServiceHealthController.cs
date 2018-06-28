using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace aspnet_core_dotnet_core.Controllers
{
    [Route("api/[controller]")]
    [ApiController]    
     public class ServiceHealthController : Controller
    {
         private readonly IServiceHealthRepository _serviceHealthRepository = new ServiceHealthRepository();
        private readonly IServiceHealthHistoryRepository _serviceHealthHistoryRepository = new ServiceHealthHistoryRepository();

        [HttpGet]
        public ActionResult<List<ServiceHealthDto>> Get()
        {
            var result = _serviceHealthRepository.All().ToList();
            var statuses = result.Select(i=> new ServiceHealthDto
            {
                ServiceId = i.ServiceId,
                ServiceName = i.ServiceName,
                Description = i.Description,
                Location = i.Location,
                LastPing = i.LastPing,
                LastStatus = i.LastStatus,
                AliveSince = (DateTime.UtcNow - i.LastPing).TotalSeconds
            }).ToList();

            return statuses;
        }

        [HttpPost] 
        public void Post([FromBody]ServiceHealthDto status)
        {
            var result = SaveStatus(status);
            SaveHistory(status);
        }

        private int SaveHistory(ServiceHealthDto status)
        {
            var service = new ServiceHealthDbModel
            {
                ServiceId = status.ServiceId,
                ServiceName = status.ServiceName,
                Description = status.Description,
                Location = status.Location,
                LastPing = DateTime.UtcNow,
                LastStatus = status.LastStatus
            };

            var rowsAffected = _serviceHealthHistoryRepository.Create(service);
            return rowsAffected;
        }

        private int SaveStatus(ServiceHealthDto status)
        {
            var service = _serviceHealthRepository
                        .All()
                        .FirstOrDefault(f => f.ServiceId == status.ServiceId);

            if (null != service)
            {
                service.LastPing = DateTime.UtcNow;
                service.LastStatus = status.LastStatus;
                _serviceHealthRepository.Update(service);
            }
            else
            {
                service = new ServiceHealthDbModel
                {
                    ServiceId = status.ServiceId,
                    ServiceName = status.ServiceName,
                    Description = status.Description,
                    Location = status.Location,
                    LastPing = DateTime.UtcNow,
                    LastStatus = status.LastStatus
                };
                _serviceHealthRepository.Create(service);
            }
            return 1;       
        }   
    }
}