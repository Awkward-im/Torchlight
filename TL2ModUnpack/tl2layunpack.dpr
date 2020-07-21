{$I-}

uses
  sysutils,
  TL2DatNode,
  TL2Memory;

type
  TAttribute = (
      t_unknown,t_integer,t_float,t_double,t_unsigned_int,
      t_string,t_bool,t_integer64,t_translate);

type
  TLayChunkHeader = packed record
    asize:integer; // including size
    atype:byte;    // object type
    id   :int64;
  end;
  TLaySubChunkHeader = packed record
    asize:word;   // excluding size
    atype:byte;   // tag type
  end;

  
var
  objcount:integer;
  _filestart:pbyte;
  lver:byte;
  slout,tags,sobj:PTL2Node;
  numbuffer:array [0..31] of WideChar;

function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);
  repeat
    if s1^<>s2^ then exit(false);
    if s1^=#0 then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;

function GetPropInfo(aobj:PTL2Node; atype:integer; out aname:PWideChar):integer;
var
  llobj,lobj:PTL2node;
  pcw:PWideChar;
  i,j:integer;
begin
  result:=ntUnknown;
  llobj:=nil;
  for i:=0 to aobj^.childcount-1 do
  begin
    lobj:=@aobj^.children^[i];
    if (lobj^.nodetype=ntGroup) and CompareWide(lobj^.Name,'PROPERTY') then
    begin
      for j:=0 to lobj^.childcount-1 do
      begin
        if CompareWide(lobj^.children^[j].Name,'ID') then
        begin
          if lobj^.children^[j].asInteger=atype then
          begin
            llobj:=lobj;
          end;
          break;
        end;
      end;
      if llobj<>nil then
      begin
        for j:=0 to llobj^.childcount-1 do
        begin
          if CompareWide(llobj^.children^[j].Name,'NAME') then
            aname:=llobj^.children^[j].asString
          else if CompareWide(llobj^.children^[j].Name,'TYPEOFDATA') then
          begin
            pcw:=llobj^.children^[j].asString;
            if      CompareWide(pcw,'VECTOR3'         ) then result:=ntVector
            else if CompareWide(pcw,'BOOL'            ) then result:=ntBool
            else if CompareWide(pcw,'FLOAT'           ) then result:=ntFloat
            else if CompareWide(pcw,'STRING'          ) then result:=ntString
            else if CompareWide(pcw,'UNSIGNED INTEGER') then result:=ntUnsigned
            else if CompareWide(pcw,'INT64'           ) then result:=ntInteger64
            else if CompareWide(pcw,'INTEGER'         ) then result:=ntInteger
            else
writeln('UNKNOWN PROPRETY TYPE ',string(widestring(pcw)));
          end;
        end;

        exit;
      end;
    end;
  end;
end;

function GetObjectStr(aid:integer; out aobj:PTL2Node):PWideChar;
var
  lobj:PTL2Node;
  lsw:WideString;
  i,j:integer;
begin
  aobj:=nil;
  // obj points to "OBJECT GROUP"
  // cycle through OBJECT
  for i:=0 to sobj^.childcount-1 do
  begin
    lobj:=@sobj^.children^[i];
    // cycle through object fields
    for j:=0 to lobj^.childcount-1 do
    begin
      if CompareWide(lobj^.children^[j].Name,'ID') then
      begin
        if lobj^.children^[j].asInteger=aid then
          aobj:=lobj;
        break;
      end;
    end;
    if aobj<>nil then break;
  end;
  for i:=0 to aobj^.childcount-1 do
  begin
    if CompareWide(aobj^.children^[i].Name,'NAME') then
    begin
      result:=aobj^.children^[i].asString;
      exit;
    end;
  end;

  Str(aid,lsw);
  numbuffer:=lsw;
  result:=@numbuffer;
end;


procedure DoParseBlock(var anode:PTL2Node; var aptr:pByte; const aparent:Int64);
var
  llnode,lnk,bnode,lobj,lnode:PTL2Node;
  ch :TLayChunkHeader;
  sch:TLaySubChunkHeader;
  pname,pcw:PWideChar;
  lsize,llcnt,i,j,lcnt:integer;
  lint:integer;
  lfloat:single;
  ldouble:double;
  lint64:int64;
  laptr,llptr:pbyte;
begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');
  llptr:=aptr;
  ch.asize:=ReadInteger(aptr);
  ch.atype:=ReadByte(aptr);
  ch.id   :=ReadInteger64(aptr);
  pname:=GetObjectStr(ch.atype,lobj);
  AddText(lnode,'DESCRIPTOR',pname,ntString);
  pcw:=ReadShortString(aptr);
  if pcw<>nil then
  begin
    AddText(lnode,'NAME',pcw,ntString);
    FreeMem(pcw);
  end
  else
    AddText(lnode,'NAME',pname,ntString);
  AddInteger64(lnode,'PARENTID',aparent);
  AddInteger64(lnode,'ID',ch.id);

