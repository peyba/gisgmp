create procedure gisgmp_sp_PackageStatusRequestType
  @PackageID varchar(39),
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  if nullif(ltrim(rtrim(@PackageID)), '') is null
  begin
    raiserror('Не найден параметр PackageID', 18, -1)
    return
  end

  WITH XMLNAMESPACES (
    'http://roskazna.ru/gisgmp/xsd/116/PackageStatusRequest' as [psr],
    'http://roskazna.ru/gisgmp/xsd/116/MessageData' as [msgd])
  select @Xml = (
    select [psr:PackageID] = @PackageID
    FOR XML PATH('msgd:PackageStatusRequest'), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_PackageStatusRequestType to public