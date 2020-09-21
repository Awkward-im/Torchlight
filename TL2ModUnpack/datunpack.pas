unit DATUnpack;

interface

uses
  TL2DatNode;


function DoParseDat (buf:pByte):pointer;
function IsProperDat(buf:pByte):boolean;

implementation

uses
  sysutils,
  rgglobal,
  rgdict,
  rgtypes,
  TL2Memory;

var
  locdict:array of record
    id  :dword;
    astr:PWideChar;
  end;
var
  tdict,dict,cdict,aliases:pointer;
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
begin
  if aid=0 then exit(nil);

  result:=nil;

  if fver=verTL1 then
  begin
    result:=GetLocalStr(aid);
    if result<>nil then exit;
  end;

  if aliases=pointer(-1) then LoadTags(aliases,'dataliases.txt');
  result:=GetTagStr(aliases,aid);

  if result=nil then
  begin
    if dict=pointer(-1) then LoadTags(dict);
    result:=GetTagStr(dict,aid);

    if result=nil then
    begin
      if cdict=pointer(-1) then LoadTags(cdict,'hashed.txt');
      result:=GetTagStr(cdict,aid);
    end;

    if result=nil then
    begin
      if tdict=pointer(-1) then LoadTags(tdict,'tagdict.txt');
      result:=GetTagStr(tdict,aid);
    end;
  end;

  if result=nil then
  begin
    //!!!!!!
    if fver<>verTL1 then
    begin
      result:=GetLocalStr(aid);
      if result<>nil then exit;
    end;

    Str(aid,buffer);
    result:=pointer(buffer);

    if hashlog<>nil then
    begin
  //writeln(curfname);
      hashlog.Add(IntToStr(aid));
    end;
  end;
end;

procedure DoParseBlock(var anode:pointer; var aptr:pByte);
var
  ldouble:double;
  lint64:int64;
  lnode:pointer;
  lname:PWideChar;
  lfloat:single;
  i,lcnt,lsub,ltype:integer;
  lint:integer;
  luint:longword;
begin
  lnode:=AddGroup(anode,GetStr(ReadDWord(aptr)));
  if anode=nil then anode:=lnode;

  lcnt:=ReadInteger(aptr);
  for i:=0 to lcnt-1 do
  begin
    lname:=GetStr(ReadDWord(aptr));
    ltype:=ReadDword(aptr);

    case ltype of
		  rgInteger: begin
		    lint:=ReadInteger(aptr);
		    AddInteger(lnode,lname,lint);
		  end;
		  rgUnsigned: begin
		    luint:=ReadDWord(aptr);
		    AddUnsigned(lnode,lname,luint);
		  end;
		  rgBool: begin
		    lint:=ReadInteger(aptr);
        AddBool(lnode,lname,lint<>0);
		  end;
		  rgString: begin
		    luint:=ReadDWord(aptr);
		    AddString(lnode,lname,GetLocalStr(luint));
		  end;
		  rgTranslate: begin
		    luint:=ReadDWord(aptr);
		    AddTranslate(lnode,lname,GetLocalStr(luint));
		  end;
		  rgFloat: begin
		    lfloat:=ReadFloat(aptr);
		    AddFloat(lnode,lname,lfloat);
		  end;
		  rgDouble: begin
		    ldouble:=ReadDouble(aptr);
		    AddDouble(lnode,lname,ldouble);
		  end;
		  rgInteger64: begin
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

function DoParseDat(buf:pByte):pointer;
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
      verHob,
      verRG : locdict[i].astr:=ReadShortStringUTF8(lptr);
    end;
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

  aliases:=pointer(-1);
  dict   :=pointer(-1);
  cdict  :=pointer(-1);
  tdict  :=pointer(-1);

finalization
  
  if aliases<>pointer(-1) then FreeTags(aliases);
  if dict   <>pointer(-1) then FreeTags(dict);
  if cdict  <>pointer(-1) then FreeTags(cdict);
  if tdict  <>pointer(-1) then FreeTags(tdict);

end.