//writeln(HexStr(llptr-_filestart,8),' object start ',ch.atype);

  //--- Properties

  lcnt:=ReadByte(aptr); // ?? count?
  for i:=0 to lcnt-1 do
  begin
    laptr:=aptr;
    sch.asize:=ReadWord(aptr);
    if sch.asize=0 then
    begin
writeln('size=0');
      break;
    end;
    sch.atype:=ReadByte(aptr);
    case GetPropInfo(lobj,sch.atype,pname) of
      ntBool: begin
		    lint:=ReadInteger(aptr);
        AddBool(lnode,pname,lint<>0);
      end;
      ntInteger: begin
		    lint:=ReadInteger(aptr);
		    AddInteger(lnode,pname,lint);
      end;
      ntUnsigned: begin
		    lint:=ReadInteger(aptr);
		    AddUnsigned(lnode,pname,lint);
      end;
      ntFloat: begin
		    lfloat:=ReadFloat(aptr);
		    AddFloat(lnode,pname,lfloat);
      end;
      ntDouble: begin
		    ldouble:=ReadDouble(aptr);
		    AddDouble(lnode,pname,ldouble);
      end;
      ntInteger64: begin
		    lint64:=ReadInteger64(aptr);
		    AddInteger64(lnode,pname,lint64);
      end;
      ntString: begin
		    pcw:=ReadShortString(aptr);
		    AddText(lnode,pname,pcw,ntString);
		    FreeMem(pcw);
      end;
      ntVector: begin
        lfloat:=ReadFloat(aptr);
        AddFloat(lnode,PWideChar(WideString(pname)+'X'),lfloat);
        lfloat:=ReadFloat(aptr);
        AddFloat(lnode,PWideChar(WideString(pname)+'Y'),lfloat);
        lfloat:=ReadFloat(aptr);
        AddFloat(lnode,PWideChar(WideString(pname)+'Z'),lfloat);
      end;
    else
writeln(HexStr(laptr-_filestart,8),' prop type ',sch.atype,' size ',sch.asize);
    inc(aptr,sch.asize-1);
    end;
  end;

  //--- Logic group

  lsize:=ReadInteger(aptr); //!!
  if lsize>0 then
  begin
    lcnt:=ReadByte(aptr);
    writeln('size = ',lsize,'; count=',lcnt);
    lnode:=AddGroup(lnode,'LOGICGROUP');
    for i:=0 to lcnt-1 do
    begin
      llnode:=AddGroup(lnode,'LOGICOBJECT');
      lint:=ReadByte(aptr);
      AddUnsigned(llnode,'ID',lint);
      lint64:=ReadInteger64(aptr);
      AddInteger64(llnode,'OBJECTID',lint64);
      lfloat:=ReadFloat(aptr);
      AddFloat(llnode,'X',lfloat);
      lfloat:=ReadFloat(aptr);
      AddFloat(llnode,'Y',lfloat);
      lsize:=ReadInteger(aptr); //!!

      llcnt:=ReadByte(aptr);
      for j:=0 to llcnt-1 do
      begin
        lnk:=AddGroup(llnode,'LOGICLINK');
        lint:=ReadByte(aptr);
        AddInteger(lnk,'LINKINGTO',lint);
        pcw:=ReadShortString(aptr);
        AddText(lnk,'OUTPUTNAME',pcw,ntString);
        FreeMem(pcw);
        pcw:=ReadShortString(aptr);
        AddText(lnk,'INPUTNAME',pcw,ntString);
        FreeMem(pcw);
      end;
    end;
  end;

  //--- Children

  lcnt:=ReadWord(aptr);
writeln('child ',lcnt);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      DoParseBlock(lnode,aptr,ch.id);
    end;
  end;
  aptr:=llptr+ch.asize;
end;

procedure DoParse(buf:pByte);
var
  lobj,lc:PTL2Node;
  lptr:pByte;
  i,lcnt,llayver:integer;
begin
  lptr:=buf;
  lver:=ReadByte(lptr);
  if lver=$5A then
  begin
    inc(lptr,7);
  end;
  if lver=11 then
  begin
    slout:=AddGroup(nil,'Layout');
    llayver:=ReadByte(lptr); // Layout version
    AddInteger(slout,'VERSION',llayver);
    lc:=AddUnsigned(slout,'COUNT',0);
    ReadDWord(lptr); // ofs?? of what?!
    lcnt:=ReadWord (lptr); // root baseobject count
    lobj:=AddGroup(slout,'OBJECTS');
    for i:=0 to lcnt-1 do
      DoParseBlock(lobj,lptr,-1);
    lc^.asUnsigned:=objcount;
  end;
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
_filestart:=buf;
    objcount:=0;
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
        if (lext='.LAYOUT') then
        begin
          DoProcessFile(lname);
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

begin
  tags:=ParseDatFile('objects.dat');
  sobj:=FindNode(tags,'SCENE\OBJECT GROUP\');
  if ParamCount=0 then
    cycleDir('.')
  else
    doprocessfile(paramstr(1));
  DeleteNode(tags);
end.
