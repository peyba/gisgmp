create procedure gisgmp_sp_CreatePackageStatusRequestMessage
  @PackageId varchar(39)
as

  if @PackageId is null return;

  declare @Message xml

  exec gisgmp_sp_PackageStatusRequestType
    @PackageId = @PackageId,
    @Xml = @Message out

  exec gisgmp_sp_GISGMPTransferMsg
    @RequestMessage = @Message,
    @Xml = @Message out

  exec gisgmp_sp_SOAPEnv
    @GISGMPTransferMsg = @Message,
    @Xml = @Message out

  insert gisgmp_t_Messages ([Xml], [TypeId], [StateId], [EnterDateTime])
  select @Message, 0, 0, GetDate()

go
grant exec on gisgmp_sp_CreatePackageStatusRequestMessage to public