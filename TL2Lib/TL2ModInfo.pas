unit TL2ModInfo;

interface

type
  TTL2ModInfo = record
    modid      :Int64;
    gamever    :QWord;
    title      :PWideChar;
    author     :PWideChar;
    descr      :PWideChar;
    website    :PWideChar;
    download   :PWideChar;
    modver     :Word;
  end;

function  ReadModInfo(fname:PChar; var amod:TTL2ModInfo):boolean;
procedure ClearModInfo(var amod:TTL2ModInfo);


implementation


function ReadShortString(var aptr:pbyte):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=pword(aptr)^; inc(aptr,2);
  if lsize>0 then
  begin
    GetMem(result,(lsize+1)*SizeOf(WideChar));
    move(aptr^,result^,lsize*SizeOf(WideChar));
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
  i:integer;
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

  amod.modver  :=pWord (p)^; inc(p,2);
  amod.gamever :=             (QWord(pWord(p)^) shl 48); inc(p,2);
  amod.gamever :=amod.gamever+(QWord(pWord(p)^) shl 32); inc(p,2);
  amod.gamever :=amod.gamever+(DWord(pWord(p)^) shl 16); inc(p,2);
  amod.gamever :=amod.gamever+pWord(p)^; inc(p,2);
  inc(p,4+4); // skip offset_data and offset_dir
  amod.title   :=ReadShortString(p);
  amod.author  :=ReadShortString(p);
  amod.descr   :=ReadShortString(p);
  amod.website :=ReadShortString(p);
  amod.download:=ReadShortString(p);
  amod.modid   :=PInt64(p)^; // offset=[$0C]-24
end;

procedure ClearModInfo(var amod:TTL2ModInfo);
begin
  if amod.title   <>nil then FreeMem(amod.title);
  if amod.author  <>nil then FreeMem(amod.author);
  if amod.descr   <>nil then FreeMem(amod.descr);
  if amod.website <>nil then FreeMem(amod.website);
  if amod.download<>nil then FreeMem(amod.download);
end;

exports

  ReadModInfo,
  ClearModInfo;

end.
