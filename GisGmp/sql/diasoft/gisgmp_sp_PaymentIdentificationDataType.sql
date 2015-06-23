create procedure gisgmp_sp_PaymentIdentificationDataType
  @DealTransactID numeric(15, 0),
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  declare
    @BankIn numeric(15,0),
    @Date smalldatetime,
    @Bank xml

  exec TDocumentPlat_F_Select
    @DealTransactID = @DealTransactID,
    @BankIn = @BankIn output,
    @Date = @Date output

  exec gisgmp_sp_BankType
    @BankID = @BankIn,
    @Xml = @Bank output;

  WITH XMLNAMESPACES ('http://roskazna.ru/gisgmp/xsd/116/PaymentInfo' as [pi])
  select @Xml = (
    select
      /* 
        Реквизиты структурного подразделения кредитной организации, 
        принявшего платеж. Наличие данного тега исключает появление тегов UFK и Other
      */
      [pi:Bank] = @Bank,
      /* УИП, присвоенный участником, принявшим платеж. Алгоритм формирования УИП описан в пункте 3.3 */
      [pi:SystemIdentifier] = dbo.gisgmp_f_DealTransactIdToSystemIdentifier(@DealTransactID)
    from tInstitution i
    where i.InstitutionID = @BankIn
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_PaymentIdentificationDataType to public
grant alter on gisgmp_sp_PaymentIdentificationDataType to <system_owner>