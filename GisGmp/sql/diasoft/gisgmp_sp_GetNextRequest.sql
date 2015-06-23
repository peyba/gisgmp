create procedure gisgmp_sp_GetNextRequest
as

  declare @Request table ([Id] int, [Xml] xml)

  insert @Request
  select top 1 [Id], [Xml]
  from gisgmp_t_Messages
  where [StateId] = 0
    and [TypeId] = 0
  order by [EnterDateTime]

  update gisgmp_t_Messages
  set [StateId] = 1
  where [Id] in (select [Id] from @Request)

  select [Xml]
  from @Request

go
grant exec on gisgmp_sp_GetNextRequest to public
grant alter on gisgmp_sp_GetNextRequest to <system_owner>