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
    raiserror('������ ���������� ��������� TDocumentPlat_F_Select', 18, -1)
    return
  end

  declare @PayerIdentifier varchar(25)

  exec @RetVal = gisgmp_sp_GeneratePayerIdentifier 
    @DealTransactID = @DealTransactID,
    @PayerIdentifier = @PayerIdentifier output

  if @RetVal <> 0
  begin
    raiserror('������ ���������� ��������� gisgmp_sp_GeneratePayerIdentifier', 18, -1)
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
      /* ���. � ������ ���������� ��� ����������� �������� �0� */
      [pi:SupplierBillID] = isnull(@UIN, 0),
      /* ���������� ������� */
      [pi:Narrative]      = isnull(@Comment, ''), 
      /* ����� �������. ����� �����, ������������ ����� � �������� */
      [pi:Amount]         = cast(@Qty * 100 as bigint),
      /*
        ���� ����������� ������������ � ���� �����������.
        ����������� ��� ���������� � ������ ����������� ������������� ��������� �����������
      */
      --[pi:ReceiptDate]    = '', 
      /* ���� � ����� ������ � ���������� ������������ ����������� */
      [pi:PaymentDate]    = convert(varchar, @InDateTime, 126) + 'Z', 
      /* ��������� ������� 101, 106-110, ��������������� �������� ������� ������ �� 12 ������ 2013 �. �107� */
      [pi:BudgetIndex] = @BudgetIndex, 
      /* ������, ����������� ��� ������������� ������������ � �������� �������� ������� */
      [pi:PaymentIdentificationData] = @PaymentIdentificationData, 
      
      /* ��������� ���������� ��������� */
      /* ����� ���������� ��������� */
      --[AccDoc/AccDocNo] = '1', 
      /* ���� ���������� ��������� */
      --[AccDoc/AccDocDate] = '19000101', 
      /* C������� � ����������� */
      /* ������������� �����������. �������� ������������ �������������� ����������� ������ � ������ 3.1.3 */
      [pi:Payer/com:PayerIdentifier] = @PayerIdentifier,
      /* ������������ �����������. ����������� ������ ��� ������������-�� */
      --[Payer/PayerName] = '', 
      /* ����� ����� ����������� (��� �������) �  �����������, ��������� ������ */
      --[PayerAccount] = '', 

      /* �������� � ���������� ������� */
      /* 
        ������������ ���������� ������� � ���� ����������, ������������ � ��������� ������������ 
        ������������ � �������� �������� �������, �� ����������� ���, ��� 
      */
      [pi:Payee/pi:PayeeName] = rtrim(ltrim(@NameOut)), 
      /* ��� ���������� ������� */
      [pi:Payee/pi:payeeINN] = @InnOut, 
      /* ��� ���������� ������� */
      [pi:Payee/pi:payeeKPP] = @KppOut, 
      /* ���������  ����� ���������� ������� */
      [pi:Payee/pi:PayeeBankAcc] = @AccountType,

      /* �������������� ���� ������� */
      /* ������������ ���� */
      --[pi:AdditionalData/pi:Name] = '', 
      /* �������� ���� */
      --[pi:AdditionalData/pi:Value] = '',
      /*
        ������������� ���������� ������ / �����������. 
        �������� ������������ �������������� ���������� ������ ��������� � ���������� ������������ 
        �������������� �����������, ���������� � ������ 3.2. ����������� � ������, 
        ���� ���������� �� �������� ����������� ������
      */
      --[pi:RecipientServicesIdentifier] = '', 
      /* �������������� ������������� ���������� ������ � ������� ������� ���������� ������� */
      --[pi:PayerPA] = '', 

      /* �������� � ������� ������� � ���������� ��� ��������� */
      /* ������, ���������� ��������� ������ �������. ��������� ��������: 1 � �����; 2 � ���������; 3 � ������������� */
      [pi:ChangeStatus/@meaning] = isnull(@Meaning, 1), 
      /* ��������� ���������. �������� �������� ������������, ���� meaning= �3� */
      [pi:ChangeStatus/pi:Reason] = 
        case
          when isnull(@Meaning, 1) = 1 then null
          else @Reason
        end, 
      /*
        ��� ��� ��������������� ���, ���������� � 1 - 17 �������� ����, 
        � 18 - 20 �������� - ��� ������������� �������� ������� ���������������� ���������� 
        ��������� ������������� ���������� ���������. � ������ ���������� ������� ��������� �������� �0�
      */
      [pi:KBK] = isnull(nullif(@Kbk, ''), '0'), 
      /*
        ��� ��������. ����������� ���� ���������� ���������. 
        ��������� ��������: 
          01 ���������� ���������; 
          06 - ���������� ���������; 
          02 - ��������� ����������; 
          16 - ��������� �����; 
          �� - ��������� �������� ��
      */
      --[pi:TransKind] = '',
      /* ���������� ��������. ����������� ��� ��������� ���������� */
      --[pi:TransContent] = ''
      /*
        ������� ������. ��������� ��������:
          1 - ������� ������ ������ �����������;
          2 - ��������� ��������� ������� �����������
      */
      --[pi:PaytCondition] = '', 
      /* ���������� ���� ��� ��������� ������� ����������� */
      --[pi:AcptTerm] = '',
      /* ��������� ����� ������� */
      --[pi:MaturityDate] = '', 
      /*
        ���� ������� (��������) ����������� ���������� � ������,
        ���� ��� ��������� ���� �������� (�������) ����������� ������� �����������
      */
      --[pi:DocDispatchDate] = '',

      /* ���������� � ��������� ������� */
      /*
        ����� ���������� �������. ������������� �������� ���������������� ��������� ������������, 
        �� �������� �������������� ��������� ����������
      */
      --[pi:PartialPayt/pi:PaytNo] = '',
      /* ��� ��������. ������������� ���� ������������ ������������ */
      --[pi:PartialPayt/pi:TransKind] = '',
      /* ����� ������� ������� */
      --[pi:PartialPayt/pi:SumResidualPayt] = '', 
      
      /* ��������� ���������� ��������� �� �������� �������������� ��������� ���������� */
      /* ����� ���������� ���������, �� �������� �������������� ��������� ���������� */
      --[pi:PartialPayt/pi:AccDoc/pi:AccDocNo] = '', 
      /* ���� ���������� ���������, �� �������� �������������� ��������� ���������� */
      --[pi:PartialPayt/pi:AccDoc/pi:AccDocDate] = '', 
      /* ����������� �������. ��������� ��������: 0, 1-6 */
      --[pi:PartialPayt/pi:Priority] = '', 
      /*
        ��� �����, ��������� � ������������ � �������� �������� �������.
        � ������ ���������� ������� ��������� �������� �0�, � �����  � ������ ������������ ��������� 
        ��� ������ �������� �������� ������� � ����� ���������� �������, ������� ��������� �������� �0�
      */
      [pi:OKTMO] = isnull(nullif(@OKATO, ''), '0') 
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_Payment to public
grant alter on gisgmp_sp_Payment to <system_owner>