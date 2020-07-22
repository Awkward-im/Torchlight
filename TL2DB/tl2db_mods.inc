{$IFDEF Interface}

const
  TL2GameID = ' 0 ';

type
  TModData = record
     id     :TL2ID;
     title  :string;
     version:word;
   end;
  tModDataArray = array of TModData;

function GetTL2Mod(const aid:TL2ID; out aver:integer):string; overload;
function GetTL2Mod(const aid:TL2ID                  ):string; overload;
function GetTL2Mod(const aid:string                 ):string; overload;

function GetModList:tModDataArray;

{$ELSE}

var
  GlobalModList:tModDataArray = nil;


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
    if GlobalModList<>nil then
    begin
      for i:=0 to High(GlobalModList) do
      begin
        if aid=GlobalModList[i].id then
        begin
          aver  :=GlobalModList[i].version;
          result:=GlobalModList[i].title;
          break;
        end;
      end;
    end
    else
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

function GetModList:tModDataArray;
var
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  if GlobalModList=nil then
  begin
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
        SetLength(GlobalModList,i);
        lSQL:='SELECT id,title,version FROM mods';
        i:=sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil);
        if i=SQLITE_OK then
        begin
          i:=0;
          while sqlite3_step(vm)=SQLITE_ROW do
          begin
            GlobalModList[i].id     :=sqlite3_column_int64(vm,0);
            GlobalModList[i].title  :=sqlite3_column_text (vm,1);
            GlobalModList[i].version:=sqlite3_column_int  (vm,2);
            inc(i);
          end;
          sqlite3_finalize(vm);
        end;
      end;
    end;
  end;
  result:=GlobalModList;
end;

{$ENDIF}
