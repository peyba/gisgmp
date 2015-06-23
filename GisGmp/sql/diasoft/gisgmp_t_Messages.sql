if object_id('gisgmp_t_Messages') is not null
begin
  drop table gisgmp_t_Messages
end

create table gisgmp_t_Messages (
  [Id] int IDENTITY(1,1),
  [Xml] Xml,
  [TypeId] int,
  [StateId] int,
  [EnterDateTime] datetime
)
go
grant select on gisgmp_t_Messages to public
grant insert, delete, update, alter on gisgmp_t_Messages to <system_owner>