{$I-}

uses
  classes,
  sysutils,
  TL2DatNode,
  TL2Memory;

type
  TAttribute = (
      t_unknown,t_integer,t_float,t_double,t_unsigned_int,
      t_string,t_bool,t_integer64,t_translate);

//var slglob:TStringList;

var
  dict:array of record hash:dword; name:string end;
var
  slout,ctags,tags:PTL2Node;
  numbuffer:array [0..31] of WideChar;
  sl:array of record
    id  :integer;
    astr:PWideChar;
  end;
  strbuf:wideString;
  fver:byte;

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

  if dict<>nil then
  begin
    for i:=0 to High(dict) do
    begin
      if dict[i].hash=dword(aid) then
      begin
        strbuf:=WideString(dict[i].name);
        result:=pointer(strbuf);
        exit;
      end;
    end;
  end
  else if tags<>nil then
  begin
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
  end;

  if ctags<>nil then
  begin
    i:=1;
    while i<ctags^.childcount do
    begin
      if ctags^.children^[i].asInteger=aid then
      begin
        result:=ctags^.children^[i-1].asString;
        exit;
      end;
      inc(i,2);
    end;
  end;
  
  if dict<>nil then
    Str(dword(aid),lsw)
  else
    Str(aid,lsw);
  numbuffer:=lsw;
  result:=@numbuffer;

//slglob.Add(IntToStr(dword(aid)));
end;

procedure DoParseBlock(var anode:PTL2Node; var aptr:pByte);
var
  ldouble:double;
  lint64:int64;
  lnode:PTL2Node;
  lname:PWideChar;
  lfloat:single;
  lblock,i,lcnt,lsub,ltype:integer;
  lint:integer;
  luint:longword;
begin
  lblock:=ReadInteger(aptr);

  lnode:=AddGroup(anode,GetTagStr(lblock));
  if anode=nil then anode:=lnode;

  lcnt:=ReadInteger(aptr);
  for i:=0 to lcnt-1 do
  begin
    lname:=GetTagStr(ReadInteger(aptr));
    ltype:=ReadDword(aptr);

    case TAttribute(ltype) of
		  t_integer: begin
		    lint:=ReadInteger(aptr);
		    AddInteger(lnode,lname,lint);
		  end;
		  t_unsigned_int: begin
		    luint:=ReadInteger(aptr);
		    AddUnsigned(lnode,lname,luint);
		  end;
		  t_bool: begin
		    lint:=ReadInteger(aptr);
        AddBool(lnode,lname,lint<>0);
		  end;
		  t_string: begin
		    lint:=ReadInteger(aptr);
		    AddText(lnode,lname,GetStr(lint),ntString);
		  end;
		  t_translate: begin
		    lint:=ReadInteger(aptr);
		    AddText(lnode,lname,GetStr(lint),ntTranslate);
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
    Close(f);

    slout:=nil;
  
    DoParse(buf);
    FreeMem(buf);

    WriteDatTree(slout,PChar(fname+'.TXT'));
    DeleteNode(slout);
  end;
end;

procedure CycleDir(const adir:String);
var
  sr:TSearchRec;
  lext,ls:string;
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
           (lext='.ANIMATION') then
        begin
          ls:=UpCase(ExtractFileName(lname));
          if (ls<>'TAGS.DAT') and (ls<>'CUSTOM.DAT') then
            DoProcessFile(lname);
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

procedure LoadDict(const aname:string);
var
  sl:TStringList;
  i,p:integer;
begin
  sl:=TStringList.Create;
  try
    sl.LoadFromFile('dictionary.txt');
    SetLength(dict,sl.Count);
    for i:=0 to sl.Count-1 do
    begin
      p:=Pos(':',sl[i]);
      Val(Copy(sl[i],1,p-1),dict[i].hash);
      dict[i].name:=Copy(sl[i],p+1);
    end;
  except
    dict:=nil;
  end;
  sl.Free;
end;

begin
{
slglob:=TStringList.Create;
slglob.Sorted:=True;
}
  LoadDict('dictionary.txt');
  if dict<>nil then
    tags:=nil
  else
    tags :=ParseDatFile('tags.dat');
  ctags:=ParseDatFile('custom.dat');
  if ParamCount=0 then
    cycleDir('.')
  else
    doprocessfile(paramstr(1));
  SetLength(dict,0);
  DeleteNode(ctags);
  DeleteNode(tags);
{
slglob.Sort;
slglob.SaveToFile('hashes.txt');
slglob.Free;
}
end.
