if object_id('gisgmp_t_DealTransactIdList') is not null
begin
  drop table gisgmp_t_DealTransactIdList
end

create table gisgmp_t_DealTransactIdList (
  SPID int,
  DealTransactID numeric(15,0),
  UIN varchar(255),
  Meaning int,
  Reason varchar(255)
)

go
grant select, delete, insert on gisgmp_t_DealTransactIdList to public