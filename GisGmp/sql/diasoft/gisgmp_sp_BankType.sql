create procedure gisgmp_sp_BankType
  @BankID numeric(15, 0),
  @Xml xml output
as

  /* BEGIN ARITHABORT */
  DECLARE @ARITHABORT VARCHAR(3)
  SET @ARITHABORT = 'OFF';
  IF ( (64 & @@OPTIONS) = 64 ) SET @ARITHABORT = 'ON';
    
  if @ARITHABORT = 'OFF' SET ARITHABORT ON
  /* END ARITHABORT */

  WITH XMLNAMESPACES ('http://roskazna.ru/gisgmp/xsd/116/Organization' as [org])
  select @Xml = (
    select
      /*
        ������������ ������������ ���������������������� ����������� 
        ���  ������������� ����� ������, � ������� ������ ����
      */
      --[org:Name] = '',
      /*
        ��� ������������ �������������  ��������� ����������� ���
        ������������� ����� ������, � ������� ������ ����. 
        ������� ����� ���� ��������� ��� SWIFT 
      */ 
      [org:BIK] = 
        case
          when i.MainMember = 1 then ltrim(rtrim(i.BIC))
          else null
        end,
      /*
        ��� SWIFT ������������ �����, � ������� ������ ����. 
        ������� ����� ���� ��������� ��� BIK
      */
      [org:SWIFT] =
        case
          when i.MainMember = 0 then ltrim(rtrim(i.SWIFT))
          else null
        end
    from tInstitution i
    where i.InstitutionID = @BankID
    FOR XML PATH(''), ELEMENTS
  )

  if @ARITHABORT = 'OFF' SET ARITHABORT OFF

  return;

go

grant exec on gisgmp_sp_BankType to public
grant alter on gisgmp_sp_BankType to <system_owner>