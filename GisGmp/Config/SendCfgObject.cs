using System.Runtime.Serialization;

namespace GisGmp.Config
{
    [DataContract]
    public class SendCfgObject
    {
        [DataMember(Name = "service_url")]
        public string ServiceUrl { get; set; }

        [DataMember(Name = "proxy_server")]
        public string ProxyServer { get; set; }

        [DataMember(Name = "proxy_port")]
        public int ProxyPort { get; set; }

        [DataMember(Name = "proxy_user")]
        public string ProxyUser { get; set; }

        [DataMember(Name = "proxy_pass")]
        public string ProxyPass { get; set; }

        [DataMember(Name = "timeout")]
        public int Timeout { get; set; }

        [DataMember(Name = "soap_action")]
        public string SoapAction { get; set; }
    }
}