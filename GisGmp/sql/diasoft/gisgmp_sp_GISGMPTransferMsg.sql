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
    @SenderCode varchar(9),
    @SenderName varchar(256),
    @Sender xml,
    @RecipientCode varchar(9),
    @RecipientName varchar(256),
    @Recipient xml,
    @Originator xml,
    @Service xml

  select @SenderCode = Value from gisgmp_t_Config where Name = 'sender_code'
  select @SenderName = Value from gisgmp_t_Config where Name = 'sender_name'

  exec gisgmp_sp_orgExternalType
    @Code = @SenderCode,
    @Name = @SenderName,
    @Xml = @Sender output;

  select @RecipientCode = Value from gisgmp_t_Config where Name = 'recipient_code'
  select @RecipientName = Value from gisgmp_t_Config where Name = 'recipient_name'

  exec gisgmp_sp_orgExternalType
    @Code = @RecipientCode,
    @Name = @RecipientName,
    @Xml = @Recipient output;

  WITH XMLNAMESPACES ('http://smev.gosuslugi.ru/rev120315' as [smev],
    'http://roskazna.ru/gisgmp/xsd/116/Message' as [gisgmp])
  select @Xml = (
    select
      /* Служебный блок атрибутов СМЭВ */
      /*
        Данные о системе-инициаторе взаимодействия.
        Указывается информация об ИС участника, обращающегося в ГИС ГМП
      */
      [smev:Message/smev:Sender] = @Sender,
      /* Данные о системе-получателе сообщения. Указывается идентификатор и наименование ГИС ГМП */
      [smev:Message/smev:Recipient] = @Recipient,
      /*
        Данные о системе, инициировавшей цепочку из нескольких запросов-ответов,
        объединенных единым процессом в рамках взаимодействия.
        Заполняется в соответствии с Методическими рекомендациями версии 2.5.6.
        ГИС ГМП не регламентируется порядок заполнения данного тега
      */
      --[smev:Message/smev:Originator] = @Originator 
      /*
        Мнемоника электронного сервиса ГИС ГМП. 
        Будет уточнена после публикации электронного сервиса в промышленном контуре СМЭВ. 
        Наличие этого тега исключает тег Service
      */
      [smev:Message/smev:ServiceName] = (select Value from gisgmp_t_Config where Name = 'service_name'), 
      /*
        Данные об электронном сервисе ГИС ГМП. 
        Будут уточнены после публикации электронного сервиса в промышленном контуре СМЭВ. 
        Наличие этого тега исключает тег ServiceName
      */
      --[smev:Message/smev:Service] = @Service,
      /* Тип сообщения. Заполняется в соответствии с методическими рекомендациями версии 2.5.6 */
      [smev:Message/smev:TypeCode] = (select Value from gisgmp_t_Config where Name = 'code_type'),
      /* Статус сообщения. Принимает значение «REQUEST» */
      [smev:Message/smev:Status] = 'REQUEST',
      /* Дата создания сообщения. Заполняется в соответствии с Методическими рекомендациями версии 2.5.6 */
      [smev:Message/smev:Date] = convert(varchar, getdate(), 126) + 'Z',
      /* Категория взаимодействия. Заполняется в соответствии с Методическими рекомендациями версии 2.5.6 */
      [smev:Message/smev:ExchangeType] = '5', 
      /* Признак тестового взаимодействия. Заполняется в соответствии с методическими рекомендациями версии 2.5.6 */
      [smev:Message/smev:TestMsg] = @Test,

      /* Блок-обертка данных СМЭВ */
      /* Блок структурированных сведений */
      /* Идентификатор сообщения */
      [smev:MessageData/smev:AppData/gisgmp:RequestMessage/@Id] = 'ID_' + cast(newid() as varchar(36)), 
      /* Дата и время формирования сообщения*/
      [smev:MessageData/smev:AppData/gisgmp:RequestMessage/@timestamp] = convert(varchar, getdate(), 126) + 'Z', 
      /* УРН участника-отправителя сообщения */
      [smev:MessageData/smev:AppData/gisgmp:RequestMessage/@senderIdentifier] = (select Value from gisgmp_t_Config where Name = 'urn'), 
      [smev:MessageData/smev:AppData/gisgmp:RequestMessage] = @RequestMessage
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_GISGMPTransferMsg to public