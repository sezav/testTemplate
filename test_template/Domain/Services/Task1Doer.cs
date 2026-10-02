using Autodesk.Revit.UI;
using test_template.Domain.Classes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace test_template.Domain.Services
{
    internal class Task1Doer
    {
        public Task1Doer(BaseClass bc)
        {
            this.bc = bc;
        }
        private BaseClass bc;
        internal void DoLogic()
        {
            TaskDialog.Show("Doing Logic", bc.text);
        }
    }
}
