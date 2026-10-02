using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using test_templateWPF.UI.Windows.MainWindow;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;
using static System.Net.Mime.MediaTypeNames;

namespace test_templateWPF.Command
{
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]
    public class DevModuleOneCommand : IExternalCommand
    {
        public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            MainWindowViewModel vm = new MainWindowViewModel();
            MainWindow mw = new MainWindow(vm);
            vm.Window = mw;
            mw.ShowDialog();
            return Result.Succeeded;
        }
    }
}
