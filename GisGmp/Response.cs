using System.Xml;

namespace GisGmp
{
    internal class Response : Message
    {
        public override int Type
        {
            get { return 1; }
        }

        public Response(XmlDocument xml)
        {
            this.Xml = xml;
        }
    }
}
