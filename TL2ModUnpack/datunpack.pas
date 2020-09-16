unit DATUnpack;

interface

uses
  TL2DatNode;


function DoParseDat(buf:pByte):PTL2Node;


implementation

uses
  sysutils,
  rgglobal,
  TL2Memory;

type
  TAttribute = (
      t_not_set,t_integer,t_float,t_double,t_unsigned_int,
      t_string,t_bool,t_integer64,t_translate,t_note);

var
  locdict:array of record
    id  :dword;
    astr:PWideChar;
  end;
var
  aliases:TDict;
  tried:boolean;
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

function GetTagStr(aid:dword):PWideChar;
var
  i:integer;
begin
  result:=nil;

  if fver=verTL1 then
  begin
    result:=GetLocalStr(aid);
    if result<>nil then exit;
  end;

  if not tried then
  begin
    tried:=true;
    LoadDictCustom(aliases,'dataliases.txt');
  end;

  if aliases<>nil then
  begin
    for i:=0 to High(aliases) do
    begin
      if aliases[i].hash=aid then
      begin
        buffer:=WideString(aliases[i].name);
        result:=pointer(buffer);
        exit;
      end;
    end;
  end;

  if dict=nil then LoadDict;
  if dict<>nil then
  begin
    for i:=0 to High(dict) do
    begin
      if dict[i].hash=aid then
      begin
        buffer:=WideString(dict[i].name);
        result:=pointer(buffer);
        exit;
      end;
    end;
  end;

  if cdict=nil then LoadDictCustom(cdict,'hashed.txt');
  if cdict<>nil then
  begin
    for i:=0 to High(cdict) do
    begin
      if cdict[i].hash=aid then
      begin
        buffer:=WideString(cdict[i].name);
        result:=pointer(buffer);
        exit;
      end;
    end;
  end;

  Str(aid,buffer);
  result:=pointer(buffer);

  if hashlog<>nil then
  begin
//writeln(curfname);
    hashlog.Add(IntToStr(aid));
  end;
end;

procedure DoParseBlock(var anode:PTL2Node; var aptr:pByte);
var
  ldouble:double;
  lint64:int64;
  lnode:PTL2Node;
  lname:PWideChar;
  lfloat:single;
  i,lcnt,lsub,ltype:integer;
  lint:integer;
  luint:longword;
begin
  lnode:=AddGroup(anode,GetTagStr(ReadDWord(aptr)));
  if anode=nil then anode:=lnode;

  lcnt:=ReadInteger(aptr);
  for i:=0 to lcnt-1 do
  begin
    lname:=GetTagStr(ReadDWord(aptr));
    ltype:=ReadDword(aptr);

    case TAttribute(ltype) of
		  t_integer: begin
		    lint:=ReadInteger(aptr);
		    AddInteger(lnode,lname,lint);
		  end;
		  t_unsigned_int: begin
		    luint:=ReadDWord(aptr);
		    AddUnsigned(lnode,lname,luint);
		  end;
		  t_bool: begin
		    lint:=ReadInteger(aptr);
        AddBool(lnode,lname,lint<>0);
		  end;
		  t_string: begin
		    luint:=ReadDWord(aptr);
		    AddText(lnode,lname,GetLocalStr(luint),ntString);
		  end;
		  t_translate: begin
		    luint:=ReadDWord(aptr);
		    AddText(lnode,lname,GetLocalStr(luint),ntTranslate);
		  end;
		  t_float: begin
		    lfloat:=ReadFloat(aptr);
		    AddFloat(lnode,lname,lfloat);
		  end;
		  t_double: begin
		    ldouble:=ReadDouble(aptr);
		    AddDouble(lnode,lname,ldouble);
		  end;
		  t_integer64: begin
		    lint64:=ReadInteger64(aptr);
		    AddInteger64(lnode,lname,lint64);
		  end;
		else
		  lint:=ReadInteger(aptr);
		  AddCustom(lnode,lname,
		      PWideChar(WideString(IntToStr(lint))),   //!!!!!!!!
		      PWideChar(WideString(IntToStr(ltype)))); //!!!!!!!!
    end;
  end;

  lsub:=ReadInteger(aptr);
  for i:=0 to lsub-1 do
    DoParseBlock(lnode,aptr);
end;

function DoParseDat(buf:pByte):PTL2Node;
var
  lptr:pByte;
  i,lcnt:integer;
begin
  result:=nil;

  lptr:=buf;

  // version

  fver:=ReadByte(lptr);
  if fver<=2 then inc(lptr,3);
  case fver of
    1: fver:=verTL1;
    2: fver:=verTL2;
    6: fver:=verHob;
  end;

  // local dictionary

  lcnt:=ReadInteger(lptr);
  SetLength(locdict,lcnt);
  for i:=0 to lcnt-1 do
  begin
    locdict[i].id:=ReadDWord(lptr);
    case fver of
      verTL1: locdict[i].astr:=ReadDwordString(lptr);
      verTL2: locdict[i].astr:=ReadShortString(lptr);
      verHob: locdict[i].astr:=ReadShortStringUTF8(lptr);
    end;
  end;

  // data

  DoParseBlock(result,lptr);

  // clear

  for i:=0 to lcnt-1 do
    FreeMem(locdict[i].astr);
  SetLength(locdict,0);
end;

initialization

  tried:=false;

end.
