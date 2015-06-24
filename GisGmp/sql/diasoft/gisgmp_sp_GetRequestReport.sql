create procedure gisgmp_sp_GetRequestReport
  @BeginDate datetime,
  @EndDate datetime
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  declare @DealTransacIds table (DealTransactId numeric(15,0))

  insert @DealTransacIds
  select [DealTransactID] = dt.DealTransactID
  from tDealTransact dt with(nolock index=XIE8tDealTransact)
    join tPayInstruct  p  with(nolock index= XIE2tPayInstruct) on p.DealTransactID = dt.DealTransactID
      and p.Belong = 1
      and (
        left(p.AccClient, 5) = '40101'
        or (
          left(p.AccClient, 5) in ('40601','40701')
          and substring(AccClient, 14, 1) in ('1', '3')
        )
        or (
          left(p.AccClient, 5) = '40501'
          and substring(AccClient, 14, 1) ='2'
        )
        or (
          left(p.AccClient, 5) in ('40503','40603','40703')
          and substring(AccClient, 14, 1) ='4'
        )
      )
  where 0=0
    and dt.TransactType in (4, 5)
    and dt.Date between @BeginDate and @EndDate
    and dt.Direction = 0
    and dt.Confirmed <> 101 -- не фикт
    and dt.InstrumentID = 1195 -- **operdoc
    and substring(dt.numberext,2,1) = '1'

  declare @Id varchar(39)

  WITH XMLNAMESPACES (
    'http://roskazna.ru/gisgmp/xsd/116/MessageData' as [md],
    'http://roskazna.ru/gisgmp/xsd/116/PGU_ImportRequest' as [pir],
    'http://roskazna.ru/gisgmp/xsd/116/PaymentInfo' as [pi],
    'http://roskazna.ru/gisgmp/xsd/116/Ticket' as [tic],
    'http://roskazna.ru/gisgmp/xsd/116/ErrInfo' as [err]
  )
  select
    list.DealTransactId,
    Ids.SystemIdentifier, 
    [RequestMessageId] = Ids.MessageId,

    [DealTransacDate] = dt.[Date],

    Ids.RequestId,
    [RequestResponseMessageId] = ReqStat.MessageId,
    [RequestResponseCode] = ReqStat.Code,
    [RequestResponseDiscription] = ReqStat.Discription,
    [RequestResponseData] = ReqStat.Data,

    Ids.EntityId,
    [PackageResponseMessageId] = PackRes.MessageId,
    [PackageResponseCode] = PackRes.Code,
    [PackageResponseDiscription] = PackRes.Discription,
    [PackageResponseData] = PackRes.Data
  from @DealTransacIds list
    left join (
      select
        [MessageId] = gisgmp_t_Messages.Id,
        [EntityId] = RECORDS.t.value('@Id', 'varchar(39)'),
        [RequestId] = RECORDS.t.value('../../../../@Id', 'varchar(39)'),
        [SystemIdentifier] = cast(RECORDS.t.query('./pi:PaymentIdentificationData/pi:SystemIdentifier/text()') as varchar(32)),
        [DealTransactId] = (
          select DealTransactId 
          from @DealTransacIds 
          where dbo.gisgmp_f_DealTransactIdToSystemIdentifier(DealTransactId) = 
            cast(RECORDS.t.query('./pi:PaymentIdentificationData/pi:SystemIdentifier/text()') as varchar(32))
        )
      from gisgmp_t_Messages
        CROSS APPLY [Xml].nodes('.//md:ImportRequest/pir:Package/pir:Document/*') RECORDS(t)
      where StateId = 1 and TypeId = 0
        and cast(RECORDS.t.query('./pi:PaymentIdentificationData/pi:SystemIdentifier/text()') as varchar(32)) in (
          select dbo.gisgmp_f_DealTransactIdToSystemIdentifier(DealTransactId) from @DealTransacIds
        )
    ) Ids
      on list.DealTransactId = Ids.DealTransactId

    left join (
      select
        [MessageId] = gisgmp_t_Messages.Id,
        [RequestId] = RECORDS.t.value('../../@rqId', 'varchar(39)'),
        [Code] = cast(cast(RECORDS.t.query('./err:ResultCode/text()') as varchar(3)) as int),
        [Discription] = cast(RECORDS.t.query('./err:ResultDescription/text()') as varchar(max)),
        [Data] = cast(RECORDS.t.query('./err:ResultData/text()') as varchar(max))
      from gisgmp_t_Messages
          CROSS APPLY [Xml].nodes('.//md:Ticket/tic:RequestProcessResult') RECORDS(t)
      where StateId = 0 and TypeId = 1
    ) ReqStat
      on ReqStat.RequestId = Ids.RequestId

    left join (
      select
        [MessageId] = gisgmp_t_Messages.Id,
        [EntityId] = RECORDS.t.value('@entityId', 'varchar(39)'),
        [Code] = cast(cast(RECORDS.t.query('./err:ResultCode/text()') as varchar(3)) as int),
        [Discription] = cast(RECORDS.t.query('./err:ResultDescription/text()') as varchar(max)),
        [Data] = cast(RECORDS.t.query('./err:ResultData/text()') as varchar(max))  
      from gisgmp_t_Messages
          CROSS APPLY [Xml].nodes('.//md:Ticket/tic:PackageProcessResult/tic:EntityProcessResult') RECORDS(t)
      where StateId = 0 and TypeId = 1    
    ) PackRes
      on PackRes.EntityId = Ids.EntityId

    join tDealTransact dt
      on dt.DealTransactId = list.DealTransactId
  order by dt.[Date]

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

go
grant exec on gisgmp_sp_GetRequestReport to public