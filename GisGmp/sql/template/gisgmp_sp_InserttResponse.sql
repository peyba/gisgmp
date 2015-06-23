create procedure gisgmp_sp_InserttResponse
  @Xml xml
as

  /* Сохранение и обработка полученного ответа */

go
grant exec on gisgmp_sp_InserttResponse to public
grant alter on gisgmp_sp_InserttResponse to <system_owner>