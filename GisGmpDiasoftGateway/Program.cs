using System;
using System.Linq;
using System.Reflection;
using System.ServiceProcess;
using GisGmpDiasoftGateway.Properties;
using NDesk.Options;

namespace GisGmpDiasoftGateway
{
    class Program
    {
        #region Fields

        private static Assembly[] includedLibraries = new Assembly[] 
        {
            Assembly.Load(Resources.NDesk_Options)
        };
        private static int interval = 5000;
        private static bool showHelp = false;
        #endregion // Fields
        

        static void Main(string[] args)
        {
            AppDomain.CurrentDomain.AssemblyResolve += AppDomain_AssemblyResolve;

            if (!ParseArgs(args)) { return; }

            ServiceBase.Run(new GisGmpService(interval));
        }


        private static Assembly AppDomain_AssemblyResolve(object sender, ResolveEventArgs args)
        {
            return includedLibraries.SingleOrDefault(w => w.FullName == args.Name);
        }

        private static bool ParseArgs(string[] args)
        {
            OptionSet optionsSet = new OptionSet()
                .Add(
                    "i|interval=",
                    "Интервал отправки сообщений (милисекунды).\nПо умолчанию 5000",
                    (v) => { interval = Convert.ToInt32(v); }
                )
                .Add(
                    "h|?|help",
                    "Это сообщение",
                    (v) => { showHelp = v != null; }
                );

            optionsSet.Parse(args);

            if (showHelp)
            {
                optionsSet.WriteOptionDescriptions(Console.Out);
                return false;
            }

            return true;
        }
    }
}
