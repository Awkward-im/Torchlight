{%REGION Inventory}

function AddInventoryToBase(ams:pointer; aId:UInt32; const aname:string; isContainer:boolean):boolean;
var
  lcont,lSQL:string;
begin
  if isContainer then lcont:='1' else lcont:='0';
  lSQL:='REPLACE INTO inventory (id, name, isContainer) VALUES ('+
        IntToStr(aid)+', '+FixedText(aname)+', '+lcont+')';

  result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
end;

function AddInventoryNode(ams:pointer; anode:pointer; isContainer:boolean):boolean;
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
  result:=false;
end;

function ProcessInventory(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p:pointer;
begin
  result:=0;

  p:=ParseTextMem(abuf);
  if p=nil then
    p:=ParseDatMem(abuf);
  
  if p<>nil then
  begin
    if AddInventoryNode(aparam,p,Pos('MEDIA/INVENTORY/CONTAINERS',adir)>0) then
      result:=1
    else
      RGLog.Add('can''t update '+aname);

    DeleteNode(p);
  end;
end;

function ScanInventory(ams:pointer):integer;
begin
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/INVENTORY', @ProcessInventory);
end;

function CreateInventoryTable(ams:pointer):boolean;
begin
  if not IsTableExists(PModScanner(ams)^.db,'inventory') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE inventory ('+
      '  id          INTEGER,'+
      '  name        TEXT,'+
      '  iscontainer INTEGER (1));');
end;

{%ENDREGION Inventory}