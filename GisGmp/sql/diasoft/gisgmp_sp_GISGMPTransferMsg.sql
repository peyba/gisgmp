create procedure gisgmp_sp_GISGMPTransferMsg
  @Test int = null,
  @RequestMessage xml,
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  declare
    @Sender xml,
    @Recipient xml,
    @Originator xml,
    @Service xml

  exec gisgmp_sp_orgExternalType
    @Type = 0,
    @Xml = @Sender output;

  exec gisgmp_sp_orgExternalType
    @Type = 1,
    @Xml = @Recipient output;

  WITH XMLNAMESPACES ('http://smev.gosuslugi.ru/rev120315' as [smev],
    'http://roskazna.ru/gisgmp/xsd/116/Message' as [gisgmp])
  select @Xml = (
    select
      /* ��������� ���� ��������� ���� */
      /*
        ������ � �������-���������� ��������������.
        ����������� ���������� �� �� ���������, ������������� � ��� ���
      */
      [smev:Message/smev:Sender] = @Sender,
      /* ������ � �������-���������� ���������. ����������� ������������� � ������������ ��� ��� */
      [smev:Message/smev:Recipient] = @Recipient,
      /*
        ������ � �������, �������������� ������� �� ���������� ��������-�������,
        ������������ ������ ��������� � ������ ��������������.
        ����������� � ������������ � ������������� �������������� ������ 2.5.6.
        ��� ��� �� ���������������� ������� ���������� ������� ����
      */
      --[smev:Message/smev:Originator] = @Originator 
      /*
        ��������� ������������ ������� ��� ���. 
        ����� �������� ����� ���������� ������������ ������� � ������������ ������� ����. 
        ������� ����� ���� ��������� ��� Service
      */
      [smev:Message/smev:ServiceName] = '��������� ������������ ������� ��� ���. ����� �������� ����� ���������� ������������ ������� � ������������ ������� ����', 
      /*
        ������ �� ����������� ������� ��� ���. 
        ����� �������� ����� ���������� ������������ ������� � ������������ ������� ����. 
        ������� ����� ���� ��������� ��� ServiceName
      */
      --[smev:Message/smev:Service] = @Service,
      /* ��� ���������. ����������� � ������������ � ������������� �������������� ������ 2.5.6 */
      [smev:Message/smev:TypeCode] = 'GSRV',
      /* ������ ���������. ��������� �������� �REQUEST� */
      [smev:Message/smev:Status] = 'REQUEST',
      /* ���� �������� ���������. ����������� � ������������ � ������������� �������������� ������ 2.5.6 */
      [smev:Message/smev:Date] = convert(varchar, getdate(), 126) + 'Z',
      /* ��������� ��������������. ����������� � ������������ � ������������� �������������� ������ 2.5.6 */
      [smev:Message/smev:ExchangeType] = '5', 
      /* ������� ��������� ��������������. ����������� � ������������ � ������������� �������������� ������ 2.5.6 */
      [smev:Message/smev:TestMsg] = @Test,

      /* ����-������� ������ ���� */
      /* ���� ����������������� �������� */
      /* ������������� ��������� */
      [smev:MessageData/smev:AppData/gisgmp:RequestMessage/@Id] = 'ID_' + cast(newid() as varchar(36)), 
      /* ���� � ����� ������������ ���������*/
      [smev:MessageData/smev:AppData/gisgmp:RequestMessage/@timestamp] = convert(varchar, getdate(), 126) + 'Z', 
      /* ��� ���������-����������� ��������� */
      [smev:MessageData/smev:AppData/gisgmp:RequestMessage/@senderIdentifier] = '000172', 
      [smev:MessageData/smev:AppData/gisgmp:RequestMessage] = @RequestMessage
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_GISGMPTransferMsg to public
grant alter on gisgmp_sp_GISGMPTransferMsg to <system_owner>