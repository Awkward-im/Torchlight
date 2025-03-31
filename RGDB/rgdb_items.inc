{$IFDEF Interface}

function RGDBGetItem     (const aid:TRGID; out amods:string):string; overload;
function RGDBGetItem     (const aid:TRGID                  ):string; overload;
function RGDBGetItemMods (const aid:TRGID):string;
function RGDBGetItemIcon (const aid:TRGID):string;
function RGDBGetItemStack(const aid:TRGID):integer;
function RGDBGetItemPosition(apos:integer; out cont :string):string;
function RGDBGetItemUsability(const aid:TRGID):integer;
function RGDBGetAltItem  (const aid:TRGID; alist:TTL2ModList; out newid:TRGID):TRGID;
function RGDBIsItem      (const aid:TRGID):boolean;

function RGDBGetProp     (const aid:TRGID; out amods:string):string; overload;
function RGDBGetProp     (const aid:TRGID                  ):string; overload;

{$ELSE}

const
  dbItemTable = 'items';
  dbPropTable = 'props';

//----- Items -----

function RGDBGetItem(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,dbItemTable,'',amods,lname);
end;

function RGDBGetItem(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=RGDBGetItem(aid,lmods);
end;

function RGDBGetItemMods(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,dbItemTable,'modid');
end;

function RGDBGetItemIcon(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,dbItemTable,'icon');
end;

function RGDBGetItemUsability(const aid:TRGID):integer;
begin
  result:=RGDBGetIntValue(aid,dbItemTable,'usable');
end;

function RGDBGetItemStack(const aid:TRGID):integer;
begin
  result:=RGDBGetIntValue(aid,dbItemTable,'stack');
end;

function RGDBIsItem(const aid:TRGID):boolean;
begin
  result:=RGDBGetItemMods(aid)<>'';
end;

function RGDBGetItemPosition(apos:integer; out cont:string):string;
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

function RGDBGetAltItem(const aid:TRGID; alist:TTL2ModList; out newid:TRGID):TRGID;
var
  lmods,lunittype:string;
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  //-- Check if no replaces required

  newid:=aid;
  result:=0;

  lmods:=RGDBGetItemMods(aid);

  // 1 - item is unmodded
  if lmods=TL2GameID then
    exit;

  // 2 - search in mod list
  if RGDBIsInModList(lmods,alist)<>RGIdEmpty then
    exit;

  //-- Here is replacing existing item by similar
  // Right now, search just by unittype without any other properties

  newid:=RGIdEmpty;
  lunittype:=RGDBGetTextValue(aid,dbItemTable,'unittype');
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
          ' WHERE (modid GLOB ''* '+lSQL+' *'') AND (unittype='''+lunittype+''') LIMIT 1';
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

function RGDBGetProp(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,dbPropTable,'',amods,lname);
end;

function RGDBGetProp(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=RGDBGetProp(aid,lmods);
end;

{$ENDIF}
