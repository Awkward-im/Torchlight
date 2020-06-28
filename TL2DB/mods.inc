{$IFDEF Interface}

type
  TModData = record
     id   :TL2ID;
     title:string;
   end;
  tModDataArray = array of TModData;

function GetTL2Mod(const aid:TL2ID; out aver:integer):string; overload;
function GetTL2Mod(const aid:TL2ID                  ):string; overload;
function GetTL2Mod(const aid:string                 ):string; overload;

procedure GetModList(out alist:tModDataArray);

{$ELSE}

function GetTL2Mod(const aid:TL2ID; out aver:integer):string;
var
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  aver:=0;
  if aid=0 then
  begin
    result:='Torchlight 2';
    exit;
  end;

  result:=HexStr(aid,16);

  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT title,version FROM mods WHERE id='+lSQL;

    i:=sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil);
    if i=SQLITE_OK then
    begin
      i:=sqlite3_step(vm);
      if i=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
        aver  :=sqlite3_column_int (vm,1);
      end;
      sqlite3_finalize(vm);
    end;
  end;

end;

function GetTL2Mod(const aid:TL2ID):string;
var
  lver:integer;
begin
  result:=GetTL2Mod(aid,lver);
end;

function GetTL2Mod(const aid:string):string;
var
  ls:string;
  lid:TL2ID;
  lpos:integer;
begin
  ls:=aid;
  if ls='' then
    lid:=0
  else
  begin
    if ls[1]=' ' then ls:=Copy(ls,1);
    if ls[Length(ls)]=' ' then SetLength(ls,High(ls));
    lpos:=pos(' ',ls);
    if lpos=0 then
      Val(ls,lid)
    else
      Val(Copy(ls,1,lpos-1),lid);
  end;
  result:=GetTL2Mod(lid);
end;

procedure GetModList(out alist:tModDataArray);
var
  lSQL:string;
  vm:pointer;
  i,lcnt:integer;
begin
  alist:=nil;

  if db<>nil then
  begin
    lSQL:='SELECT count(*) FROM mods';
    i:=0;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        i:=sqlite3_column_int(vm,0);
      end;
      sqlite3_finalize(vm);
    end;

    if i>0 then
    begin
      SetLength(alist,i);
      lSQL:='SELECT id,title FROM mods';
      i:=sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil);
      if i=SQLITE_OK then
      begin
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          alist[i].id   :=sqlite3_column_int (vm,0);
          alist[i].title:=sqlite3_column_text(vm,1);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end;
end;

{$ENDIF}
