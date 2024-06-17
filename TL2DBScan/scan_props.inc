{%REGION Props}

function AddPropToBase(ams:pointer; const anid,aname,atitle,aquest:string):boolean;
var
  lmodid,lSQL:string;
begin
  result:=false;

  lmodid:=CheckIdForMod(ams,'props', anid);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO props (id, name, title, quest, modid) VALUES ('+
        anid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+
        aquest+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddPropNode(ams:pointer; anode:pointer; isquest:boolean):boolean;
var
  lnode:pointer;
  pcw:PWideChar;
  lid,lname,ltitle,lquest:string;
  i:integer;
begin
  ltitle:='';
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    pcw:=GetNodeName(lnode);
    if      CompareWide(pcw,'NAME'       )=0 then lname :=AsString(lnode)
    else if CompareWide(pcw,'DISPLAYNAME')=0 then ltitle:=AsString(lnode)
    else if CompareWide(pcw,'UNIT_GUID'  )=0 then lid   :=AsString(lnode);
{
    else if (lquest='0') and (CompareWide(p^.children^[i].name,'UNITTYPE')=0) then
    begin
    end
}
  end;
  if isquest then lquest:='1' else lquest:='0';
  result:=AddPropToBase(ams,lid,lname,ltitle,lquest);
end;

function ProcessProps(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p:pointer;
begin
  result:=sres_fail;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      if AddPropNode(aparam,p,Pos('MEDIA/UNITS/PROPS/QUESTPROPS',adir)>0) then
        result:=1
      else if PModScanner(aparam)^.FLogLevel>1 then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanProps(ams:pointer):integer;
begin
  if PModScanner(ams)^.FLogLevel>0 then RGLog.Add('Scanning props');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/PROPS', @ProcessProps);
  if PModScanner(ams)^.FLogLevel>0 then RGLog.Add(IntToStr(result)+' records added');
end;

function CreatePropsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'props') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE props ('+
      '    id    INTEGER     PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT,'+
      '    quest INTEGER (1) );')
  else
    result:=true;
end;

{%ENDREGION}
