uses
  classes,
  sysutils,
  rgglobal;

const
  Signs:array of Char = (
    '0','1','2','3','4','5','6','7','8','9',' ','_',
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'{,
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z'});

const
  minlen = 6;
  maxlen = 6;


var
  sl:tstringlist;
  hashes:array of dword;

procedure add(var s: ShortString; n: integer);
var
  lhash:dword;
  cntHash,i:integer;
begin

  for i:=0 to High(Signs) do
  begin

    if (n<(length(s)-1)) and (Signs[i] in ['0'..'9']) then continue;
    if ((n=1) or (n=length(s))) and ((Signs[i]=' ') {or (Signs[i]='_')}) then continue;
    if (s[n-1]=' ') and (Signs[i]=' ') then continue;
    s[n]:=Signs[i];
    if n = length(s) then
    begin
//writeln(PChar(pointer(@s[1])));
      lhash:=rghash(pointer(@s[1]),n);
      for cntHash:=0 to High(hashes) do
        if lhash=hashes[cntHash] then
        begin
writeln(IntToStr(lhash)+':'+s);
          sl.Add(IntToStr(lhash)+':'+s);
          break;
        end;
    end
    else
    begin
      if n<4 then write(s[1],s[2],s[3],#13);
      add(s, n+1);
    end;
{
if (n<3) and (sl.count>0) then
begin
  sl.SaveToFile('result_'+IntToStr(n)+s[1]+s[2]+'.txt');
  sl.Clear;
end;
}
  end;
end;

var
  ls:ShortString;
  i:integer;
begin
  sl:=TStringList.Create;
//  try
    sl.LoadFromFile('hashes.txt');
    SetLength(hashes,sl.Count);
    for i:=0 to sl.Count-1 do
    begin
      hashes[i]:=dword(StrToInt64(sl[i]));
    end;
    
    sl.Clear;

    ls:='';

    // for all lengths
    for i:=minlen to maxlen do
    begin
writeln(i);
      ls[i+1]:=#0;
      ls[0]:=CHR(i);
      ls[1]:='Z';
      ls[2]:='A';
      ls[3]:='P';
      add(ls,1);
    end;

//  finally
    sl.SaveToFile('result.txt');
    sl.Free;
//  end;
end.
