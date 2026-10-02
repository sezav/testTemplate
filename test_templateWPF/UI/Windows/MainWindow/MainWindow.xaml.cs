using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace test_templateWPF.UI.Windows.MainWindow
{
    /// <summary>
    /// Логика взаимодействия для MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private MainWindowViewModel _vm;
        public MainWindow(MainWindowViewModel model)
        {
            _vm = model;
            
            var assembly = Assembly.GetExecutingAssembly();
            Title = assembly.GetName().Name.ToString() + " " + assembly.GetName().Version;
            InitializeComponent();
        }
    }
}
