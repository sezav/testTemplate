using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using Logger.Domain.Classes;
using test_template.Domain.Classes;
using test_template.Domain.Services;
using SimpleInjector;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace test_template.Commands
{
    internal class ModuleDI
    {
        private readonly Container _container;

        public ModuleDI(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            _container = CreateServices(commandData, ref message, elements);
        }

        public void Run()
        {
            try
            {
                LoggerService.LogMessage("Запуск плагина");
                _container.GetInstance<Task1Doer>().DoLogic();
            }
            catch (Exception ex)
            {
                LoggerService.LogError(ex.Message);
                throw;
            }
        }


        private Container CreateServices(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            var uIapp = commandData?.Application;
            var uidoc = uIapp?.ActiveUIDocument;
            var doc = uidoc.Document;
            var app = uIapp?.Application;

            var container = new Container();


            var logPath = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "log", Assembly.GetExecutingAssembly().GetName().Name);
            Directory.CreateDirectory(logPath);
            LoggerService.Loggers.Add(new FileLogger(logPath));

            container.Register<UIApplication>(() => uIapp, Lifestyle.Singleton);
            container.Register<UIDocument>(() => uidoc, Lifestyle.Singleton);
            container.Register<Document>(() => doc, Lifestyle.Singleton);
            container.Register<Autodesk.Revit.ApplicationServices.Application>(() => app, Lifestyle.Singleton);

            container.Register<BaseClass>(() => new BaseClass("test1"), Lifestyle.Singleton);
            container.Register<Task1Doer>(Lifestyle.Singleton);
            return container;
        }
    }
}
