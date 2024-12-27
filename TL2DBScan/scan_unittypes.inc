{%REGION UnitTypes}
function AddUnittypeToBase(ams:pointer; const aname, achild:string):boolean;
var
  lmodid,lSQL:string;
begin
  result:=false;

  lmodid:=CheckNamePlusForMod(ams,'unittypes', aname, 'child='''+achild+'''');
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO unittypes (name, modid, child) VALUES ('''+
        aname+''', '+lmodid+', '''+achild+''')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;

end;

function AddUnittypeNode(ams:pointer; anode:pointer):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  lname,lchild:string;
  i:integer;
begin
  result:=0;

  lname :='';
  lchild:=',';

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    pcw:=GetNodeName(lnode);
    if CompareWide(pcw,'NAME' )=0 then
      lname:=AsString(lnode)
    else
      lchild:=lchild+FastWideToStr(AsString(lnode))+',';
  end;
  if lname='' then lname:=GetNodeName(anode);

  if AddUnitTypeToBase(ams,lname,lchild) then
    result:=1;
end;

function ProcessUnittypes(
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
      if AddUnitTypeNode(aparam,p)>0 then
        result:=1
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanUnitTypeHie(ams:pointer; anode:pointer):integer;
var
  larr:array [0..511] of string;
  lname,lchild:string;
  lnode,llnode,lunode:pointer;
  pcw:PWideChar;
  lid,i,j,k:integer;
  lmask:integer;
begin
  result:=0;
  fillchar(larr,SizeOf(larr),0);

  // 1 cycle, fill array
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    if GetNodeType(lnode)=rgGroup then
    begin
      if CompareWide(GetNodeName(lnode),'UNITTYPES')=0 then
      begin
        for j:=0 to GetChildCount(lnode)-1 do // unittype
        begin
          lname :='';
          lid   :=-1;
          lmask :=0;
          llnode:=GetChild(lnode,j);
          for k:=0 to GetChildCount(llnode)-1 do
          begin
            lunode:=GetChild(llnode,k);
            pcw:=GetNodeName(lunode);
            if CompareWide(pcw,'ID')=0 then
            begin
              lmask:=lmask or 1;
              lid :=AsInteger(lunode)
            end
            else if CompareWide(pcw,'NAME' )=0 then
            begin
              lmask:=lmask or 2;
              lname:=AsString(lunode);
            end;
 
            if lmask=3 then break;
          end;
          if lname='' then lname:=GetNodeName(llnode);
          if (lid>=0) and (lid<512) then larr[lid]:=UpCase(lname);
        end;
        break;
      end;
    end;
  end;

  // 2 cycle, fill base
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    if GetNodeType(lnode)=rgGroup then
    begin
      if CompareWide(GetNodeName(lnode),'UNITTYPES')=0 then
      begin
        for j:=0 to GetChildCount(lnode)-1 do // unittype
        begin
          lchild:=',';
          lname :='';
          llnode:=GetChild(lnode,j);
          for k:=0 to GetChildCount(llnode)-1 do
          begin
            lunode:=GetChild(llnode,k);
            pcw:=GetNodeName(lunode);
            if CompareWide(pcw,'NAME' )=0 then lname:=AsString(lunode)
            else if CompareWide(pcw,'ID')<>0 then
            begin
              lid:=AsInteger(lunode);
              if (lid>=0) and (lid<512) then
                lchild:=lchild+larr[lid]+',';
            end;
          end;
          if lname='' then lname:=GetNodeName(llnode); // larr[lid]
          lchild:=','+UpCase(lname)+lchild;            // use to avoid additional name check
          if AddUnitTypeToBase(ams,lname,lchild) then
            inc(result)
          else if RGDebugLevel=dlDetailed then
            RGLog.Add('can''t add unittype '+lname);
        end;
        break;
      end;
    end;
  end;
end;

function ScanUnitTypes(ams:pointer):integer;
var
  p:pointer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning unittypes');

  LoadFile(ams,'MEDIA/UNITTYPES.HIE',p);
  if (p=nil) and (PModScanner(ams)^.gamever=verTL1) then
    LoadFile(ams,'MEDIA/UNITTYPES.HIE.ADM',p);
  
  result:=0;
  if p<>nil then
  begin
    result:=ScanUnitTypeHie(ams,p);
    DeleteNode(p);
  end;

  result:=result+DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITTYPES', @ProcessUnittypes);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateUnittypesTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'unittypes') then
    ExecuteDirect(adb,
      'CREATE TABLE unittypes ('+
      '  name  TEXT,'+
      '  modid TEXT,'+
      '  child TEXT);')
  else
    result:=true;
end;

{%ENDREGION UnitTypes}
