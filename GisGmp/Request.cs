using System.IO;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Xml;
using GisGmp.Cryptography;

namespace GisGmp
{
    internal class Request : Message
    {
        public override int Type
        {
            get { return 0; }
        }

        public Request(XmlDocument xml)
        {
            this.Xml = xml;
            this.Xml.CreateXmlDeclaration("1.0", "UTF-8", null);
        }

        private void Sign()
        {
            X509Certificate2 cert = Cryptography.Certificate.GetLocalX509Certificate(
                StoreName.My,
                Config.RootCfgObject.Read().Certificate
            );

            this.SignPackage(cert);
            this.SignXmlSoap(cert);
        }

        internal Response Send()
        {
            this.Sign();

            // TODO: проверять валидность подписанного xml-документа

            var webSend = new GisGmpGateway(Config.RootCfgObject.Read().Send.ServiceUrl);
            webSend.SoapAction = Config.RootCfgObject.Read().Send.SoapAction;
            webSend.Timeout = Config.RootCfgObject.Read().Send.Timeout;
            webSend.ProxyServer = Config.RootCfgObject.Read().Send.ProxyServer;
            webSend.ProxyPort = Config.RootCfgObject.Read().Send.ProxyPort;
            webSend.ProxyUser = Config.RootCfgObject.Read().Send.ProxyUser;
            webSend.ProxyPassword = Config.RootCfgObject.Read().Send.ProxyPass;

            this.Xml.PreserveWhitespace = true;

            Stream documentSream = new MemoryStream();
            this.Xml.Save(documentSream);
            documentSream.Position = 0;
            var documentBytes = new byte[documentSream.Length];
            documentSream.Read(documentBytes, 0, (int)documentSream.Length);

            var bytesResponse = webSend.Send(documentBytes);

            var responseXml = new XmlDocument();
            responseXml.LoadXml(
                Encoding.UTF8.GetString(bytesResponse)
            );

            return new Response(responseXml);
        }
    }
}
