create function gisgmp_f_DealTransactIdToSystemIdentifier
(
	@DealTransactId numeric(15,0)
)
returns varchar(32)

with schemabinding

as
begin

  declare
    @BankIn numeric(15,0),
    @Date smalldatetime

  select
    @Date = [Date],
    @BankIn = InstitutionID
  from dbo.tDealTransact dt
  where dt.DealTransactID = @DealTransactId

	declare @SystemIdentifier varchar(32)
	select @SystemIdentifier = 
    '1' + 
    ltrim(rtrim(i.BIC)) +
    '000000' +
    replace(convert(varchar, @Date, 4), '.', '') +
    right(cast(@DealTransactID as varchar(15)), 10)
  from dbo.tInstitution i
  where i.InstitutionID = @BankIn

	return  @SystemIdentifier

end