{%REGION Items}

type
  tItemInfo = record
    id      :string;
    name    :string;
    title   :string;
    descr   :string;
    icon    :string;
    ausable :string;
    quest   :string;
    afile   :string;
    base    :string;
    unittype:string;
    stack   :string;
  end;

function AddItemToBase(ams:pointer; const aitem:tItemInfo):boolean;
var
  lmodid,lSQL,lfile,lbase:string;
  i:integer;
begin
  result:=false;

  lmodid:=CheckForMod(ams,'items', aitem.id, PModScanner(ams)^.FModId);
  if lmodid<>'' then
  begin
    lfile:=LowerCase(aitem.afile);
    for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';
    lbase:=LowerCase(aitem.base);
    for i:=1 to Length(lbase) do if lbase[i]='\' then lbase[i]:='/';

    lSQL:='REPLACE INTO items (id, name, title, descr, icon, usable, quest, unittype, stack,'+
          ' file, base, modid) VALUES ('+
        aitem.id+', '+FixedText(aitem.name)+', '+FixedText(aitem.title)+', '+FixedText(aitem.descr)+
        ', '+FixedText(aitem.icon)+', '+aitem.ausable+', '+aitem.quest+', '+FixedText(aitem.unittype)+
        ', '+aitem.stack+', '+FixedText(lfile)+', '+FixedText(lbase)+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function GetBaseUnitType(ams:pointer; const fname:string):string;
var
  p,lnode:pointer;
  pcw:PWideChar;
  lbase:string;
  i:integer;
begin
{
  'SELECT unittype FROM items WHERE file='+fname
}
  
  result:='';
  lbase :='';

  LoadFile(ams,fname,p);
  if p=nil then
  begin
    if PModScanner(ams)^.FLogLevel>1 then
      RGLog.Add('can''t load: '+fname);
    exit;
  end;

  for i:=0 to GetChildCount(p)-1 do
  begin
    lnode:=GetChild(p,i);
    pcw:=GetNodeName(lnode);
    if CompareWide(pcw,'UNITTYPE')=0 then
    begin
      result:=AsString(lnode);
      break;
    end;
    if CompareWide(pcw,'BASEFILE')=0 then
    begin
      lbase:=AsString(lnode);
    end;
  end;

  if (result='') and (lbase<>'') then
    result:=GetBaseUnitType(ams,lbase);

  DeleteNode(p);
end;

function GetBaseIcon(ams:pointer; const fname:string):string;
var
  p,lnode:pointer;
  pcw:PWideChar;
  lbase:string;
  i:integer;
begin
  result:='';
  lbase :='';

  LoadFile(ams,fname,p);
  if p=nil then
  begin
    if PModScanner(ams)^.FLogLevel>1 then
      RGLog.Add('can''t load: '+fname);
    exit;
  end;

  for i:=0 to GetChildCount(p)-1 do
  begin
    lnode:=GetChild(p,i);
    pcw:=GetNodeName(lnode);
    if CompareWide(pcw,'ICON')=0 then
    begin
      result:=AsString(lnode);
      break;
    end;
    if (result='') and (CompareWide(pcw,'GAMBLER_ICON')=0) then
    begin
      result:=AsString(lnode);
    end;
    if CompareWide(pcw,'BASEFILE')=0 then
    begin
      lbase:=AsString(lnode);
    end;
  end;

  if (result='') and (lbase<>'') then
    result:=GetBaseIcon(ams,lbase);

  DeleteNode(p);
end;

function AddItemNode(ams:pointer; anode:pointer; const fname:string; aquest:boolean):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  litem:tItemInfo;
  i:integer;
begin
  result:=0;

  litem.title  :='';
  litem.ausable:='0';
  litem.base   :='';
  litem.afile  :=fname;
  litem.stack  :='1';

  if aquest then litem.quest:='1' else litem.quest:='0';

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    pcw:=GetNodeName(lnode);
    if      CompareWide(pcw,'NAME'        )=0 then litem.name   :=AsString(lnode)
    else if CompareWide(pcw,'DISPLAYNAME' )=0 then litem.title  :=AsString(lnode)
    else if CompareWide(pcw,'DESCRIPTION' )=0 then litem.descr  :=AsString(lnode)
    else if CompareWide(pcw,'BASEFILE'    )=0 then litem.base   :=AsString(lnode)
    else if CompareWide(pcw,'UNIT_GUID'   )=0 then litem.id     :=AsString(lnode)
    else if CompareWide(pcw,'USES'        )=0 then litem.ausable:=AsString(lnode)
    else if CompareWide(pcw,'MAXSTACKSIZE')=0 then Str(AsInteger(lnode),litem.stack)
    else if CompareWide(pcw,'ICON'        )=0 then litem.icon:=ExtractFileNameOnly(AsString(lnode))
    else if (litem.icon='') and (CompareWide(pcw,'GAMBLER_ICON')=0) then
      litem.icon:=ExtractFileNameOnly(AsString(lnode))
    else if CompareWide(pcw,'UNITTYPE')=0 then
    begin
      litem.unittype:=AsString(lnode);
      if (litem.quest='0') and (
         (litem.unittype='LEVEL ITEM') or 
         (litem.unittype='QUESTITEM')) then
           litem.quest:='1';
    end;
  end;

  if (litem.base<>'') then
  begin
    if (litem.unittype='') then litem.unittype:=GetBaseUnitType(ams,litem.base);
    if (litem.icon    ='') then litem.icon    :=ExtractFileNameOnly(GetBaseIcon(ams,litem.base));
  end;
  if litem.icon='' then result:=result or 1;

  if not AddItemToBase(ams,litem) then result:=result or 2;
end;

function ProcessItems(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p:pointer;
  ldir:string;
  i:integer;
begin
  result:=0;

  if asize>0 then
  begin
    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    if p<>nil then
    begin
      if PModScanner(aparam)^.FRootLen>0 then
        ldir:=Copy(adir,PModScanner(aparam)^.FRootLen+2)
      else
        ldir:=adir;
      i:=AddItemNode(aparam,p,
          ldir+'/'+aname,
          Pos('MEDIA/UNITS/ITEMS/QUEST_ITEMS',adir)>0);
      if (i and 1)<>0 then RGLog.Add('No icon for '  +aname);
      if (i and 2)<>0 then RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;
  end;
end;

function ScanItems(ams:pointer):integer;
begin
  RGLog.Add('Scanning items');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/ITEMS', @ProcessItems);
  RGLog.Add(IntToStr(result)+' records added');
end;

function CreateItemsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'items') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE items ('+
      '    id       INTEGER     PRIMARY KEY,'+
      '    name     TEXT,'+
      '    title    TEXT,'+
      '    modid    TEXT,'+
      '    descr    TEXT,'+
      '    usable   INTEGER (1),'+
      '    quest    INTEGER (1),'+
      '    stack    INTEGER     DEFAULT (1),'+
      '    icon     TEXT,'+
      '    unittype TEXT,'+
      '    file     TEXT,'+
      '    base     TEXT );');
end;

{%ENDREGION}
