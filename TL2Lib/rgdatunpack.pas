unit RGDATUnpack;

interface

function IsProperDat(buf:pByte):boolean;
{
  resulting pointer is PTL2Node from RGNode.pas
  So, it requires to free by DeleteNode later
}
function DoParseDat (buf:pByte):pointer;
function DoParseDatFile(const afname:string):pointer;


implementation

uses
  sysutils,
  rgglobal,
  rglogging,
  rgnode,
  rgdict,
  rgmemory;

var
  known,unkn:TRGDict;
var
  aliases:TRGDict;
  buffer:WideString;

function GetStr(aid:dword; const alocals:TRGDict; aver:byte):PWideChar;
begin
  if aver=verTL1 then
  begin
    result:=alocals.Tag[aid];
    exit;
  end;

  result:=aliases.Tag[aid];

  if result=nil then
    result:=RGTags.Tag[aid];

  if result=nil then
  begin
    RGLog.Add('Unknown tag with hash '+IntToStr(aid));
    Str(aid,buffer);
    result:=pointer(buffer);

    unkn.add(aid,nil);
  end
  else
    known.add(aid,result);
end;

procedure DoParseBlock(var anode:pointer; var aptr:pByte; const alocals:TRGDict; aver:byte);
var
  lnode:pointer;
  lname:PWideChar;
  i,lcnt,lsub,ltype:integer;
begin
  lnode:=AddGroup(anode,GetStr(memReadDWord(aptr),alocals,aver));
  if anode=nil then anode:=lnode;

  lcnt:=memReadInteger(aptr);
  for i:=0 to lcnt-1 do
  begin
    lname:=GetStr(memReadDWord(aptr),alocals,aver);
    ltype:=integer(memReadDword(aptr)); //!!

    case ltype of
		  rgInteger  : AddInteger  (lnode,lname,memReadInteger  (aptr));
		  rgUnsigned : AddUnsigned (lnode,lname,memReadDWord    (aptr));
		  rgBool     : AddBool     (lnode,lname,memReadInteger  (aptr)<>0);
		  rgFloat    : AddFloat    (lnode,lname,memReadFloat    (aptr));
		  rgDouble   : AddDouble   (lnode,lname,memReadDouble   (aptr));
		  rgInteger64: AddInteger64(lnode,lname,memReadInteger64(aptr));
		  rgString   : AddString   (lnode,lname,alocals.Tag[memReadDWord(aptr)]);
		  rgTranslate: AddTranslate(lnode,lname,alocals.Tag[memReadDWord(aptr)]);
		  rgNote     : AddNote     (lnode,lname,alocals.Tag[memReadDWord(aptr)]);
		else
      lsub:=memReadInteger(aptr);
		  AddCustom(lnode,lname,
		      PWideChar(WideString(IntToStr(lsub))),   //!!!!!!!!
		      PWideChar(WideString(IntToStr(ltype)))); //!!!!!!!!
		  RGLog.Add('Non-standard tag '+IntToStr(ltype)+' with possible value '+IntToStr(lsub));
    end;
  end;

  lsub:=memReadInteger(aptr);
  for i:=0 to lsub-1 do
    DoParseBlock(lnode,aptr,alocals,aver);
end;

function DoParseDat(buf:pByte):pointer;
var
  pc:PWideChar;
  locals:TRGDict;
  lptr:pByte;
  lid:dword;
  i,lcnt:integer;
  lver:byte;
begin
  result:=nil;

  lptr:=buf;

  // version

  lver:=memReadByte(lptr);
  if lver<=2 then inc(lptr,3);
  case lver of
    1: lver:=verTL1;
    2: lver:=verTL2;
    6: lver:=verHob;
  else
    RGLog.Add('Unknown file version: '+IntToStr(lver));
    exit;
  end;

  // local dictionary

  lcnt:=memReadInteger(lptr);
  if lcnt<0 then
    RGLog.Add('Dictionary size < 0');
  locals.Init;
  locals.Capacity:=lcnt;

  for i:=0 to lcnt-1 do
  begin
    lid:=memReadDWord(lptr);
    case lver of
      verTL1: pc:=memReadDwordString(lptr);
      verTL2: pc:=memReadShortString(lptr);
      verHob,
      verRGO,
      verRG : pc:=memReadShortStringUTF8(lptr);
    end;
    locals.Add(lid,pc,true);
  end;

  // data

  DoParseBlock(result,lptr,locals,lver);

  // clear

  locals.Clear;
end;

function DoParseDatFile(const afname:string):pointer;
var
  f:file of byte;
  buf:PByte;
  l:integer;
begin
  Reset(f);
  if IOResult=0 then
  begin
    l:=FileSize(f);
    GetMem(buf,l);
    BlockRead(f,buf^,l);
    CloseFile(f);
    if IsProperDat(buf) then
      result:=DoParseDat(buf);

    FreeMem(buf);
  end;
end;

function IsProperDat(buf:pByte):boolean;
begin
  result:=buf^ in [1, 2, 6];
end;

initialization

  aliases.Init;
  aliases.Import('dataliases.txt');

  known.init;
  known.options:=[check_hash];

  unkn.init;
  unkn.options:=[check_hash];

finalization

{$IFDEF DEBUG}  
  if known.count>0 then
  begin
    known.Sort;
    known.export('known-dat.dict'    ,false);
    known.export('known-dat-txt.dict',false,false);
  end;
{$ENDIF}
  known.clear;

{$IFDEF DEBUG}  
  if unkn.count>0 then
  begin
    unkn.Sort;
    unkn.export('unknown-dat.dict',false);
  end;
{$ENDIF}
  unkn.clear;
  
  aliases.Clear;

end.
