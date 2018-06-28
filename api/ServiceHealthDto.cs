using System;

namespace aspnet_core_dotnet_core
{
    public class ServiceHealthDto
    {
        public string ServiceId { get; set; }
        public string ServiceName { get; set; }
        public string Description { get; set; }
        public string Location { get; set; }
        public string LastStatus { get; set; }
        public DateTime LastPing { get; set; }
        public double  AliveSince { get; set; }
    }
}