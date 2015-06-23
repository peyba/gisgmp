using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace GisGmpDiasoftGateway
{
    [RunInstaller(true)]
    public class ProjectInstaller : Installer
    {
        private ServiceProcessInstaller serviceProcessInstaller;
        private ServiceInstaller serviceInstaller;

        public ProjectInstaller()
        {
            serviceProcessInstaller = new ServiceProcessInstaller();
            serviceInstaller = new ServiceInstaller();
            
            serviceProcessInstaller.Account = ServiceAccount.LocalService;

            serviceInstaller.ServiceName = GisGmpService.MY_SERVICE_NAME;
            this.Installers.AddRange(new Installer[] { serviceProcessInstaller, serviceInstaller });
        }
    }
}