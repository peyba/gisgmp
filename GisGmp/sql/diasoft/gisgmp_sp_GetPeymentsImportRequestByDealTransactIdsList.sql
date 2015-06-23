create procedure gisgmp_sp_GetPeymentsImportRequestByDealTransactIdsList
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  /* таблица для хранения xml */
  declare @PaymentXmlList table (Body xml)
  
  declare
    @PaymentXml xml,
    @UIN varchar(255),
    @Meaning int,
    @Reason varchar(255)

  declare @MinId numeric(15,0)
  select @MinId = min(DealTransactID) from gisgmp_t_DealTransactIdList where spid = @@spid

  while exists (select 1 from gisgmp_t_DealTransactIdList where spid = @@spid and DealTransactId >= @MinId)
  begin

    set @PaymentXml = null

    select 
      @UIN = UIN,
      @Meaning = Meaning,
      @Reason = Reason
    from gisgmp_t_DealTransactIdList
    where spid = @@spid
      and DealTransactID = @MinId

    exec gisgmp_sp_Payment
      @DealTransactID = @MinId,
      @UIN = @UIN,
      @Meaning = @Meaning,
      @Reason = @Reason,
      @Xml = @PaymentXml output

      insert @PaymentXmlList
      select @PaymentXml

      select @MinId = min(DealTransactID)
      from gisgmp_t_DealTransactIdList
      where spid = @@spid and DealTransactId > @MinId

  end;

  WITH XMLNAMESPACES (
    'http://roskazna.ru/gisgmp/xsd/116/PGU_ImportRequest' as [pir],
    'http://roskazna.ru/gisgmp/xsd/116/PaymentInfo' as [pi]
  )
  select @Xml = (
    select
      /* Данные платежей */
      [pir:Document/@originatorID] = (select top 1 Value from gisgmp_t_Config where Name = 'urn'),
      [pir:Document/pi:FinalPayment/@Id] = 'A_' + cast(newid() as varchar(36)),
      [pir:Document/pi:FinalPayment] = t.Body
    from @PaymentXmlList t
    FOR XML PATH(''), ELEMENTS
  );

  WITH XMLNAMESPACES (
    'http://roskazna.ru/gisgmp/xsd/116/PGU_ImportRequest' as [pir],
    'http://roskazna.ru/gisgmp/xsd/116/MessageData' as [md]
  )
  select @Xml = (
    select
      [pir:Package] = @Xml
    FOR XML PATH('md:ImportRequest'), ELEMENTS
  );

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_GetPeymentsImportRequestByDealTransactIdsList to public
grant alter on gisgmp_sp_GetPeymentsImportRequestByDealTransactIdsList to <system_owner>