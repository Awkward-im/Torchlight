{$IFDEF Interface}

function RGDBGetTL2Movie(const aid:TRGID; out amods:string; out aviews:integer;
                        out aname:string; out apath:string):string; overload;
function RGDBGetTL2Movie(const aid:TRGID; out amods:string):string; overload;
function RGDBGetTL2Movie(const aid:TRGID                  ):string; overload;

{$ELSE}

function RGDBGetTL2Movie(const aid  :TRGID ; out amods:string; out aviews:integer;
                     out   aname:string; out apath:string ):string;
var
  lSQL:string;
  vm:pointer;
begin
  amods :='';
  result:=HexStr(aid,16);
  aviews:=1;
  aname :='';
  apath :='';

  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT title,modid,views,name,path FROM movies WHERE id='+lSQL+' LIMIT 1';

    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
        amods :=sqlite3_column_text(vm,1);
        aviews:=sqlite3_column_int (vm,2);
        aname :=sqlite3_column_text(vm,3);
        apath :=sqlite3_column_text(vm,4);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function RGDBGetTL2Movie(const aid:TRGID; out amods:string):string; overload;
var
  lname:string;
begin
  result:=GetById(aid,'movies','',amods,lname);
end;

function RGDBGetTL2Movie(const aid:TRGID):string; overload;
var
  lmods:string;
begin
  result:=RGDBGetTL2Movie(aid,lmods);
end;

{$ENDIF}
