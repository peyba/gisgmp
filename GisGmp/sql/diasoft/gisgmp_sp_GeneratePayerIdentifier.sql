create procedure gisgmp_sp_GeneratePayerIdentifier
	@DealTransactID numeric(15,0), 
	@PayerIdentifier varchar(25) = null output
as
begin
  set nocount on;

  /* const */
  declare
    @FIZ int,
    @U_REZIDENT int,
    @U_NOT_REZIDENT int,
    @IP int,
    @IP_CODE varchar(255),
    @MAB_ID numeric(15,0)

  select
    @FIZ = 1,
    @U_REZIDENT = 2,
    @U_NOT_REZIDENT = 3,
    @IP = 4,
    @IP_CODE = 'ИП',
    @MAB_ID = 2000

  declare
    @RetVal int,
    @PayerResourceOwner numeric(15,0),
    @PayerType int,
    @InnIn varchar(15),
    @KppIn varchar(9),
    @PayerResourceID numeric(15,0)

  exec @RetVal = TDocumentPlat_F_Select
    @DealTransactID = @DealTransactID,
    @InnIn = @InnIn output,
    @KppIn = @KppIn output,
    @AccInID = @PayerResourceID output

  select @PayerResourceOwner = r.InstOwnerID
  from tResource r
  where r.ResourceID = @PayerResourceID

  select @PayerType = 
    case
      when i.PropDealPart = 1 and i.MainMember = 1 
        and not (
          @PayerResourceOwner = @MAB_ID
          and left(r.Brief, 1) = '4'
        )
      then @U_REZIDENT
      when i.PropDealPart = 1 and i.MainMember = 0 then @U_NOT_REZIDENT
      when i.PropDealPart = 0 and rt.ReutersID is not null then @IP
      else @FIZ
    end,
    @PayerResourceOwner = r.InstOwnerID,
    @PayerResourceID = r.ResourceID
  from tDealTransact dt
    join tResource r
      on r.ResourceID = dt.ResourceID
    join tInstitution i
      on r.InstOwnerID = i.InstitutionID
    left join tReuters rt
      on rt.InstitutionID = i.InstitutionID
      and rt.Reuters = @IP_CODE
  where dt.DealTransactID = @DealTransactID

  if @PayerType = @FIZ
  begin

    declare @DocTypeDictionary table (DiasType int, GisGmpType varchar(2))

    insert @DocTypeDictionary
      select 20, '01' union
      select 9 , '02' union
      select 22, '03' union
      select 13, '05' union
      select 19, '06' union
      select 11, '07' union
      select 15, '08' union
      select 17, '09' union
      select 18, '11' union
      select 7 , '13' union
      select 4 , '22'

    if @PayerResourceOwner <> @MAB_ID
    begin 
      select @PayerIdentifier = 
        (select top 1 GisGmpType from @DocTypeDictionary where DiasType = il.DocTypeID) +
        upper(
          right(REPLICATE('0', 20) + 
            replace(replace(replace(
              rtrim(il.DocSeries) + rtrim(il.NumDoc)
            ,'-', ''), 'N', ''), ' ', '') 
          , 20)
        ) +
        c.NumCode
      from tInstLicense il
        join tInstitution i
          on i.InstitutionID = il.InstitutionID
        join tCountry c
          on i.CountryID = c.CountryID
      where il.InstitutionID = @PayerResourceOwner
        and il.[Type] = 0
        and il.isDefault = 1
    end
    else
    begin

      declare
        @Citizenship numeric(15,0),
        @CasDealTransactID numeric(15,0),
        @DocSeries varchar(35),
        @DocNumber varchar(35),
        @CashDocTypeID numeric(15,0),
        @NumCode varchar(3)

      select top 1 @CasDealTransactID = dt.DealTransactID
      from tDealTransact dt
        join tResource r
          on r.ResourceID = dt.ResourceID
          and left(r.Brief, 5) = '20202'
      where dt.ResourcePsvID = @PayerResourceID
      order by dt.Date desc

      exec TDocumentCas_F_Select
        @DealTransactID = @CasDealTransactID,
        @Citizenship = @Citizenship output,
        @CashDocSeries = @DocSeries output,
        @CashDocNumber = @DocNumber output,
        @CashDocTypeID = @CashDocTypeID output

      select @NumCode = c.NumCode
      from tCountry c
      where c.CountryID = @Citizenship

      select top 1
        @PayerIdentifier = 
          (select GisGmpType from @DocTypeDictionary where DiasType = @CashDocTypeID) +
          upper(
            replace(replace(replace(
              right(REPLICATE('0', 20) + rtrim(@DocSeries) + rtrim(@DocNumber), 20)
            ,'-', ''), 'N', ''), ' ', '') 
          ) +
          @NumCode
    end
  end
  else if @PayerType = @IP
  begin

    select @PayerIdentifier = '4' + rtrim(@InnIn)

  end
  else if @PayerType = @U_REZIDENT
  begin

    select @PayerIdentifier = '2' + rtrim(@InnIn) + rtrim(@KppIn)

  end
  else if @PayerType = @U_NOT_REZIDENT
  begin

    select @PayerIdentifier = '3' + rtrim(@InnIn) + rtrim(@KppIn)

  end
end

go
grant exec on gisgmp_sp_GeneratePayerIdentifier to public