using System;
using System.Security.Cryptography.X509Certificates;
using System.Security.Cryptography.Xml;
using System.Xml;

namespace GisGmp.Cryptography
{
    static class SignGisGmpMessageExtension
    {
        public static void SignSingleEntity(
            this GisGmp.Message message,
            X509Certificate2 certificate,
            XmlNode entityXml)
        {
            XmlDocument signingDoc = new XmlDocument();
            signingDoc.LoadXml(entityXml.OuterXml);

            SmevSignedXml signedXml = new SmevSignedXml(signingDoc);
            signedXml.SigningKey = certificate.PrivateKey;

            Reference reference = new Reference();
            reference.Uri = "";
            reference.DigestMethod = CryptoPro.Sharpei.Xml.CPSignedXml.XmlDsigGost3411UrlObsolete;
            
            XmlDsigEnvelopedSignatureTransform envelopedSignature = new XmlDsigEnvelopedSignatureTransform();
            reference.AddTransform(envelopedSignature);
            XmlDsigExcC14NTransform c14 = new XmlDsigExcC14NTransform();
            reference.AddTransform(c14);
            
            KeyInfo ki = new KeyInfo();
            ki.AddClause(new KeyInfoX509Data(certificate));
            
            signedXml.KeyInfo = ki;
            signedXml.SignedInfo.CanonicalizationMethod = SignedXml.XmlDsigExcC14NTransformUrl;            
            signedXml.SignedInfo.SignatureMethod = CryptoPro.Sharpei.Xml.CPSignedXml.XmlDsigGost3410UrlObsolete;
            signedXml.AddReference(reference);

            signedXml.ComputeSignature();

            XmlElement xmlDigitalSignature = signedXml.GetXml();

            signingDoc.DocumentElement.AppendChild(xmlDigitalSignature);

            XmlDocumentFragment signedFinalPayment = message.Xml.CreateDocumentFragment();
            signedFinalPayment.InnerXml = signingDoc.OuterXml;

            var documentNode = entityXml.ParentNode;
            documentNode.RemoveChild(entityXml);
            documentNode.AppendChild(signedFinalPayment);
        }

        public static void SignPackage(
            this GisGmp.Message message,
            X509Certificate2 certificate)
        {
            var documents = message.Xml.SelectNodes(".//pir:Document/*", message.GetNamespacesManager());
            foreach (XmlNode doc in documents)
            {
                message.SignSingleEntity(certificate, doc);
            }
        }

        public static void SignXmlSoap(
            this Message message,
            X509Certificate2 certificate)
        {
            XmlDocument signedMessageXml = message.Xml;

            SmevSignedXml signedXml = new SmevSignedXml(signedMessageXml);

            signedXml.SigningKey = certificate.PrivateKey;

            Reference reference = new Reference();
            reference.Uri = "#body";

            reference.DigestMethod = CryptoPro.Sharpei.Xml.CPSignedXml.XmlDsigGost3411UrlObsolete;

            XmlDsigExcC14NTransform c14 = new XmlDsigExcC14NTransform();
            reference.AddTransform(c14);
            signedXml.SignedInfo.CanonicalizationMethod = SignedXml.XmlDsigExcC14NTransformUrl;

            signedXml.SignedInfo.SignatureMethod = CryptoPro.Sharpei.Xml.CPSignedXml.XmlDsigGost3410UrlObsolete;
            signedXml.AddReference(reference);

            signedXml.ComputeSignature();

            XmlElement xmlDigitalSignature = signedXml.GetXml();

            string xmldsig = @"http://www.w3.org/2000/09/xmldsig#";
            string wsse = @"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";

            var namespaceManager = new XmlNamespaceManager(new NameTable());
            namespaceManager.AddNamespace("ds", xmldsig);
            namespaceManager.AddNamespace("wsse", wsse);

            signedMessageXml.GetElementsByTagName("Signature", xmldsig)[0].PrependChild(
                signedMessageXml.ImportNode(xmlDigitalSignature.GetElementsByTagName("SignatureValue", xmldsig)[0], true)
            );
            signedMessageXml.GetElementsByTagName("Signature", xmldsig)[0].PrependChild(
                signedMessageXml.ImportNode(xmlDigitalSignature.GetElementsByTagName("SignedInfo", xmldsig)[0], true)
            );

            signedMessageXml.GetElementsByTagName("BinarySecurityToken", wsse)[0].InnerText = Convert.ToBase64String(certificate.RawData);
        }
    }
}
