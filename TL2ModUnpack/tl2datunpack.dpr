{$I-}

uses
  Classes,sysutils,
  TL2DatNode,
  TL2Memory;

type
  TAttribute = (
      t_unknown,t_integer,t_float,t_double,t_unsigned_int,
      t_string,t_bool,t_integer64,t_translate);

const
  deepincr = 2;
  
var
  tags,sl,slout:TStringList;

procedure LoadTags;
var
  tmptags:TStringList;
  i:integer;
  lid:integer;
begin
  tmptags:=TStringList.Create;
  try
    tmptags.LoadFromFile('tags.dat',TEncoding.Unicode);
    i:=1;
    tags.Capacity:=tmptags.count div 2;
    while i<(tmptags.count-1) do
    begin
      Val(Copy(tmptags[i+1],Pos(':',tmptags[i+1])+1),lid);
      tags.AddObject(Copy(tmptags[i],Pos(':',tmptags[i])+1),TObject(IntPtr(lid)));
      inc(i,2);
    end;
  except
  end;
  tmptags.Free;
end;

function GetTagStr(aid:integer):string;
var
  i:integer;
begin
  for i:=0 to tags.count-1 do
  begin
    if IntPtr(tags.Objects[i])=aid then
    begin
      result:=tags[i];
      exit;
    end;
  end;
  Str(aid,result);
end;

function GetStr(aid:integer):string;
var
  i:integer;
begin
  for i:=0 to sl.Count-1 do
  begin
    if UIntPtr(sl.Objects[i])=aid then
    begin
      result:=sl[i];
      exit;
    end;
  end;
  result:='';
end;

var
  deep:integer;

procedure DoParseBlock(var lptr:pByte);
var
  lblock,i,lcnt,lsub,ltype:integer;
  lstr,ls:string;
  lint:integer;
  lfloat:single;
  ldouble:double;
  lint64:int64;
  lid:integer;
begin
  lblock:=ReadInteger(lptr);

  slout.Add(StringOfChar(' ',deep)+'['+GetTagStr(lblock)+']');
  inc(deep,deepincr);
  ls:=StringOfChar(' ',deep);

  lcnt:=ReadInteger(lptr);
  for i:=0 to lcnt-1 do
  begin
    lid:=ReadInteger(lptr);
    ltype:=ReadDword(lptr);
    case TAttribute(ltype) of
		  t_integer: begin
		    lint:=ReadInteger(lptr);
		    slout.Add(ls+'<INTEGER>'+GetTagStr(lid)+':'+IntToStr(lint));
		  end;
		  t_unsigned_int: begin
		    lint:=ReadInteger(lptr);
		    slout.Add(ls+'<UNSIGNED INT>'+GetTagStr(lid)+':'+IntToStr(dword(lint)));
		  end;
		  t_bool: begin
		    lint:=ReadInteger(lptr);
		    if lint=0 then
  		    slout.Add(ls+'<BOOL>'+GetTagStr(lid)+':false')
		    else
          slout.Add(ls+'<BOOL>'+GetTagStr(lid)+':true');
		  end;
		  t_string: begin
		    lint:=ReadInteger(lptr);
		    slout.Add(ls+'<STRING>'+GetTagStr(lid)+':'+GetStr(lint));
		  end;
		  t_translate: begin
		    lint:=ReadInteger(lptr);
		    slout.Add(ls+'<TRANSLATE>'+GetTagStr(lid)+':'+GetStr(lint));
		  end;
		  t_float: begin
		    lfloat:=ReadFloat(lptr);
		    Str(lfloat:0:4,lstr);
		    slout.Add(ls+'<FLOAT>'+GetTagStr(lid)+':'+lstr);
		  end;
		  t_double: begin
		    ldouble:=ReadDouble(lptr);
		    Str(ldouble:0:4,lstr);
		    slout.Add(ls+'<DOUBLE>'+GetTagStr(lid)+':'+lstr);
		  end;
		  t_integer64: begin
		    lint64:=ReadInteger64(lptr);
		    slout.Add(ls+'<INTEGER64>'+GetTagStr(lid)+':'+IntToStr(lint64));
		  end;
		else
		  lint:=ReadInteger(lptr);
		  slout.Add(ls+'<'+IntToStr(ltype)+'>'+GetTagStr(lid)+':'+IntToStr(lint));
    end;
  end;

  lsub:=ReadInteger(lptr);
  for i:=0 to lsub-1 do
    DoParseBlock(lptr);

  dec(deep,deepincr);
  slout.Add(StringOfChar(' ',deep)+'[/'+GetTagStr(lblock)+']');
end;

procedure DoParse(buf:pByte);
var
  lptr:pByte;
  lstr:PWideChar;
  lver:byte;
  i,lcnt:integer;
  lid:integer;
begin
  lptr:=buf;
  lver:=Readinteger(lptr);
  sl:=TStringList.Create;
  lcnt:=ReadInteger(lptr);
  sl.Capacity:=lcnt;
  for i:=0 to lcnt-1 do
  begin
    lid :=ReadInteger(lptr);
    lstr:=ReadShortString(lptr);
    sl.AddObject(UTF8Encode(WideString(lstr)),TObject(UIntPtr(lid)));
    FreeMem(lstr);
  end;

  DoParseBlock(lptr);
  sl.Free;
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
    slout:=TStringList.Create;
    DoParse(buf);
    slout.WriteBOM:=true;
    slout.SaveToFile(fname+'.TXT',TEncoding.Unicode);
    slout.Free;
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
  tags:=TStringList.Create;
  LoadTags();
  if ParamCount=0 then
    cycleDir('.')
  else
    doprocessfile(paramstr(1));
  tags.Free;
end.
