{%REGION Inventory}

{NOTE: TL1 don't have it}
{TODO: don't rewrite inventory}

function AddInventoryToBase(ams:pointer; aId:UInt32; const aname:string; isContainer:boolean):integer;
var
  vm:pointer;
  lid,lcont,lSQL:string;
  lupdate:boolean;
begin
  if isContainer then lcont:='1' else lcont:='0';

  Str(aId,lid);
  lupdate:=true;
  lSQL:='SELECT COUNT(*) FROM inventory '+
        'WHERE (id='+lid+') AND (name='''+aname+''') AND (isContainer='+lcont+')';
  if sqlite3_prepare_v2(PModScanner(ams)^.db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      lupdate:=sqlite3_column_int(vm,0)=0; //!! was ">0"
    sqlite3_finalize(vm);
  end;

  if lupdate then
  begin
    lSQL:='REPLACE INTO inventory (id, name, isContainer) VALUES ('+
          lid+', '+FixedText(aname)+', '+lcont+')';
    if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
      result:=1
    else
      result:=0;
  end
  else
    result:=-1;
end;

function AddInventoryNode(ams:pointer; anode:pointer; isContainer:boolean):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  lname:string;
  i,lmask:integer;
  lid:UInt32;
begin
  lmask:=0;
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    pcw:=GetNodeName(lnode);
    if CompareWide(pcw,'NAME')=0 then
    begin
      lmask:=lmask or 1;
      lname:=AsString(lnode);
    end
    else if CompareWide(pcw,'UNIQUEID')=0 then
    begin
      lmask:=lmask or 2;
      lid:=AsUnsigned(lnode);
    end;
    if lmask=3 then
      Exit(AddInventoryToBase(ams,lid,lname,isContainer));
  end;
  result:=0;
end;

function ProcessInventory(
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
      result:=AddInventoryNode(aparam,p,Pos('MEDIA/INVENTORY/CONTAINERS',adir)>0);
           if result>0 then result:=1
      else if result<0 then result:=0
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanInventory(ams:pointer):integer;
begin
  if PModScanner(ams)^.gamever=verTL1 then
  begin
    RGLog.Add('TL1 don''t support Inventory setup');
    exit(0);
  end;

  if RGDebugLevel<>dlNone then RGLog.Add('Scanning inventory');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/INVENTORY', @ProcessInventory);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateInventoryTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'inventory') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE inventory ('+
      '  id          INTEGER,'+
      '  name        TEXT,'+
      '  iscontainer INTEGER (1));')
  else
    result:=true;
end;

{%ENDREGION Inventory}
