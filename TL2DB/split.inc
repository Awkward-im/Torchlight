{Split string functions}

type
 TIntArray   = array of integer;
 TInt64Array = array of int64;

function splitInt(const astr:string; asep:char):TIntArray;
var
  p:PChar;
  i,lcnt:integer;
  isminus:boolean;
begin
  result:=nil;
  if astr='' then
    exit;

  // get array length

  p:=pointer(astr);
  if p^=asep then inc(p);
  lcnt:=0;
  while p^<>#0 do
  begin
    if p^=asep then inc(lcnt);
    inc(p);
  end;
  if (p-1)^<>asep then inc(lcnt);
  SetLength(result,lcnt);

  // fill array

  p:=pointer(astr);
  if p^=asep then inc(p);

  isminus:=false;
  result[0]:=0;
  i:=0;
  while p^<>#0 do
  begin
    if p^='-' then isminus:=true
    else if p^<>asep then result[i]:=result[i]*10+ORD(p^)-ORD('0')
    else
    begin
      if isminus then
      begin
        result[i]:=-result[i];
        isminus:=false;
      end;
      inc(i);
      if i<lcnt then result[i]:=0;
    end;
    inc(p);
  end;
end;

function splitInt64(const astr:string; asep:char):TInt64Array;
var
  p:PChar;
  i,lcnt:integer;
  isminus:boolean;
begin
  result:=nil;
  if astr='' then
    exit;

  // get array length

  p:=pointer(astr);
  if p^=asep then inc(p);
  lcnt:=0;
  while p^<>#0 do
  begin
    if p^=asep then inc(lcnt);
    inc(p);
  end;
  if (p-1)^<>asep then inc(lcnt);
  SetLength(result,lcnt);

  // fill array

  p:=pointer(astr);
  if p^=asep then inc(p);

  isminus:=false;
  result[0]:=0;
  i:=0;
  while p^<>#0 do
  begin
    if p^='-' then isminus:=true
    else if p^<>asep then result[i]:=result[i]*10+ORD(p^)-ORD('0')
    else
    begin
      if isminus then
      begin
        result[i]:=-result[i];
        isminus:=false;
      end;
      inc(i);
      if i<lcnt then result[i]:=0;
    end;
    inc(p);
  end;
end;
