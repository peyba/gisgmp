create procedure gisgmp_sp_BudgetIndexType
  @DealTransactID numeric(15, 0),
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  declare
    @StatusSostav int,
    @TaxBase varchar(255),
    @TaxPeriod varchar(255),
    @TaxNumberDoc varchar(255),
    @TaxDate varchar(255),
    @TaxType varchar(255)

  exec TDocumentPlat_F_Select
    @DealTransactID = @DealTransactID,
    @StatusSostav = @StatusSostav output,
    @TaxBase = @TaxBase output,
    @TaxPeriod = @TaxPeriod output,
    @TaxNumberDoc = @TaxNumberDoc output,
    @TaxDate = @TaxDate output,
    @TaxType = @TaxType output;

  WITH XMLNAMESPACES ('http://roskazna.ru/gisgmp/xsd/116/BudgetIndex' as [bdi])
  select @Xml = (
    select
       /* Статус плательщика — реквизит 101 Распоряжения */
      [bdi:Status] = right('0' + isnull(nullif(cast(@StatusSostav as varchar(2)), ''), '00'), 2),
      /* Показатель основания платежа — реквизит 106 Распоряжения */
      [bdi:Purpose] = isnull(nullif(@TaxBase, ''), '0'),
      /* Налоговый период или код таможенного органа — реквизит 107 Распоряжения */
      [bdi:TaxPeriod] =
        case isnull(nullif(@TaxPeriod, ''), '0')
          when '0' then '0'
          else
            case
              when left(@TaxPeriod, 2) in ('МС', 'КВ', 'ПЛ', 'ГД') then left(@TaxPeriod, 2) + '.' + substring(@TaxPeriod, 3, 2) + '.' + right(@TaxPeriod, 4)
              else @TaxPeriod
            end
        end,
      /* Показатель номера документа — реквизит 108 Распоряжения */
      [bdi:TaxDocNumber] = isnull(nullif(@TaxNumberDoc, ''), '0'),
      /* Показатель даты документа — реквизит 109 Распоряжения */
      [bdi:TaxDocDate] =
        case isnull(nullif(nullif(@TaxDate, ''), '00000000'), '0')
          when  '0' then '0'
          else left(@TaxDate, 2) + '.' + substring(@TaxDate, 3, 2) + '.' + right(@TaxDate, 4)
        end,
      /* Показатель типа платежа — реквизит 110 Распоряжения */
      [bdi:PaymentType] = isnull(nullif(@TaxType, ''), '0')
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_BudgetIndexType to public
grant alter on gisgmp_sp_BudgetIndexType to <system_owner>