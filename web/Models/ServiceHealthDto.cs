using System;
using System.Collections.Generic;

namespace aspnet_core_dotnet_core
{
    public class ServiceHealthDto
    {
        public string ServiceId { get; set; }
        public string ServiceName { get; set; }
        public string Description { get; set; }
        public DateTime LastPing { get; set; }
        public string Location { get; set; }
        public string LastStatus { get; set; }
        public double AliveSince { get; set; }
    }

    public class SolutionVm
    {
        public string Name { get; set; }
        public List<ServiceHealthDto> Data { get; set; } = new List<ServiceHealthDto>();
    }

    public class ServiceHealthVm
    {
        public string ServiceId { get; set; }
        public string ServiceName { get; set; }
        public string Description { get; set; }
        public DateTime LastPing { get; set; }
        public string LastLocation { get; set; }
        public double AliveSince { get; set; }
        public string LastStatus { get; set; }
    }

}