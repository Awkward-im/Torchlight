unit DATUnpack;

interface

function DoParseDat (buf:pByte):pointer;
function IsProperDat(buf:pByte):boolean;


implementation

uses
  sysutils,
  rgglobal,
  rgnode,
  rgdict,
  rgmemory,
  deglobal;

var
  locdict:array of record
    id  :dword;
    astr:PWideChar;
  end;
var
  aliases:pointer;
  buffer:WideString;
  fver:byte;

function GetLocalStr(aid:dword):PWideChar;
var
  i:integer;
begin
  for i:=0 to High(locdict) do
  begin
    if locdict[i].id=aid then
    begin
      result:=locdict[i].astr;
      exit;
    end;
  end;
  result:=nil;
end;

function GetStr(aid:dword):PWideChar;
var
  i:integer;
begin
  if aid=0 then exit(nil);

  result:=nil;

  if fver=verTL1 then
  begin
    result:=GetLocalStr(aid);
//    if result<>nil then
    exit;
  end;

  result:=GetTagStr(aliases,aid);

  if result=nil then
  begin
    for i:=0 to High(dicts) do
    begin
      result:=GetTagStr(dicts[i],aid);
      if result<>nil then break;
    end;
{
    if result=nil then
    begin
  //    if fver<>verTL1 then
      begin
        result:=GetLocalStr(aid);
      end;
    end;
}
  end;

{$IFDEF DEBUG}
if result<>nil then datlog.Add(IntToStr(aid)+':'+string(WideString(result)));
{$ENDIF}

  if result=nil then
  begin
    Str(aid,buffer);
    result:=pointer(buffer);

    if hashlog<>nil then
    begin
      hashlog.Add(IntToStr(aid));
  //writeln(curfname);
      hashlog1.Add('DAT:'+IntToStr(aid));
    end;
  end;
end;

procedure DoParseBlock(var anode:pointer; var aptr:pByte);
var
  lnode:pointer;
  lname:PWideChar;
  i,lcnt,lsub,ltype:integer;
begin
  lnode:=AddGroup(anode,GetStr(memReadDWord(aptr)));
  if anode=nil then anode:=lnode;

  lcnt:=memReadInteger(aptr);
  for i:=0 to lcnt-1 do
  begin
    lname:=GetStr(memReadDWord(aptr));
    ltype:=memReadDword(aptr);

    case ltype of
		  rgInteger  : AddInteger  (lnode,lname,memReadInteger  (aptr));
		  rgUnsigned : AddUnsigned (lnode,lname,memReadDWord    (aptr));
		  rgBool     : AddBool     (lnode,lname,memReadInteger  (aptr)<>0);
		  rgFloat    : AddFloat    (lnode,lname,memReadFloat    (aptr));
		  rgDouble   : AddDouble   (lnode,lname,memReadDouble   (aptr));
		  rgInteger64: AddInteger64(lnode,lname,memReadInteger64(aptr));
		  rgString   : AddString   (lnode,lname,GetLocalStr(memReadDWord(aptr)));
		  rgTranslate: AddTranslate(lnode,lname,GetLocalStr(memReadDWord(aptr)));
		  rgNote     : AddNote     (lnode,lname,GetLocalStr(memReadDWord(aptr)));
		else
		  AddCustom(lnode,lname,
		      PWideChar(WideString(IntToStr(memReadInteger(aptr)))), //!!!!!!!!
		      PWideChar(WideString(IntToStr(ltype))));               //!!!!!!!!
    end;
  end;

  lsub:=memReadInteger(aptr);
  for i:=0 to lsub-1 do
    DoParseBlock(lnode,aptr);
end;

function DoParseDat(buf:pByte):pointer;
var
  lptr:pByte;
  i,lcnt:integer;
begin
  result:=nil;

  lptr:=buf;

  // version

  fver:=memReadByte(lptr);
  if fver<=2 then inc(lptr,3);
  case fver of
    1: fver:=verTL1;
    2: fver:=verTL2;
    6: fver:=verHob;
  else
    exit;
  end;

  // local dictionary

  lcnt:=memReadInteger(lptr);
  SetLength(locdict,lcnt);
  for i:=0 to lcnt-1 do
  begin
    locdict[i].id:=memReadDWord(lptr);
    case fver of
      verTL1: locdict[i].astr:=memReadDwordString(lptr);
      verTL2: locdict[i].astr:=memReadShortString(lptr);
      verHob,
      verRG : locdict[i].astr:=memReadShortStringUTF8(lptr);
    end;
{$IFDEF DEBUG}
datloclog.Add(IntToStr(
//RGHash(pointer(string(WideString(locdict[i].astr))),Length(locdict[i].astr))
  locdict[i].id
)+':'+string(WideString(locdict[i].astr)));

datloclog1.Add(IntToStr(
RGHash(pointer(string(WideString(locdict[i].astr))),Length(locdict[i].astr))
)+':'+string(WideString(locdict[i].astr)));
{$ENDIF}
  end;

  // data

  DoParseBlock(result,lptr);

  // clear

  for i:=0 to lcnt-1 do
    FreeMem(locdict[i].astr);
  SetLength(locdict,0);

end;

function IsProperDat(buf:pByte):boolean;
begin
  result:=buf^ in [1, 2, 6];
end;

initialization

  LoadTags(aliases,'dataliases.txt');

finalization
  
  if aliases<>nil then FreeTags(aliases);

end.
