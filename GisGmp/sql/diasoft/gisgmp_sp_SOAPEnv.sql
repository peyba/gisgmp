create procedure gisgmp_sp_SOAPEnv
  @GISGMPTransferMsg xml,
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  WITH XMLNAMESPACES (
    'http://schemas.xmlsoap.org/soap/envelope/' as [soap],
    'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' as [wsse],
    'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd' as [wsu],
    'http://www.w3.org/2000/09/xmldsig#' as [ds],
    'http://roskazna.ru/gisgmp/02000000/SmevGISGMPService/' as n1
  )
  select @Xml = (
    select
      /* /soap:Envelope */ /* SOAP root */
      /* /soap:Envelope/soap:Header */
      /* /soap:Envelope/soap:Header/wsse:Security */
      [soap:Envelope/soap:Header/wsse:Security/@soap:actor] = 'http://smev.gosuslugi.ru/actors/smev',
      
      /* /soap:Envelope/soap:Header/wsse:Security/wsse:BinarySecurityToken */
      [soap:Envelope/soap:Header/wsse:Security/wsse:BinarySecurityToken/@EncodingType] = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
      [soap:Envelope/soap:Header/wsse:Security/wsse:BinarySecurityToken/@ValueType] = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3',
      [soap:Envelope/soap:Header/wsse:Security/wsse:BinarySecurityToken/@wsu:Id] = 'CertId',

      /* /soap:Envelope/soap:Header/wsse:Security/ds:Signature */
      /* /soap:Envelope/soap:Header/wsse:Security/ds:Signature/ds:KeyInfo */
      /* /soap:Envelope/soap:Header/wsse:Security/ds:Signature/ds:KeyInfo/wsse:SecurityTokenReference */
      /* /soap:Envelope/soap:Header/wsse:Security/ds:Signature/ds:KeyInfo/wsse:SecurityTokenReference/wsse:Reference */
      [soap:Envelope/soap:Header/wsse:Security/ds:Signature/ds:KeyInfo/wsse:SecurityTokenReference/wsse:Reference/@URI] = '#CertId',
      [soap:Envelope/soap:Header/wsse:Security/ds:Signature/ds:KeyInfo/wsse:SecurityTokenReference/wsse:Reference/@ValueType] = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3',

      /* /soap:Envelope/soap:Body */
      [soap:Envelope/soap:Body/@wsu:Id] = 'body',
      [soap:Envelope/soap:Body/n1:GISGMPTransferMsg] = @GISGMPTransferMsg
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_SOAPEnv to public
grant alter on gisgmp_sp_SOAPEnv to <system_owner>