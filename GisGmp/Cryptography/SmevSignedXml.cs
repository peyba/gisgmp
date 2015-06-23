using System.Security.Cryptography.Xml;
using System.Xml;

namespace GisGmp.Cryptography
{
    public class SmevSignedXml : SignedXml
    {
        // пространство имен для подписываемого сообщения СМЭВ
        const string WS_SECURITY_WSU_NAMESPACE_URL = @"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd";

        public SmevSignedXml(XmlDocument document) : base(document) { }

        // переопределяем метод GetIdElement родителя, т.к. класса умеет искать узлы 
        // только по атрибуту Id в глобальном простанстве имен, тогда как подписываемое
        // тело сообщения для СМЭВ должно быть помечено атрибутом wsu:Id
        public override XmlElement GetIdElement(XmlDocument document, string idValue)
        {
            XmlNamespaceManager nsmgr = new XmlNamespaceManager(document.NameTable);
            nsmgr.AddNamespace("wsu", WS_SECURITY_WSU_NAMESPACE_URL);
            return document.SelectSingleNode("//*[@wsu:Id='" + idValue + "']", nsmgr) as XmlElement;
        }
    }
}
