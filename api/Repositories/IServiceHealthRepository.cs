
using System;
using System.Collections.Generic;

namespace aspnet_core_dotnet_core
{
    public interface IServiceHealthRepository
    {
        List<ServiceHealthDbModel> All();
        int Create(ServiceHealthDbModel status);
        int Update(ServiceHealthDbModel status);
    }

    public interface IServiceHealthHistoryRepository
    {
        int Create(ServiceHealthDbModel status);
    }

}
