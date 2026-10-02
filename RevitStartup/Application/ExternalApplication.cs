using Autodesk.Revit.Attributes;
using Autodesk.Revit.UI;
using Logger.Domain.Classes;
using System;
using System.IO;
using System.Reflection;

namespace RevitStartup.Application
{
    /// <summary>
    /// Class for running the application in Revit
    /// </summary>
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]
    public class ExternalApplication : IExternalApplication
    {
        public Result OnStartup(UIControlledApplication application)
        {

            var logPath = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "log", Assembly.GetExecutingAssembly().GetName().Name);
            Directory.CreateDirectory(logPath);
            LoggerService.Loggers.Add(new FileLogger(logPath));
            try
            {
                AppDomain.CurrentDomain.AssemblyResolve += OnResolveAssembly;
                RibbonManager.OnStartup(application);
                LoggerService.LogMessage("Запуск панели");
            }
            catch (Exception ex) 
            { 
                LoggerService.LogError(ex.ToString());
            }
            return Result.Succeeded;
        }

        public Result OnShutdown(UIControlledApplication application)
        {
            return Result.Succeeded;
        }

        public static Assembly OnResolveAssembly(object sender, ResolveEventArgs args)
        {
            string directoryDLLs = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

            if (args.Name.Contains(".resources"))
                return null;

            var assemblyName = new AssemblyName(args.Name).Name;

            return LoadAssemblyFromDirectory(directoryDLLs, assemblyName);
        }

        public static Assembly LoadAssemblyFromDirectory(string directory, string assemblyName)
        {
            try
            {
                string assemblyPath = Path.Combine(directory, assemblyName + ".dll");
                if (File.Exists(assemblyPath))
                {
                    return Assembly.LoadFrom(assemblyPath);
                }

                return null;
            }
            catch (Exception ex)
            {
                LoggerService.LogError(ex.ToString());
                System.Diagnostics.Debug.WriteLine($"Failed to load assembly {assemblyName}: {ex.Message}");
                return null;
            }
        }
    }


}
