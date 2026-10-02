using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace Styles.UI.Styles
{
    /// <summary>
    /// Interaction logic for DesignTimeResources.xaml
    /// </summary>
    public partial class DesignTimeResources
    {
        public DesignTimeResources()
        {
            //InitializeComponent();
        }
        private void Border_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ChangedButton == MouseButton.Left)
            {
                Border border = sender as Border;
                Window window = border.Tag as Window;
                if (window != null)
                {
                    window.DragMove();
                }
            }
        }
    }
}
