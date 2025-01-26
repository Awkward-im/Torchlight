{$IFDEF Interface}

function RGDBGetEffectValueNames(num:integer):string;
function RGDBGetEffectValueName(const avalues:string; idx:integer):string;

{$ELSE}

function RGDBGetEffectValueNames(num:integer):string;
var
  lSQL:string;
  vm:pointer;
begin
  result:='';

  Str(num,lSQL);
  lSQL:='SELECT value1,value2,value3,value4,value5 FROM effects WHERE id='+lSQL;
  if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      result:=sqlite3_column_text(vm,0)+
          ','+sqlite3_column_text(vm,1)+
          ','+sqlite3_column_text(vm,2)+
          ','+sqlite3_column_text(vm,3)+
          ','+sqlite3_column_text(vm,4);
    end;
    sqlite3_finalize(vm);
  end;

end;

function RGDBGetEffectValueName(const avalues:string; idx:integer):string;
var
  i,lpos:integer;
begin
  if avalues='' then exit('');
  i:=1;
  while true do
  begin
    lpos:=i;
    while (i<=Length(avalues)) and (avalues[i]<>',') do inc(i);
    if i>Length(avalues) then break;
    if lpos<>i then
    begin
      if idx=0 then break;
      dec(idx);
    end;
    inc(i);
  end;

  if (idx=0) and (i<>lpos) then
  begin
    SetLength(result,i-lpos);
    move(addr(avalues[lpos])^,addr(result[1])^,i-lpos);
  end
  else
    result:='';
end;
{$ENDIF}
