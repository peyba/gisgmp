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

  WITH XMLNAMESPACES (
    'http://roskazna.ru/gisgmp/xsd/116/Message' as [ms],
    'http://roskazna.ru/gisgmp/xsd/116/MessageData' as [md],
    'http://roskazna.ru/gisgmp/xsd/116/PGU_ImportRequest' as [pir],
    'http://roskazna.ru/gisgmp/xsd/116/PaymentInfo' as [pi],
    'http://roskazna.ru/gisgmp/xsd/116/Ticket' as [tic],
    'http://roskazna.ru/gisgmp/xsd/116/ErrInfo' as [err]
  ),

  /* TODO: info for Ids */
  Ids as (
    select
      [DealTransactId] = dt.DealTransactID,
      [SystemIdentifier] = dbo.gisgmp_f_DealTransactIdToSystemIdentifier(dt.DealTransactId)
    from tDealTransact dt
      join tPayInstruct p
        on p.DealTransactID = dt.DealTransactID
        and p.Belong = 1
        and (
          p.AccClient like '40101%'
          or p.AccClient like '40[67]01________[13]%'
          or p.AccClient like '40501________2%'
          or p.AccClient like '40[567]03_______4%'
        )
      left join tKey k
        on k.ObjectId = dt.DealTransactId
        and k.InterfaceFieldId = 8
    where 0=0
      and dt.TransactType in (4, 5)
      and dt.Date between '20150716' and '20150716'
      and dt.Direction = 0
      and dt.Confirmed <> 101 -- не фикт
      and dt.InstrumentID = 1195 -- **operdoc
      and dt.NumberExt like '_1%'
      and k.PKey is not null
  ),

  /* TODO: info for Documents */
  Documents as (
  select
    [MessageId] = m.Id,
    [DocumetnType] = cast(Documents.data.query('local-name((.)[1])') as varchar(32)),
    [EntityId] = Documents.data.value('@Id', 'varchar(39)'),
    [RequestId] = Documents.data.value('../../../../@Id', 'varchar(39)'),
    [SystemIdentifier] = cast(Documents.data.query('./pi:PaymentIdentificationData/pi:SystemIdentifier/text()') as varchar(32))
  from gisgmp_t_Messages m
    cross apply m.[Xml].nodes('.//md:ImportRequest/pir:Package/pir:Document/*') Documents(data)
  ),

  /* TODO: info for DocumentsOnDate */
  DocumentsOnDate as (
    select
      Ids.DealTransactId,
      doc.*
    from Ids
      left join Documents doc
        on doc.SystemIdentifier = Ids.SystemIdentifier
  ),

  /* TODO: info for RequestStatus */
  RequestStatus as (
    select
      [MessageId] = m.Id,
      [RequestId] = m.[Xml].value('(.//ms:ResponseMessage/@rqId)[1]', 'varchar(39)'),
      [Code] = cast(cast(m.[Xml].query('.//err:ResultCode/text()') as varchar(3)) as int),
      [Discription] = cast(m.[Xml].query('.//err:ResultDescription/text()') as varchar(max)),
      [Data] = cast(m.[Xml].query('.//err:ResultData/text()') as varchar(max))
    from gisgmp_t_Messages m
    where StateId = 0 and TypeId = 1
      and m.[Xml].exist('.//md:Ticket/tic:RequestProcessResult') = 1
  ),

  /* TODO: info for PackageRequest */
  PackageRequest as (
    select
      [MessageId] = gisgmp_t_Messages.Id,
      [EntityId] = PackageResults.data.value('@entityId', 'varchar(39)'),
      [Code] = cast(cast(PackageResults.data.query('./err:ResultCode/text()') as varchar(3)) as int),
      [Discription] = cast(PackageResults.data.query('./err:ResultDescription/text()') as varchar(max)),
      [Data] = cast(PackageResults.data.query('./err:ResultData/text()') as varchar(max))  
    from gisgmp_t_Messages
      cross apply [Xml].nodes('.//md:Ticket/tic:PackageProcessResult/tic:EntityProcessResult') PackageResults(data)
    where StateId = 0 and TypeId = 1
  )

  /* TODO: info for MAIN */
  select
    [DealTransactId] = doc.DealTransactId,
    [SystemIdentifier] = doc.SystemIdentifier,
    [RequestMessageId] = doc.MessageId,

    [RequestId] = doc.RequestId,
    [RequestResponseMessageId] = rs.MessageId,
    [RequestResponseCode] = rs.Code,
    [RequestResponseDiscription] = rs.Discription,
    [RequestResponseData] = rs.Data,

    [EntityId] = pr.EntityId,
    [PackageResponseMessageId] = pr.MessageId,
    [PackageResponseCode] = pr.Code,
    [PackageResponseDiscription] = pr.Discription,
    [PackageResponseData] = pr.Data
  from DocumentsOnDate doc
    left join RequestStatus rs
      on rs.RequestId = doc.RequestId
    left join PackageRequest pr
      on pr.EntityId = doc.EntityId

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

go
grant exec on gisgmp_sp_GetRequestReport to public