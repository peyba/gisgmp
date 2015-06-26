declare
  @BeginDate datetime,
  @EndDate datetime

select 
  @BeginDate = '20150625',
  @EndDate = '20150625'

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  declare @Message xml

  declare @RequestReport table (
    DealTransactId numeric(15,0),
    SystemIdentyfier varchar(32),
    RequestMessageId int,
    DealTransactDate datetime,
    RequestId varchar(39),
    RequestResponseMessageId int,
    RequestResponseCode varchar(3),
    RequestResponseDiscription varchar(max),
    RequestResponseData varchar(max),
    EntityId varchar(39),
    PackageResponseMessageId int,
    PackageResponseCode varchar(3),
    PackageResponseDiscription varchar(max),
    PackageResponseData varchar(max)
  )

  insert @RequestReport
  exec gisgmp_sp_GetRequestReport
    @BeginDate = @BeginDate,
    @EndDate = @EndDate

  declare @DealTransactIds table (DealTransactId numeric(15,0))
  
  --insert @DealTransactIds
  select DealTransactId
  from @RequestReport
  /*where DealTransactId not in (
    select DealTransactId from @RequestReport where PackageResponseCode in (0, 5, 50)
  )*/

  declare @DodumentsInPackage int
  select @DodumentsInPackage = convert(int, Value) from gisgmp_t_Config where Name = 'docs_in_package'

  declare
    @StartDocumenNumber int,
    @DocumentsCount int
  select
    @StartDocumenNumber = 0,
    @DocumentsCount = (select count(1) from @DealTransactIds)

  while (@StartDocumenNumber < @DocumentsCount)
  begin

    delete gisgmp_t_DealTransactIdList
    where spid = @@spid
    
    set rowcount @DodumentsInPackage

    insert gisgmp_t_DealTransactIdList (spid, DealTransactID)
    select @@spid, DealTransactId 
    from @DealTransactIds
    order by DealTransactId

    set rowcount 0

    delete @DealTransactIds
    where DealTransactId in (select DealTransactID from gisgmp_t_DealTransactIdList where spid = @@spid)

    select @StartDocumenNumber = @StartDocumenNumber + @DodumentsInPackage

    exec gisgmp_sp_GetPeymentsImportRequestByDealTransactIdsList
      @Xml = @Message out

    exec gisgmp_sp_GISGMPTransferMsg
      @RequestMessage = @Message,
      @Xml = @Message out

    exec gisgmp_sp_SOAPEnv
      @GISGMPTransferMsg = @Message,
      @Xml = @Message out

    --insert gisgmp_t_Messages ([Xml], [TypeId], [StateId], [EnterDateTime])
    select @Message, 0, 0, GetDate()

  end

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF