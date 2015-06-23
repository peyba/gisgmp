using System.Xml;

namespace GisGmp
{
    internal abstract class Message
    {
        #region Properties

        public XmlDocument Xml { get; protected set; }
        public abstract int Type { get; }
        #endregion // Properties

        #region Methods

        public XmlNamespaceManager GetNamespacesManager()
        {
            var namespaces = new XmlNamespaceManager(this.Xml.NameTable);

            namespaces.AddNamespace("smev", "http://smev.gosuslugi.ru/rev120315");
            namespaces.AddNamespace("gisgmp", "http://roskazna.ru/gisgmp/xsd/116/Message");
            namespaces.AddNamespace("pi", "http://roskazna.ru/gisgmp/xsd/116/PaymentInfo");
            namespaces.AddNamespace("pir", "http://roskazna.ru/gisgmp/xsd/116/PGU_ImportRequest");
            namespaces.AddNamespace("err", "http://roskazna.ru/gisgmp/xsd/116/ErrInfo");
            namespaces.AddNamespace("tic", "http://roskazna.ru/gisgmp/xsd/116/Ticket");

            return namespaces;
        }
        #endregion // Methods
    }
}
