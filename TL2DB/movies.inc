{$IFDEF Interface}

function GetTL2Movie(const id:TL2ID ; out amod :string; out aviews:integer;
                    out aname:string; out apath:string):string; overload;
function GetTL2Movie(const id:TL2ID ; out amod :string):string; overload;
function GetTL2Movie(const id:TL2ID                   ):string; overload;

{$ELSE}

function GetTL2Movie(const id   :TL2ID ; out amod :string; out aviews:integer;
                     out   aname:string; out apath:string ):string;
var
  aSQL:string;
  vm:pointer;
begin
  amod  :='';
  result:=HexStr(id,16);
  aviews:=1;
  aname :='';
  apath :='';

  if db<>nil then
  begin
    Str(id,aSQL);
    aSQL:='SELECT title,modid,views,name,path FROM movies WHERE id='+aSQL+' LIMIT 1';

    if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text (vm,0);
        amod  :=sqlite3_column_text (vm,1);
        aviews:=sqlite3_column_int64(vm,2);
        aname :=sqlite3_column_text (vm,3);
        apath :=sqlite3_column_text (vm,4);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function GetTL2Movie(const id:TL2ID; out amod:string):string; overload;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'movies','',amod,lname);
end;

function GetTL2Movie(const id:TL2ID):string; overload;
var
  lmodid:string;
begin
  result:=GetTL2Movie(id,lmodid);
end;

{$ENDIF}
