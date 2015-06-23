if object_id('gisgmp_t_Config') is not null
begin
  drop table gisgmp_t_Config
end

create table gisgmp_t_Config (
  Name varchar(50),
  Value varchar(max)
)

go
grant select on gisgmp_t_Config to public
grant insert, delete, update, alter on gisgmp_t_Config to <system_owner>

go
insert gisgmp_t_Config
select 'docs_in_package', '1' union
select 'urn',             '<ur_urn>' union
select 'sender_name',     '<ur_name>' union
select 'sender_code',     '<ur_code>' union
select 'recipient_name',  'Казначейство России' union
select 'recipient_code',  'RKZN35001' union
select 'service_name',    'RKZNGISGMP116' union
select 'code_type',       'GSRV'