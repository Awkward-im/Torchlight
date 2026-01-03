unit RG3dShared;

interface

uses
  Classes;


{$I rg3d.Ogre.inc}

// XML
procedure WriteLine(aStream:TStream; const aString:UTF8String);
// Binary
function WriteChunk(astream:TStream; achunk:integer; asize:integer=0):integer;
procedure WriteText(astream:TStream; const atext:AnsiString);
function memReadText(var abuf:PByte):string;

function GetVersionText(aver:integer):AnsiString;
function TranslateVersion(const sign:AnsiString):integer;
// Log
procedure LogLn;
procedure Log(const astr:string; const aval:string='');
procedure Log(const astr:string; aval:single);
procedure Log(const astr:string; aval:boolean);
procedure Log(const astr:string; aval:int64);


implementation

uses
  RGGlobal;


procedure WriteLine(aStream:TStream; const aString:UTF8String);
begin
  if length(aString)>0 then
    aStream.WriteBuffer(aString[1],length(aString));

  aStream.WriteBuffer(#13#10,2);
end;

function WriteChunk(astream:TStream; achunk:integer; asize:integer=0):integer;
begin
  astream.WriteWord(achunk); // chunk code
  result:=astream.Position;  // position of chunk size
  astream.WriteDWord(asize+SizeOf(TOgreChunk)); // reserve for chunk size if needs
end;

procedure WriteText(astream:TStream; const atext:AnsiString);
begin
  if atext<>'' then astream.Write(atext[1],Length(atext));
  astream.WriteByte($0A);
end;

function memReadText(var abuf:PByte):string;
var
  lptr:PByte;
  lsize:integer;
begin
  lptr:=abuf;
  while abuf^<>10 do inc(abuf);

  lsize:=abuf-lptr;
  if lsize=0 then
    result:=''
  else
    SetString(result,PAnsiChar(lptr),lsize);
  inc(abuf);
end;

function GetVersionText(aver:integer):AnsiString;
var
  i:integer;
begin
  for i:=0 to High(FileVersions) do
    if FileVersions[i].ver=aver then exit(FileVersions[i].sign);

  result:='';
end;

function TranslateVersion(const sign:AnsiString):integer;
var
  i:integer;
begin
  for i:=0 to High(FileVersions) do
    if FileVersions[i].sign=sign then exit(FileVersions[i].ver);

  result:=-1;
end;

procedure LogLn;
begin
  RGLog.Add('');
end;

procedure Log(const astr:string; const aval:string='');
begin
  if aval<>'' then RGLog.Add(astr+': '+aval) else RGLog.Add(astr);
end;

procedure Log(const astr:string; aval:single);
var
  ls:string;
begin
  Str(aval:0:4,ls);
  RGLog.Add(astr+': '+ls);
end;

procedure Log(const astr:string; aval:boolean);
var
  ls:string;
begin
  if aval then ls:='true' else ls:='false';
  RGLog.Add(astr+': '+ls);
end;

procedure Log(const astr:string; aval:int64);
var
  ls:string;
begin
  Str(aval,ls);
  RGLog.Add(astr+': '+ls);
end;

end.
