{%REGION Sets}

function AddSetAffixToBase(ams:pointer; asetid, acount, alevel:integer; const aaffix:string):boolean;
var
  ls1,ls2,ls3,lmodid,lSQL:string;
begin
  result:=false;

  ls1:=IntToStr(asetid);
  ls2:=IntToStr(acount);
  ls3:=FixedText(aaffix);

  lmodid:=CheckForMod(ams,'sets',
    '      (idset='+ls1+
    ') AND (count='+ls2+
    ') AND (affix='+ls3+')');

  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO sets (idset, count, level, affix, modid) VALUES ('+
        ls1+', '+ls2+', '+IntToStr(alevel)+', '+ls3+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddSetToBase(ams:pointer; const aname,atitle:string):integer;
var
  lmodid,lSQL,ls:string;
begin
  ls:=FixedText(aname);
  lmodid:=CheckNameForMod(ams,'dicsets', aname);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO dicsets (name, title, modid) VALUES ('+
        ls+', '+FixedText(atitle)+', '+lmodid+') RETURNING id;';

    result:=ReturnInt(PModScanner(ams)^.db,lSQL);
  end
  else
    result:=ReturnInt(PModScanner(ams)^.db,'SELECT id FROM dicsets WHERE name='+ls);
end;

function AddSetNode(ams:pointer; anode:pointer; const aname:string):integer;
var
  lnode, llnode:pointer;
  pcw:PWideChar;
  lname,ltitle,laffix:string;
  lsetid,lcount,llevel,i,j:integer;
begin
  result:=0;

  lnode:=FindNode(anode,'NAME'       ); if lnode<>nil then lname :=AsString   (lnode) else lname :=aname;
  lnode:=FindNode(anode,'DISPLAYNAME'); if lnode<>nil then ltitle:=AsTranslate(lnode) else ltitle:=lname;
  lsetid:=AddSetToBase(ams, lname, ltitle);
  if lsetid<0 then exit;

  result:=$10000;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    if GetNodeType(lnode)=rgGroup then
    begin
      llevel:=0;
      lcount:=0;
      laffix:='';
      for j:=0 to GetChildCount(lnode)-1 do
      begin
        llnode:=GetChild(lnode,j);
        pcw:=GetNodeName(llnode);
        if CompareWide(pcw,'COUNT')=0 then
        begin
          lcount:=AsInteger(llnode);
        end
        else if CompareWide(pcw,'AFFIXLEVEL')=0 then
        begin
          llevel:=AsInteger(llnode);
        end
        else if CompareWide(pcw,'AFFIX')=0 then
        begin
          laffix:=AsString(llnode);
        end;
      end;
      if (lcount>1) and (laffix<>'') then
        if AddSetAffixToBase(ams, lsetid, lcount, llevel, laffix) then
          inc(result);
    end;

  end;

end;

function ProcessSets(
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
      result:=AddSetNode(aparam,p,ExtractNameOnly(aname));
      if result=0 then
        if RGDebugLevel=dlDetailed then
          RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanSets(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning sets');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/SETS', @ProcessSets);
  if RGDebugLevel<>dlNone then
    RGLog.Add('Checked '+IntToStr(result shr 16)+
        ' set records. Added '+IntToStr(result and $FFFF)+' set elements');
end;

function CreateSetsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'dicsets') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE dicsets ('+
      '  id    INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  name  TEXT,'+
      '  title TEXT,'+
      '  modid TEXT);')
  else
    result:=true;

  if result and (not IsTableExists(adb,'sets')) then
    result:=ExecuteDirect(adb,
      'CREATE TABLE sets ('+
      '  idset INTEGER,'+
      '  count INTEGER,'+
      '  level INTEGER,'+
      '  affix TEXT,'+
      '  modid TEXT);')
  else
    result:=true;
end;

{%ENDREGION Sets}
