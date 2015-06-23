create procedure gisgmp_sp_orgExternalType
  @Code varchar(9),
  @Name varchar(256),
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  WITH XMLNAMESPACES ('http://smev.gosuslugi.ru/rev120315' as [smev])
  select @Xml = (
    select
      /*
        ������������� �������.
        ����� ������� ����� ���������� ������������ ������� � ������������ ������� ����.
        ����������� � ������������ � ������������� �������������� ������ 2.5.6.
      */
      [smev:Code] = @Code, 
      /*
        ������������ �������.
        ����� �������� ����� ���������� ������������ ������� � ������������ ������� ����.
        ����������� � ������������ � ������������� �������������� ������ 2.5.6.
      */
      [smev:Name] = @Name
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go
grant exec on gisgmp_sp_orgExternalType to public
grant alter on gisgmp_sp_orgExternalType to <system_owner>