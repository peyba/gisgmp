create procedure gisgmp_sp_Payment
  @DealTransactID numeric(15, 0),
  @UIN varchar(255) = null,
  @Meaning int = null,
  @Reason varchar(255) = null,
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */


  declare
    @RetVal int,
    @Kbk varchar(255),
    @OKATO varchar(255),
    @KppOut varchar(9),
    @InnOut varchar(15),
    @NameOut varchar(255),
    @Comment varchar(255),
    @Qty numeric(28, 10),
    @InDateTime datetime,
    @BudgetIndex xml,
    @PaymentIdentificationData xml,
    @AccountType xml

  exec @RetVal = TDocumentPlat_F_Select
    @DealTransactID = @DealTransactID,
    @Kbk = @Kbk output,
    @OKATO = @OKATO output,
    @KppOut = @KppOut output,
    @InnOut = @InnOut output,
    @NameOut = @NameOut output,
    @Comment = @Comment output,
    @Qty = @Qty output,
    @InDateTime = @InDateTime output

  if @RetVal <> 0
  begin
    raiserror('Ошибка выполнения процедуры TDocumentPlat_F_Select', 18, -1)
    return
  end

  declare @PayerIdentifier varchar(25)

  exec @RetVal = gisgmp_sp_GeneratePayerIdentifier 
    @DealTransactID = @DealTransactID,
    @PayerIdentifier = @PayerIdentifier output

  if @RetVal <> 0
  begin
    raiserror('Ошибка выполнения процедуры gisgmp_sp_GeneratePayerIdentifier', 18, -1)
    return
  end

  exec gisgmp_sp_BudgetIndexType
    @DealTransactID = @DealTransactID,
    @Xml = @BudgetIndex output;  

  exec gisgmp_sp_PaymentIdentificationDataType
    @DealTransactID = @DealTransactID,
    @Xml = @PaymentIdentificationData output; 

  exec gisgmp_sp_AccountType
    @DealTransactID = @DealTransactID,
    @Xml = @AccountType output;

  WITH XMLNAMESPACES (
    'http://roskazna.ru/gisgmp/xsd/116/PaymentInfo' as [pi],
    'http://roskazna.ru/gisgmp/xsd/116/Common' as [com])
  select @Xml = (
    select
      /* attrs */
      --[@Id] = 'A_' + cast(newid() as varchar(36)),

      /* nodes */
      /* УИН. В случае отсутствия УИН указывается значение «0» */
      [pi:SupplierBillID] = isnull(@UIN, 0),
      /* Назначение платежа */
      [pi:Narrative]      = isnull(@Comment, ''), 
      /* Сумма платежа. Целое число, показывающее сумму в копейках */
      [pi:Amount]         = cast(@Qty * 100 as bigint),
      /*
        Дата поступления распоряжения в банк плательщика.
        Обязательно для заполнения в случае поступления распоряженияв кредитную организацию
      */
      --[pi:ReceiptDate]    = '', 
      /* Дата и время приема к исполнению распоряжения плательщика */
      [pi:PaymentDate]    = convert(varchar, @InDateTime, 126) + 'Z', 
      /* Реквизиты платежа 101, 106-110, предусмотренные приказом Минфина России от 12 ноября 2013 г. №107н */
      [pi:BudgetIndex] = @BudgetIndex, 
      /* Данные, необходимые для идентификации распоряжения о переводе денежных средств */
      [pi:PaymentIdentificationData] = @PaymentIdentificationData, 
      
      /* Реквизиты платежного документа */
      /* Номер платежного документа */
      --[AccDoc/AccDocNo] = '1', 
      /* Дата платежного документа */
      --[AccDoc/AccDocDate] = '19000101', 
      /* Cведения о плательщике */
      /* Идентификатор плательщика. Алгоритм формирования идентификатора плательщика описан в пункте 3.1.3 */
      [pi:Payer/com:PayerIdentifier] = @PayerIdentifier,
      /* Наименование плательщика. Указывается только для плательщиков-ЮЛ */
      --[Payer/PayerName] = '', 
      /* Номер счета плательщика (при наличии) в  организации, принявшей платеж */
      --[PayerAccount] = '', 

      /* Сведения о получателе средств */
      /* 
        Наименование получателя средств и иная информация, содержащаяся в реквизите «Получатель» 
        распоряжения о переводе денежных средств, за исключением ИНН, КПП 
      */
      [pi:Payee/pi:PayeeName] = rtrim(ltrim(@NameOut)), 
      /* ИНН получателя средств */
      [pi:Payee/pi:payeeINN] = @InnOut, 
      /* КПП получателя средств */
      [pi:Payee/pi:payeeKPP] = @KppOut, 
      /* Реквизиты  счета получателя средств */
      [pi:Payee/pi:PayeeBankAcc] = @AccountType,

      /* Дополнительные поля платежа */
      /* Наименование поля */
      --[pi:AdditionalData/pi:Name] = '', 
      /* Значение поля */
      --[pi:AdditionalData/pi:Value] = '',
      /*
        Идентификатор получателя услуги / плательщика. 
        Алгоритм формирования идентификатора получателя услуги совпадает с алгоритмом формирования 
        идентификатора плательщика, описанного в пункте 3.2. Заполняется в случае, 
        если плательщик не является получателем услуги
      */
      --[pi:RecipientServicesIdentifier] = '', 
      /* Дополнительный идентификатор получателя услуги в учетной системе получателя средств */
      --[pi:PayerPA] = '', 

      /* Сведения о статусе платежа и основаниях его изменения */
      /* Статус, отражающий изменение данных платежа. Возможные значения: 1 — новое; 2 — уточнение; 3 — аннулирование */
      [pi:ChangeStatus/@meaning] = isnull(@Meaning, 1), 
      /* Основание изменения. Указание является обязательным, если meaning= «3» */
      [pi:ChangeStatus/pi:Reason] = 
        case
          when isnull(@Meaning, 1) = 1 then null
          else @Reason
        end, 
      /*
        КБК или двадцатизначный код, содержащий в 1 - 17 разрядах нули, 
        в 18 - 20 разрядах - код классификации операций сектора государственного управления 
        бюджетной классификации Российской Федерации. В случае отсутствия следует указывать значение «0»
      */
      [pi:KBK] = isnull(nullif(@Kbk, ''), '0'), 
      /*
        Вид операции. Указывается шифр платежного документа. 
        Возможные значения: 
          01 –платежное поручение; 
          06 - инкассовое поручение; 
          02 - платежное требование; 
          16 - платежный ордер; 
          ПД - платежный документ ФЛ
      */
      --[pi:TransKind] = '',
      /* Содержание операции. Указывается при частичном исполнении */
      --[pi:TransContent] = ''
      /*
        Условие оплаты. Возможные значения:
          1 - заранее данный акцепт плательщика;
          2 - требуется получение акцепта плательщика
      */
      --[pi:PaytCondition] = '', 
      /* Количество дней для получения акцепта плательщика */
      --[pi:AcptTerm] = '',
      /* Окончание срока акцепта */
      --[pi:MaturityDate] = '', 
      /*
        Дата отсылки (вручения) плательщику документов в случае,
        если эти документы были отосланы (вручены) получателем средств плательщику
      */
      --[pi:DocDispatchDate] = '',

      /* Информация о частичном платеже */
      /*
        Номер частичного платежа. Соответствует значению соответствующего реквизита распоряжения, 
        по которому осуществляется частичное исполнение
      */
      --[pi:PartialPayt/pi:PaytNo] = '',
      /* Вид операции. Проставляется шифр исполняемого распоряжения */
      --[pi:PartialPayt/pi:TransKind] = '',
      /* Сумма остатка платежа */
      --[pi:PartialPayt/pi:SumResidualPayt] = '', 
      
      /* Реквизиты платежного документа по которому осуществляется частичное исполнение */
      /* Номер платежного документа, по которому осуществляется частичное исполнение */
      --[pi:PartialPayt/pi:AccDoc/pi:AccDocNo] = '', 
      /* Дата платежного документа, по которому осуществляется частичное исполнение */
      --[pi:PartialPayt/pi:AccDoc/pi:AccDocDate] = '', 
      /* Очередность платежа. Возможные значения: 0, 1-6 */
      --[pi:PartialPayt/pi:Priority] = '', 
      /*
        Код ОКТМО, указанный в распоряжении о переводе денежных средств.
        В случае отсутствия следует указывать значение «0», а также  в случае формирования извещения 
        при приеме наличных денежных средств в кассу получателя платежа, следует указывать значение «0»
      */
      [pi:OKTMO] = isnull(nullif(@OKATO, ''), '0') 
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_Payment to public