{$IFDEF Interface}

function GetTL2Recipes(const id:TL2ID; out amod:string):string; overload;
function GetTL2Recipes(const id:TL2ID                 ):string; overload;

function GetRecipesList(aactual,atitled:boolean):TL2IdList;

{$ELSE}

function GetTL2Recipes(const id:TL2ID; out amod:string):string; overload;
var
  lname:string;
begin
  result:=GetById(id,'recipes','',amod,lname);
end;

function GetTL2Recipes(const id:TL2ID):string; overload;
var
  lmodid:string;
begin
  result:=GetTL2Recipes(id,lmodid);
end;

function GetRecipesList(aactual,atitled:boolean):TL2IdList;
var
  lSQL,ls:string;
  vm:pointer;
  i:integer;
begin
  result:=nil;

  if db<>nil then
  begin
    if atitled then
      ls:=' WHERE title<>'''''
    else
      ls:='';

    lSQL:='SELECT count(*) FROM recipes'+ls;
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
      SetLength(result,i);

      lSQL:='SELECT id FROM recipes'+ls;
      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          result[i]:=sqlite3_column_int64(vm,0);
          inc(i);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end;
end;

{$ENDIF}
