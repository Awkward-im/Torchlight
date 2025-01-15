uses
  classes,
  sysutils,
  rgglobal;

type
  TBruteOption = (
    boCheckSmall ,  // check small letters
    boNo1stUnder ,  // no underscore first
    boNoEdgeSpace,  // check space at start and end
    boNoSpace    ,  // no spaces allowed
    boCheckSign  ,  // check for signs too
    boNumberAtEnd   // numbers at the end only
  );
  TBruteOptions = set of TBruteOption;

// order is from dictionary analize
const
  dictSign    = '?-%.';
  dictUpper   = 'EATINOR_SLMCDPUHGBFYWVKX1234567890QJZ';
  dictUpSpace = 'EATINOR_SLMCDPUHGBFYWV KX1234567890QJZ';
  dictLower   = 'eaiolnrdtchsmgufywpbqvkxzj';

const
  minlen = 4;
  maxlen = 5;
  maxnumlen = 3;

var
  sl:tstringlist;
  hashes:array of dword;
  dict:ShortString;
  options:TBruteOptions;

procedure add(var s: ShortString; n: integer);
var
  lhash:dword;
  cntHash,i:integer;
begin

  for i:=1 to Length(dict) do
  begin
    if (boNo1stUnder  in options) and
       (n=1) and (dict[i]='_') then continue;
    // numbers at the end only
    if (boNumberAtEnd in options) and
       (dict[i] in ['0'..'9']) and (n<(Length(s)-maxnumlen+1)) then continue;
    // no space at the start and end
    if (boNoEdgeSpace in options) and 
       (dict[i]=' ') and ((n=1) or (n=length(s)))  then continue;
    // no two spaces one by one
    if (dict[i]=' ') and (s[n-1]=' ') then continue;

    s[n]:=dict[i];
    if n = length(s) then
    begin
      lhash:=RGHashB(PAnsiChar(@s[1]),n);
      for cntHash:=0 to High(hashes) do
        if lhash=hashes[cntHash] then
        begin
          sl.Add(IntToStr(lhash)+':'+s);
          writeln(sl[sl.Count-1]);
          break;
        end;
    end
    else
    begin
//      if n<4 then write(s[1],s[2],s[3],#13);
      add(s, n+1);
    end;
  end;
end;

var
  ls:ShortString;
  i:integer;
begin
  sl:=TStringList.Create;
  try
{
    sl.LoadFromFile('hashes.txt');
    SetLength(hashes,sl.Count);
    for i:=0 to sl.Count-1 do
    begin
      hashes[i]:=dword(StrToInt64(sl[i]));
    end;
    sl.Clear;
}    
    SetLength(hashes,1);
    hashes[0]:=StrToInt64(ParamStr(1));

    options:=[
      boCheckSmall ,  // check small letters
      boNo1stUnder ,  // no underscore first
      boNoEdgeSpace,  // check space at start and end
//      boNoSpace    ,  // no spaces allowed
//      boCheckSign  ,  // check for signs too
      boNumberAtEnd   // numbers at the end only
    ];

    if boNoSpace    in options then dict:=dictUpper else dict:=dictUpSpace;
    if boCheckSmall in options then dict:=dict+dictLower;
    if boCheckSign  in options then dict:=dict+dictSign;

    ls:='';
    // for all lengths
    for i:=minlen to maxlen do
    begin
      writeln('>>',i);
      ls[ 0]:=CHR(i);
{
      ls[ 1]:='A';
      ls[ 2]:='M';
      ls[ 3]:='A';
      ls[ 4]:='G';
      ls[ 5]:='E';
}
      ls[i+1]:=#0;
      add(ls,1);
    end;

  finally
    sl.Sort;
    sl.SaveToFile('result.txt');
    sl.Free;
  end;
end.
