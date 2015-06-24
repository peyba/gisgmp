create procedure gisgmp_sp_InserttResponse
  @Xml xml
as

  begin tran

  insert gisgmp_t_Messages ([Xml], [StateId], [TypeId], [EnterDateTime])
  select @Xml, 0, 1, GetDate()

  declare @Id int
  select @Id = @@IDENTITY

  declare @PackageId varchar(39);

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  declare @ResponseType varchar(50)

  WITH XMLNAMESPACES (
    'http://roskazna.ru/gisgmp/xsd/116/MessageData' as [md],
    'http://roskazna.ru/gisgmp/xsd/116/Ticket' as [tic]
  )
  select @ResponseType = cast(RECORDS.t.query('local-name(./*[1])') as varchar(50))
  from gisgmp_t_Messages
    CROSS APPLY [Xml].nodes('.//md:Ticket') RECORDS(t)
  where Id = @Id

  if @ResponseType = 'RequestProcessResult'
  begin

    WITH XMLNAMESPACES (
      'http://roskazna.ru/gisgmp/xsd/116/MessageData' as [md],
      'http://roskazna.ru/gisgmp/xsd/116/Ticket' as [tic],
      'http://roskazna.ru/gisgmp/xsd/116/ErrInfo' as [err]
    )
    select @PackageId = cast(RECORDS.t.query('./err:ResultData/text()') as varchar(39))
    from gisgmp_t_Messages
      CROSS APPLY [Xml].nodes('.//md:Ticket/tic:RequestProcessResult') RECORDS(t)
    where Id = @Id
      and cast(cast(RECORDS.t.query('./err:ResultCode/text()') as varchar(3)) as int) = 0
  
    exec gisgmp_sp_CreatePackageStatusRequestMessage
      @PackageId = @PackageId

  end

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  commit tran

go
grant exec on gisgmp_sp_InserttResponse to public