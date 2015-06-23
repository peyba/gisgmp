using System.Security.Cryptography.X509Certificates;

namespace GisGmp.Cryptography
{
    public static class Certificate
    {
        public static X509Certificate2 GetLocalX509Certificate(
            StoreName storeName,
            string certStringPart)
        {
            X509Store targetLocalCertificatesStore = new X509Store(storeName, StoreLocation.CurrentUser);
            targetLocalCertificatesStore.Open(OpenFlags.OpenExistingOnly | OpenFlags.ReadOnly);
            X509Certificate2Collection collectionOfFoundCertificates =
                targetLocalCertificatesStore.Certificates.Find(X509FindType.FindBySubjectName, certStringPart, false);

            if (collectionOfFoundCertificates.Count == 0)
            {
                throw new CannotFindCertificateException();
            }

            if (collectionOfFoundCertificates.Count > 1)
            {
                throw new CannotFindCertificateException();
            }

            return collectionOfFoundCertificates[0];
        }
    }
}
