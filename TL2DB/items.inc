{$IFDEF Interface}

function GetTL2Item(const aid:TL2ID  ; out amods:string):string; overload;
function GetTL2Item(const aid:TL2ID                    ):string; overload;
function GetItemPosition(apos:integer; out cont :string):string;

function GetTL2Prop(const aid:TL2ID  ; out amods:string):string; overload;
function GetTL2Prop(const aid:TL2ID                    ):string; overload;

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
