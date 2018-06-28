using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using System.Net.Http;

namespace aspnet_core_dotnet_core.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            var serviceClient = new ServiceHealthClientService();
            var servicesHeatlth = serviceClient.GetDataAsync();

            var solution = new SolutionVm
            {
                Name = "D3A Services",
                Data = servicesHeatlth.Result
            };

            return View(solution);
        }

        public IActionResult About()
        {
            ViewData["Message"] = "Your application description page.";

            return View();
        }

        public IActionResult Contact()
        {
            ViewData["Message"] = "For comments and suggestions";

            return View();
        }

        public IActionResult Error()
        {
            return View();
        }
    }
}
