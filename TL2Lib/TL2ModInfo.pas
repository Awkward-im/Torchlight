{$CALLING cdecl}

unit TL2ModInfo;

interface

type
  // fields are rearranged
  TTL2ModInfo = record
    modid   :Int64;
    gamever :QWord;
    offData :DWord;
    offDir  :DWord;
    title   :PWideChar;
    author  :PWideChar;
    descr   :PWideChar;
    website :PWideChar;
    download:PWideChar;
    filename:PWideChar;
    flags   :DWord;
    reqHash :Int64;
    reqs    :array of record
      name:PWideChar;
      id  :Int64;
      ver :Word;
    end;
    dels    :array of PWideChar;
    modver  :Word;
  end;

function  ReadModInfo(fname:PChar; var amod:TTL2ModInfo):boolean; export;
procedure ClearModInfo(var amod:TTL2ModInfo); export;


implementation

function ReadShortString(var aptr:pbyte):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=pword(aptr)^; inc(aptr,2);
  if lsize>0 then
  begin
    GetMem    (result ,(lsize+1)*SizeOf(WideChar));
    move(aptr^,result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
    inc(aptr,lsize*SizeOf(WideChar));
  end
  else
    result:=nil;
end;

function ReadModInfo(fname:PChar; var amod:TTL2ModInfo):boolean;
var
  buf:array [0..16383] of byte;
  f:file of byte;
  p:pbyte;
  i,lcnt:integer;
begin
  result:=false;

  AssignFile(f,fname);
  try
    Reset(f);
    i:=FileSize(f);
    if i>SizeOf(buf) then i:=SizeOf(buf);
    BlockRead(f,buf[0],i);
  except
    i:=0;
  end;
  CloseFile(f);

  if i<(2+2+8+4+4+2*5+8) then exit; // minimal size of used header data

  p:=@buf[0];

  // wrong signature
  if pword(p)^<>4 then
  begin
    amod.modid:=-1;
    amod.title:=nil;
    exit;
  end;
  inc(p,2);

  result:=true;

//  amod.filename:=UTF8Decode(fname);

  amod.modver  :=pWord(p)^; inc(p,2);
  amod.gamever :=             (QWord(pWord(p)^) shl 48); inc(p,2);
  amod.gamever :=amod.gamever+(QWord(pWord(p)^) shl 32); inc(p,2);
  amod.gamever :=amod.gamever+(DWord(pWord(p)^) shl 16); inc(p,2);
  amod.gamever :=amod.gamever+pWord(p)^; inc(p,2);
  amod.offData :=pDWord(p)^; inc(p,4);
  amod.offDir  :=pDWord(p)^; inc(p,4);
  amod.title   :=ReadShortString(p);
  amod.author  :=ReadShortString(p);
  amod.descr   :=ReadShortString(p);
  amod.website :=ReadShortString(p);
  amod.download:=ReadShortString(p);
  amod.modid   :=pInt64(p)^; inc(p,8);
  //-
  amod.flags   :=pDWord(p)^; inc(p,4);
  amod.reqHash :=pInt64(p)^; inc(p,8);
  lcnt:=pWord(p)^; inc(p,2);
  SetLength(amod.reqs,lcnt);
  for i:=0 to lcnt-1 do
  begin
    amod.reqs[i].name:=ReadShortString(p);
    amod.reqs[i].id  :=pInt64(p)^; inc(p,8);
    amod.reqs[i].ver :=pWord (p)^; inc(p,2);
  end;
  lcnt:=pWord(p)^; inc(p,2);
  SetLength(amod.dels,lcnt);
  for i:=0 to lcnt-1 do
    amod.dels[i]:=ReadShortString(p);
end;

procedure ClearModInfo(var amod:TTL2ModInfo);
var
  i:integer;
begin
  if amod.title   <>nil then FreeMem(amod.title);
  if amod.author  <>nil then FreeMem(amod.author);
  if amod.descr   <>nil then FreeMem(amod.descr);
  if amod.website <>nil then FreeMem(amod.website);
  if amod.download<>nil then FreeMem(amod.download);
  if Length(amod.reqs)>0 then
  begin
    for i:=0 to High(amod.reqs) do
      FreeMem(amod.reqs[i].name);
    SetLength(amod.reqs,0);
  end;
  if Length(amod.dels)>0 then
  begin
    for i:=0 to High(amod.dels) do
      FreeMem(amod.dels[i]);
    SetLength(amod.dels,0);
  end;
end;

exports

  ReadModInfo,
  ClearModInfo;

end.
