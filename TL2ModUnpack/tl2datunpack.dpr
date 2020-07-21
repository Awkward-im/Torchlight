{$I-}

uses
  sysutils,
  TL2DatNode,
  TL2Memory;

type
  TAttribute = (
      t_unknown,t_integer,t_float,t_double,t_unsigned_int,
      t_string,t_bool,t_integer64,t_translate);

var
  fver:byte;
  slout,tags:PTL2Node;
  sl:array of record
    id  :integer;
    astr:PWideChar;
  end;
  numbuffer:array [0..31] of WideChar;

function GetStr(aid:integer):PWideChar;
var
  i:integer;
begin
  for i:=0 to High(sl) do
  begin
    if sl[i].id=aid then
    begin
      result:=sl[i].astr;
      exit;
    end;
  end;
  result:=nil;
end;

function GetTagStr(aid:integer):PWideChar;
var
  lsw:WideString;
  i:integer;
begin
  if fver=1 then
  begin
    result:=GetStr(aid);
    exit;
  end;

  i:=1;
  while i<tags^.childcount do
  begin
    if tags^.children^[i].asInteger=aid then
    begin
      result:=tags^.children^[i-1].asString;
      exit;
    end;
    inc(i,2);
  end;
  Str(aid,lsw);
  numbuffer:=lsw;
  result:=@numbuffer;
end;

procedure DoParseBlock(var anode:PTL2Node; var aptr:pByte);
var
  lnode:PTL2Node;
  lblock,i,lcnt,lsub,ltype:integer;
  lint:integer;
  lfloat:single;
  ldouble:double;
  lint64:int64;
  lid:integer;
begin
  lblock:=ReadInteger(aptr);

  lnode:=AddGroup(anode,GetTagStr(lblock));
  if anode=nil then anode:=lnode;

  lcnt:=ReadInteger(aptr);
  for i:=0 to lcnt-1 do
  begin
    lid:=ReadInteger(aptr);
    ltype:=ReadDword(aptr);
    case TAttribute(ltype) of
		  t_integer: begin
		    lint:=ReadInteger(aptr);
		    AddInteger(lnode,GetTagStr(lid),lint);
		  end;
		  t_unsigned_int: begin
		    lint:=ReadInteger(aptr);
		    AddUnsigned(lnode,GetTagStr(lid),lint);
		  end;
		  t_bool: begin
		    lint:=ReadInteger(aptr);
        AddBool(lnode,GetTagStr(lid),lint<>0);
		  end;
		  t_string: begin
		    lint:=ReadInteger(aptr);
		    AddText(lnode,GetTagStr(lid),GetStr(lint),ntString);
		  end;
		  t_translate: begin
		    lint:=ReadInteger(aptr);
		    AddText(lnode,GetTagStr(lid),GetStr(lint),ntTranslate);
		  end;
		  t_float: begin
		    lfloat:=ReadFloat(aptr);
		    AddFloat(lnode,GetTagStr(lid),lfloat);
		  end;
		  t_double: begin
		    ldouble:=ReadDouble(aptr);
		    AddDouble(lnode,GetTagStr(lid),ldouble);
		  end;
		  t_integer64: begin
		    lint64:=ReadInteger64(aptr);
		    AddInteger64(lnode,GetTagStr(lid),lint64);
		  end;
		else
		  lint:=ReadInteger(aptr);
		  AddCustom(lnode,GetTagStr(lid),
		      PWideChar(WideString(IntToStr(lint))),   //!!!!!!!!111
		      PWideChar(WideString(IntToStr(ltype)))); //!!!!!!!!!1
    end;
  end;

  lsub:=ReadInteger(aptr);
  for i:=0 to lsub-1 do
    DoParseBlock(lnode,aptr);
end;

procedure DoParse(buf:pByte);
var
  lptr:pByte;
  i,lcnt:integer;
begin
  lptr:=buf;
  fver:=ReadByte(lptr);
  if fver<=2 then inc(lptr,3);
  lcnt:=ReadInteger(lptr);
  SetLength(sl,lcnt);
  for i:=0 to lcnt-1 do
  begin
    sl[i].id:=ReadInteger(lptr);
    case fver of
      1: sl[i].astr:=ReadDwordString(lptr);      // TL1
      2: sl[i].astr:=ReadShortString(lptr);      // TL2
      6: sl[i].astr:=ReadShortStringUTF8(lptr);  // Hob
    end;
  end;

  DoParseBlock(slout,lptr);
  for i:=0 to lcnt-1 do
    FreeMem(sl[i].astr);
  SetLength(sl,0);
end;

procedure DoProcessFile(const fname:string);
var
  f:file of byte;
  buf:pByte;
  l:integer;
begin
  Assign(f,fname);
  Reset(f);
  if IOResult=0 then
  begin
    l:=FileSize(f);
    GetMem(buf,l);
    BlockRead(f,buf^,l);
    slout:=nil;
    DoParse(buf);
    WriteDatTree(slout,PChar(fname+'.TXT'));
    DeleteNode(slout);
    FreeMem(buf);
    Close(f);
  end;
end;

procedure CycleDir(const adir:String);
var
  sr:TSearchRec;
  lext:string;
  lname:AnsiString;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(lname);
      end
      else
      begin
        lext:=UpCase(ExtractFileExt(lname));
        if (lext='.DAT') or
//           (lext='.LAYOUT') or
           (lext='.ANIMATION') then
        begin
          if UpCase(ExtractFileName(lname))<>'TAGS.DAT' then
            DoProcessFile(lname);
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

begin
  tags:=ParseDatFile('tags.dat');
  if ParamCount=0 then
    cycleDir('.')
  else
    doprocessfile(paramstr(1));
  DeleteNode(tags);
end.
