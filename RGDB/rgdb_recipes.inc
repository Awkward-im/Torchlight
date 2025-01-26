{$IFDEF Interface}

function RGDBGetRecipes(const aname:string; out amod:string):string; overload;
function RGDBGetRecipes(const id:TRGID    ; out amod:string):string; overload;
function RGDBGetRecipes(const id:TRGID                     ):string; overload;

function RGDBGetRecipesList(aactual,atitled:boolean):TL2IdList;

{$ELSE}

const
  dbRecipeTable = 'recipes';

function RGDBGetRecipes(const aname:string; out amod:string):string; overload;
var
  lid:TRGID;
  ls:string;
begin
  result:=GetByName(aname,dbRecipeTable,lid);
  Str(lid,ls);
  amod:=ReturnText(db,'SELECT modid FROM '+dbRecipeTable+' WHERE id='+ls);
end;

function RGDBGetRecipes(const id:TRGID; out amod:string):string; overload;
var
  lname:string;
begin
  result:=GetById(id,dbRecipeTable,'',amod,lname);
end;

function RGDBGetRecipes(const id:TRGID):string; overload;
var
  lmodid:string;
begin
  result:=RGDBGetRecipes(id,lmodid);
end;

function RGDBGetRecipesList(aactual,atitled:boolean):TL2IdList;
var
  lSQL,ls:string;
  vm:pointer;
  i,lcnt:integer;
begin
  result:=nil;

  if db<>nil then
  begin
    ls:='';
    if atitled then ls:='(title<>'''')';
    if aactual then ls:=ls+ModFilter;
    if ls<>''  then ls:=' WHERE '+ls;

    lcnt:=ReturnInt(db,'SELECT count(*) FROM '+dbRecipeTable+ls);

    if lcnt>0 then
    begin
      SetLength(result,lcnt);

      lSQL:='SELECT id FROM '+dbRecipeTable+ls;
      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while (i<lcnt) and (sqlite3_step(vm)=SQLITE_ROW) do
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
