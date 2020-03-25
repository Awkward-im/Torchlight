unit TL2Common;

interface

uses
  tl2stream;

type
  TTL2ParseType = (ptLite, ptStandard, ptDeep, ptDeepest);

type
  gc_Sex = (male, female);
  gc_BaseClass = (Berserker, Embermage, Engineer, Outlander);

type
  TTL2StringList = array of string;

type
  TTL2ModId = QWord;
  TTL2ModIdList = array of TTL2ModId;

procedure SaveDump(const aname:string; aptr:pByte; asize:cardinal);

function ReadModIdList      (AStream:TTL2Stream):TTL2ModIdList;
function ReadShortStringList(AStream:TTL2Stream):TTL2StringList;


implementation


procedure SaveDump(const aname:string; aptr:pByte; asize:cardinal);
var
  f:file of byte;
begin
  AssignFile(f,aname);
  Rewrite(f);
  BlockWrite(f,aptr^,asize);
  CloseFile(f);
end;

function ReadModIdList(AStream:TTL2Stream):TTL2ModIdList;
var
  lcnt:cardinal;
//  i:integer;
begin
  result:=nil;
  lcnt:=AStream.ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    AStream.Read(result[0],lcnt*SizeOf(TTL2ModId));
  {
    for i:=0 to lcnt-1 do
    begin
      result[i].modid:=PInt64(abuf+apos)^; inc(apos,8);
    end;
  }
  end;
end;

function ReadShortStringList(AStream:TTL2Stream):TTL2StringList;
var
  lcnt:cardinal;
  i:integer;
begin
  result:=nil;
  lcnt:=AStream.ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
    begin
      result[i]:=AStream.ReadShortString();
    end;
  end;
end;

end.
