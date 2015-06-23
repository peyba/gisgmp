create procedure gisgmp_sp_GetNextRequest
as

  declare @Xml xml

  /* Генерация сообщения */

  select [Xml] = @Xml

go
grant exec on gisgmp_sp_GetNextRequest to public
grant alter on gisgmp_sp_GetNextRequest to <system_owner>