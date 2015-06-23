create procedure gisgmp_sp_AccountType
  @DealTransactID numeric(15,0),
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  declare
    @Acc varchar(25),
    @BankID numeric(15,0),
    @Bank xml

  exec TDocumentPlat_F_Select
    @DealTransactID = @DealTransactID,
    @AccOut = @Acc output,
    @BankOut = @BankID output

  exec gisgmp_sp_BankType
    @BankID = @BankID,
    @Xml = @Bank output;

  WITH XMLNAMESPACES ('http://roskazna.ru/gisgmp/xsd/116/Organization' as [org])
  select @Xml = (
    select
      /* Номер банковского счета */
      [org:AccountNumber] = ltrim(rtrim(@Acc)),
      /* Данные банка, в котором открыт счет */
      [org:Bank] = @Bank 
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_AccountType to public
grant alter on gisgmp_sp_AccountType to <system_owner>