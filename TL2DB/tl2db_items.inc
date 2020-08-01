{$IFDEF Interface}

function GetTL2Item (const aid:TL2ID; out amods:string):string; overload;
function GetTL2Item (const aid:TL2ID                  ):string; overload;
function GetItemMods(const aid:TL2ID):string;
function GetItemIcon(const aid:TL2ID):string;
function GtItemStack(const aid:TL2ID):integer;
function GetItemPosition(apos:integer; out cont :string):string;
function GetItemUsability(const aid:TL2ID):integer;
function GetAlt(const aid:TL2ID; alist:TTL2ModList; out newid:TL2ID):TL2ID;
function IsItem(const aid:TL2ID):boolean;

function GetTL2Prop(const aid:TL2ID; out amods:string):string; overload;
function GetTL2Prop(const aid:TL2ID                  ):string; overload;

{$ELSE}

const
  dbItemTable = 'items';
  dbPropTable = 'props';

//----- Items -----

function GetTL2Item(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,dbItemTable,'',amods,lname);
end;

function GetTL2Item(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Item(aid,lmods);
end;

function GetItemMods(const aid:TL2ID):string;
begin
  result:=GetTextValue(aid,dbItemTable,'modid');
end;

function GetItemIcon(const aid:TL2ID):string;
begin
  result:=GetTextValue(aid,dbItemTable,'icon');
end;

function GetItemUsability(const aid:TL2ID):integer;
begin
  result:=GetIntValue(aid,dbItemTable,'usable');
end;

function GtItemStack(const aid:TL2ID):integer;
begin
  result:=GetIntValue(aid,dbItemTable,'stack');
end;

function IsItem(const aid:TL2ID):boolean;
begin
  result:=GetItemMods(aid)<>'';
end;

function GetItemPosition(apos:integer; out cont:string):string;
var
  lSQL:string;
  vm:pointer;
begin
  result:='';
  cont  :='';
  if db<>nil then
  begin
    Str(apos,lSQL);
    lSQL:='SELECT name, MAX(id),'+
    ' (SELECT name FROM inventory WHERE'+
    ' (iscontainer=1) AND (id =('+lSQL+' >> 16)) ) AS ''container'''+
    ' FROM inventory WHERE id<=('+lSQL+' & 0xFFFF)';
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
        cont  :=sqlite3_column_text(vm,2);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function GetAlt(const aid:TL2ID; alist:TTL2ModList; out newid:TL2ID):TL2ID;
var
  lmods,lunittype:string;
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  //-- Check if no replaces required

  newid:=aid;
  result:=0;

  lmods:=GetItemMods(aid);

  // 1 - item is unmodded
  if lmods=TL2GameID then
    exit;

  // 2 - search in mod list
  if IsInModList(lmods,alist)<>TL2IdEmpty then
    exit;

  //-- Here is replacing existing item by similar
  // Right now, search just by unittype without any other properties

  newid:=TL2IdEmpty;
  lunittype:=GetTextValue(aid,dbItemTable,'unittype');
  if lunittype='' then exit;

  // 3 - search alternative in unmodded items
  lSQL:='SELECT id FROM '+dbItemTable+
        ' WHERE modid='' 0 '' AND unittype='''+lunittype+''' LIMIT 1';
  if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      newid:=sqlite3_column_int64(vm,0);
    sqlite3_finalize(vm);
  end;
  if newid<>TL2IdEmpty then
    exit;

  // 4 - search alternative in modded items
  for i:=0 to High(alist) do
  begin
    Str(alist[i].id,lSQL);
    lSQL:='SELECT id FROM '+dbItemTable+
          ' WHERE modid LIKE '' '+lSQL+' '' AND unittype='''+lunittype+''' LIMIT 1';
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
        newid:=sqlite3_column_int64(vm,0);
      sqlite3_finalize(vm);
      if newid<>TL2IdEmpty then
      begin
        result:=alist[i].id;
        exit;
      end;
    end;
  end;

  result:=TL2IdEmpty;
end;

//----- Props -----

function GetTL2Prop(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,dbPropTable,'',amods,lname);
end;

function GetTL2Prop(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Prop(aid,lmods);
end;

{$ENDIF}
