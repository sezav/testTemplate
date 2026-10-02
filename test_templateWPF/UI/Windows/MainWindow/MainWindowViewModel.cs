using Autodesk.Revit.DB;
using test_templateWPF.Domain.Classes;
using test_templateWPF.Domain.Classes.Commands;
using test_templateWPF.Domain.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace test_templateWPF.UI.Windows.MainWindow
{
    public class MainWindowViewModel
    {
        public MainWindow Window;
        public MainWindowViewModel()
        {
            DoLogicCommand = new RelayCommand(DoLogic, CanExecute);
        }
        public RelayCommand DoLogicCommand { get; }
        private bool CanExecute(object obj)
        {
            return true;
        }

        private void DoLogic(object obj)
        {
            BaseClass bc = new BaseClass("Sample text");
            Task1Doer task1Doer = new Task1Doer(bc);
            task1Doer.DoLogic();
        }
    }
}
