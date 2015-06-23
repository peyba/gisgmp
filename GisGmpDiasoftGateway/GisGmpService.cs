using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Timers;

namespace GisGmpDiasoftGateway
{
    public class GisGmpService : ServiceBase
    {
        public const string MY_SERVICE_NAME = "GisGmpGateway";

        private System.Timers.Timer gisgmpServiceTimer;
        private GisGmp.RequestManager nextQuery;
        private int interval;

        public GisGmpService(int interval)
        {
            this.ServiceName = MY_SERVICE_NAME;
            this.CanPauseAndContinue = false;
            this.interval = interval;
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
        }

        protected override void OnStart(string[] args)
        {
            gisgmpServiceTimer = new System.Timers.Timer(this.interval);
            gisgmpServiceTimer.Elapsed += gisgmpServiceTimer_Elapsed;
            gisgmpServiceTimer.AutoReset = true;

            nextQuery = new GisGmp.RequestManager();

            gisgmpServiceTimer.Enabled = true;
        }

        protected override void OnStop()
        {
            gisgmpServiceTimer.Enabled = false;
            gisgmpServiceTimer = null;
        }

        private void gisgmpServiceTimer_Elapsed(object sender, ElapsedEventArgs e)
        {
            try
            {
                nextQuery.SendNextRequest();
            }
            catch (Exception exp)
            {
                var error = String.Format("{0}\n{1}", exp.Message, exp.StackTrace);
                this.EventLog.WriteEntry(error, EventLogEntryType.Error);
                this.OnStop();
            }
        }
    }
}