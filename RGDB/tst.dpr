function GetEffectValueName(const avalues:string; idx:integer):string;
var
  i,lpos:integer;
begin
  i:=1;
  while true do
  begin
    lpos:=i;
    while (i<=Length(avalues)) and (avalues[i]<>',') do inc(i);
    if i>Length(avalues) then break; // got last value
    if lpos<>i then
    begin
      dec(idx);
      if idx<0 then break;
    end;
    inc(i);
  end;

  if idx<0 then
  begin
    SetLength(result,i-lpos);
    move(addr(avalues[lpos])^,addr(result[1])^,i-lpos);
  end
  else
    result:='';
end;

begin
  writeln('"',GetEffectValueName(',,1_1,,',0),'"');
  writeln('"',GetEffectValueName(',,1_1,,',6),'"');
  writeln('"',GetEffectValueName('one,,1_1,,',0),'"');
  writeln('"',GetEffectValueName('one,,1_1,2_2,',2),'"');
end.