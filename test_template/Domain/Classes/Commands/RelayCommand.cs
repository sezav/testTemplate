using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace test_template.Domain.Classes.Commands
{
    public class RelayCommand : ICommand
    {
        private Action<object> _execute { get; set; }
        private Predicate<object> _canExecute { get; set; }

        public event EventHandler CanExecuteChanged;

        public RelayCommand(Action<object> execute, Predicate<object> canExecute)
        {
            _execute = execute;
            _canExecute = canExecute;
        }

        public bool CanExecute(object parameter) { return _canExecute(parameter); }
        public void Execute(object parameter) { _execute(parameter); }

        public void RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);
    }

}
