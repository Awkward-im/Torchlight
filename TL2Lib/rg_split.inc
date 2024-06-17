{Split string functions}

{$IFDEF Interface}

function splitCountW(      astr:PWideChar; asep:WideChar):integer;
function splitCountA(      astr:PAnsiChar; asep:AnsiChar):integer;
function splitInt   (      astr:PWideChar; asep:WideChar):TIntegerDynArray;
function splitInt   (const astr:string   ; asep:char    ):TIntegerDynArray;
function splitInt64 (const astr:string   ; asep:char    ):TInt64DynArray;
function splitFloat (const astr:string   ; asep:char    ):TSingleDynArray;

{$ELSE}

function splitCountW(astr:PWideChar; asep:WideChar):integer;
var
  p:PWideChar;
begin
  result:=0;
  if (astr=nil) or (astr^=#0) then
    exit;

  p:=astr;
  while p^=asep do inc(p);
  while p^<>#0 do
  begin
    if p^=asep then inc(result);
    inc(p);
  end;
  if (p>astr) and ((p-1)^<>asep) then inc(result);
end;

function splitCountA(astr:PAnsiChar; asep:AnsiChar):integer;
var
  p:PAnsiChar;
begin
  result:=0;
  if (astr=nil) or (astr^=#0) then
    exit;

  p:=astr;
  while p^=asep do inc(p);
  while p^<>#0 do
  begin
    if p^=asep then inc(result);
    inc(p);
  end;
  if (p>astr) and ((p-1)^<>asep) then inc(result);
end;

function splitInt(astr:PWideChar; asep:WideChar):TIntegerDynArray;
var
  p:PWideChar;
  i,lcnt:integer;
  isminus:boolean;
begin
  result:=nil;

  // get array length

  lcnt:=splitCountW(astr,asep);
  if lcnt=0 then exit;
  SetLength(result,lcnt);

  // fill array

  p:=astr;
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

function splitInt(const astr:string; asep:char):TIntegerDynArray;
var
  p:PChar;
  i,lcnt:integer;
  isminus:boolean;
begin
  result:=nil;

  // get array length

  lcnt:=splitCountA(pointer(astr),asep);
  if lcnt=0 then exit;
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

function splitInt64(const astr:string; asep:char):TInt64DynArray;
var
  p:PChar;
  i,lcnt:integer;
  isminus:boolean;
begin
  result:=nil;
  if astr='' then
    exit;

  // get array length

  lcnt:=splitCountA(pointer(astr),asep);
  if lcnt=0 then exit;
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

function splitFloat(const astr:string; asep:char):TSingleDynArray;
begin
  result:=nil;
end;

{$ENDIF}
