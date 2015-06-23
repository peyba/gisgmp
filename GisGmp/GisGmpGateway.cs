using System;
using System.IO;
using System.Net;
using System.Text;

namespace GisGmp
{
    class GisGmpGateway
    {
        #region Fields

        private HttpWebRequest webRequest;
        private string soapAction = String.Empty;
        #endregion // Fields

        #region Properties

        public string RequestUri { get { return this.webRequest.RequestUri.ToString(); } }

        public string SoapAction
        {
            get { return this.soapAction; }
            set
            {
                this.soapAction = value;
                this.webRequest.Headers.Add("SOAPAction", this.soapAction);
            }
        }

        public int Timeout
        {
            get { return this.webRequest.Timeout; }
            set { this.webRequest.Timeout = value; }
        }

        public string ProxyServer { get; set; }

        public int ProxyPort { get; set; }

        public string ProxyUser { get; set; }

        public string ProxyPassword { get; set; }
        #endregion // Properties

        #region Constructor

        public GisGmpGateway(string requestUri)
        {
            System.Net.ServicePointManager.Expect100Continue = false;
            this.webRequest = (HttpWebRequest)WebRequest.Create(requestUri);
            this.webRequest.ContentType = "text/xml; charset=UTF-8";
            this.webRequest.Method = "POST";
            this.webRequest.Credentials = CredentialCache.DefaultCredentials;
        }
        #endregion // Constructor

        #region Methods

        public byte[] Send(byte[] sendingFile)
        {
            if (!String.IsNullOrEmpty(this.ProxyServer))
            {
                WebProxy proxy;
                if (this.ProxyPort != 0)
                {
                    proxy = new WebProxy(this.ProxyServer, this.ProxyPort);
                }
                else
                {
                    proxy = new WebProxy(this.ProxyServer);
                }

                if (!String.IsNullOrEmpty(this.ProxyUser))
                {
                    proxy.Credentials = new NetworkCredential(this.ProxyUser, this.ProxyPassword);
                }

                this.webRequest.Proxy = proxy;
                this.webRequest.KeepAlive = true;
            }

            Stream newStream = this.webRequest.GetRequestStream();
            newStream.Write(sendingFile, 0, sendingFile.Length);

            WebResponse response;
            try
            {
                response = this.webRequest.GetResponse();
            }
            catch (WebException wex)
            {
                response = wex.Response;
            }

            StreamReader soapStreamReader = new StreamReader(response.GetResponseStream());

            return Encoding.UTF8.GetBytes(soapStreamReader.ReadToEnd());
        }
        #endregion // Methods
    }
}