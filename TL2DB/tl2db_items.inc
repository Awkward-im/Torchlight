{$IFDEF Interface}

function GetTL2Item (const aid:TL2ID; out amods:string):string; overload;
function GetTL2Item (const aid:TL2ID                  ):string; overload;
function GetItemIcon(const aid:TL2ID):string;
function GtItemStack(const aid:TL2ID):integer;
function GetItemPosition(apos:integer; out cont :string):string;
function GetAlt(const aid:TL2ID; alist:TTL2ModList):TL2ID;

function GetTL2Prop(const aid:TL2ID; out amods:string):string; overload;
function GetTL2Prop(const aid:TL2ID                  ):string; overload;

{$ELSE}

//----- Items -----

function GetTL2Item(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,'items','',amods,lname);
end;

function GetTL2Item(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Item(aid,lmods);
end;

function GetItemIcon(const aid:TL2ID):string;
begin
  result:=GetTextValue(aid,'items','icon');
end;

function GtItemStack(const aid:TL2ID):integer;
begin
  result:=GetIntValue(aid,'items','stack');
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

function GetAlt(const aid:TL2ID; alist:TTL2ModList):TL2ID;
var
  lunittype,lmods:string;
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  lmods:=GetTL2Item(aid);

  // 1 - item is unmodded
  if lmods=TL2GameID then
  begin
    result:=aid;
    exit;
  end;

  result:=TL2IdEmpty;

  // 2 - search in mod list
  if IsInModList(lmods,alist)<>TL2IdEmpty then
  begin
    result:=aid;
    exit;
  end;

  lunittype:='';
  Str(aid,lSQL);
  lSQL:='SELECT unittype FROM items WHERE id='+lSQL;
  if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      lunittype:=sqlite3_column_text(vm,0);
    sqlite3_finalize(vm);
  end;
  if lunittype='' then exit;
  
  // 3 - search alternative in unmodded items
  lSQL:='SELECT id FROM items WHERE modid='' 0 '' AND unittype='''+lunittype+''' LIMIT 1';
  if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      result:=sqlite3_column_int64(vm,0);
    sqlite3_finalize(vm);
  end;
  if result<>TL2IdEmpty then exit;

  // 4 - search alternative in mods
  for i:=0 to High(alist) do
  begin
    Str(alist[i].id,lSQL);
    lSQL:='SELECT id FROM items WHERE modid LIKE '' '+lSQL+' '' AND unittype='''+lunittype+''' LIMIT 1';
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
        result:=sqlite3_column_int64(vm,0);
      sqlite3_finalize(vm);
      if result<>TL2IdEmpty then exit;
    end;
  end;
end;

//----- Props -----

function GetTL2Prop(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,'props','',amods,lname);
end;

function GetTL2Prop(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Prop(aid,lmods);
end;

{$ENDIF}
