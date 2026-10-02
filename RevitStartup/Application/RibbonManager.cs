using Autodesk.Revit.UI;
using Logger.Domain.Classes;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media.Imaging;

namespace RevitStartup.Application
{
    /// <summary>
    /// Class for generating Revit tab and panels
    /// </summary>
    public class RibbonManager
    {
        private static string ThisAssemblyDirectoryPath
        {
            get { return Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location); }
        }
        private static RibbonPanel _creationPanel;
        const string TabName = "TiverGroup";
        public static Result OnStartup(UIControlledApplication application)
        {
            
            try
            {
                application.CreateRibbonTab(TabName);
            }
            catch (Exception ex)
            {
                LoggerService.LogError(ex.ToString());
                Debug.WriteLine(ex.Message);
            }

            try
            {
                _creationPanel = application.CreateRibbonPanel(TabName, "test_template");
            }
            catch (Exception ex)
            {
                LoggerService.LogError(ex.ToString());
                Debug.WriteLine(ex.Message);
            }

            var button = new PushButtonData("ModuleButton", "Module One", 
                Path.Combine(ThisAssemblyDirectoryPath, "test_template.dll"), "test_template.Command.ModuleOneCommand");
            var button2 = new PushButtonData("ModuleWPFButton", "Module One", 
                Path.Combine(ThisAssemblyDirectoryPath, "test_templateWPF.dll"), "test_templateWPF.Command.ModuleOneCommand");

            /*string iconName = "test.png";
            var assembly = Assembly.GetExecutingAssembly();
            var stream = assembly.GetManifestResourceStream($"test_template.Resource.Icon.{iconName}");
            Bitmap img = new Bitmap(stream);
            button.LargeImage = ConvertFromImage(new Bitmap(img, 32, 32));
            button.Image = ConvertFromImage(new Bitmap(img, 16, 16));*/

            _creationPanel.AddItem(button);
            _creationPanel.AddItem(button2);

            return Result.Succeeded;
        }
        private static BitmapImage LoadIcon()
        {
            using var stream = Assembly.GetExecutingAssembly()
                .GetManifestResourceStream("RevitWorker.Resources.icon.png");

            var img = new BitmapImage();
            img.BeginInit();
            img.CacheOption = BitmapCacheOption.OnLoad;
            img.StreamSource = stream;
            img.EndInit();
            img.Freeze();
            return img;
        }

    }
}
