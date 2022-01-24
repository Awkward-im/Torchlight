{$IFDEF Interface}

function GetTL2Item  (const aid:TRGID; out amods:string):string; overload;
function GetTL2Item  (const aid:TRGID                  ):string; overload;
function GetItemMods (const aid:TRGID):string;
function GetItemIcon (const aid:TRGID):string;
function GetItemStack(const aid:TRGID):integer;
function GetItemPosition(apos:integer; out cont :string):string;
function GetItemUsability(const aid:TRGID):integer;
function GetAlt(const aid:TRGID; alist:TTL2ModList; out newid:TRGID):TRGID;
function IsItem(const aid:TRGID):boolean;

function GetTL2Prop(const aid:TRGID; out amods:string):string; overload;
function GetTL2Prop(const aid:TRGID                  ):string; overload;

{$ELSE}

const
  dbItemTable = 'items';
  dbPropTable = 'props';

//----- Items -----

function GetTL2Item(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,dbItemTable,'',amods,lname);
end;

function GetTL2Item(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=GetTL2Item(aid,lmods);
end;

function GetItemMods(const aid:TRGID):string;
begin
  result:=GetTextValue(aid,dbItemTable,'modid');
end;

function GetItemIcon(const aid:TRGID):string;
begin
  result:=GetTextValue(aid,dbItemTable,'icon');
end;

function GetItemUsability(const aid:TRGID):integer;
begin
  result:=GetIntValue(aid,dbItemTable,'usable');
end;

function GetItemStack(const aid:TRGID):integer;
begin
  result:=GetIntValue(aid,dbItemTable,'stack');
end;

function IsItem(const aid:TRGID):boolean;
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

function GetAlt(const aid:TRGID; alist:TTL2ModList; out newid:TRGID):TRGID;
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
  if IsInModList(lmods,alist)<>RGIdEmpty then
    exit;

  //-- Here is replacing existing item by similar
  // Right now, search just by unittype without any other properties

  newid:=RGIdEmpty;
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
  if newid<>RGIdEmpty then
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
      if newid<>RGIdEmpty then
      begin
        result:=alist[i].id;
        exit;
      end;
    end;
  end;

  result:=RGIdEmpty;
end;

//----- Props -----

function GetTL2Prop(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,dbPropTable,'',amods,lname);
end;

function GetTL2Prop(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=GetTL2Prop(aid,lmods);
end;

{$ENDIF}
