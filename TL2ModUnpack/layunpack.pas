unit layunpack;

interface

uses
  TL2DatNode;


function DoParseLayout (buf:pByte):pointer;
function IsProperLayout(buf:pByte):boolean;


implementation

uses
  sysutils,
  rgglobal,
  rgdict,
  rgtypes,
  TL2Memory;

var
  tdict,aliases,dict,cdict:pointer;
  _filestart:PByte;
  buffer:WideString;
  objcount:integer;
  objInfo:pointer;
  fver:Byte;


function ReadStr(var aptr:PByte):PWideChar;
begin
  case fver of
    verTL2: result:=ReadShortString(aptr);
    verHob,
    verRG : result:=ReadShortStringUTF8(aptr);
  end;
end;

function GetStr(aid:dword):PWideChar;
begin
  if aid=0 then exit(nil);

  result:=nil;

  if aliases=pointer(-1) then LoadTags(aliases,'layaliases.txt');
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
    Str(aid,buffer);
    result:=pointer(buffer);

    if hashlog<>nil then
    begin
  //writeln(curfname);
      hashlog.Add(IntToStr(aid));
    end;
  end;
end;

const
  IdLogicGroup = 36;
  IdTimeline   = 35;

procedure ParseLogicGroup(var anode:pointer; var aptr:pByte);
var
  lgobj,lgroup,lglnk:pointer;
  pcw:PWideChar;
  lsize:integer;
  lgroups,lglinks,i,j:integer;
begin
  lgroup:=AddGroup(anode,'LOGICGROUP');
  lgroups:=ReadByte(aptr);
  for i:=0 to lgroups-1 do
  begin
    lgobj:=AddGroup(lgroup,'LOGICOBJECT');
    AddUnsigned (lgobj,'ID'      ,ReadByte     (aptr));
    AddInteger64(lgobj,'OBJECTID',ReadInteger64(aptr));
    AddFloat    (lgobj,'X'       ,ReadFloat    (aptr));
    AddFloat    (lgobj,'Y'       ,ReadFloat    (aptr));

    lsize:=ReadInteger(aptr); // absolute offset of next

    lglinks:=ReadByte(aptr);
    for j:=0 to lglinks-1 do
    begin
      lglnk:=AddGroup(lgobj,'LOGICLINK');
      AddInteger(lglnk,'LINKINGTO' ,ReadByte(aptr));
      case fver of
        verTL2: begin
          pcw :=ReadShortString(aptr); AddString(lglnk,'OUTPUTNAME',pcw); FreeMem(pcw);
          pcw :=ReadShortString(aptr); AddString(lglnk,'INPUTNAME' ,pcw); FreeMem(pcw);
        end;
        verHob: begin
          AddString(lglnk,'OUTPUTNAME',GetStr(ReadDWord(aptr)));
          AddString(lglnk,'INPUTNAME' ,GetStr(ReadDWord(aptr)));
        end;
      end;
    end;
  end;
end;

procedure ParseTimeline(var anode:pointer; aid:Int64; var aptr:pByte);
var
  tlpoint,tlnode,tldata,tlobject:pointer;
  pcw:PWideChar;
  laptr:pByte;
  lint,ltlpoints,ltltype,ltlprops,ltlobjs,i,j,k:integer;
begin
  tldata:=AddGroup(anode,'TIMELINEDATA');
  AddInteger64(tldata,'ID',aid);

  ltlobjs:=ReadByte(aptr);
  for i:=0 to ltlobjs-1 do
  begin
    tlobject:=AddGroup(tldata,'TIMELINEOBJECT');
    AddInteger64(tlobject,'OBJECTID',ReadInteger64(aptr));
    
    ltlprops:=ReadByte(aptr);
    for j:=0 to ltlprops-1 do
    begin
      ltltype:=0;
      laptr:=aptr;

      // Property
      pcw:=ReadStr(aptr);
      if pcw<>nil then
      begin
        ltltype:=1;
        tlnode:=AddGroup(tlobject,'TIMELINEOBJECTPROPERTY');
        AddString(tlnode,'OBJECTPROPERTYNAME',pcw);
        FreeMem(pcw);
      end;

      // Event
      pcw:=ReadStr(aptr);
      if pcw<>nil then
      begin
        if ltltype<>0 then
        begin
if IsConsole then writeln('Double Timeline type at ',HexStr(aptr-_filestart,8));
        end;
        ltltype:=2;
        tlnode:=AddGroup(tlobject,'TIMELINEOBJECTEVENT');
        AddString(tlnode,'OBJECTEVENTNAME',pcw);
        FreeMem(pcw);
      end;

      if ltltype=0 then
      begin
if IsConsole then writeln('Unknown Timeline type at ',HexStr(laptr-_filestart,8));
        tlnode:=AddGroup(tlobject,'??TIMELINEUNKNOWN');
      end;

      ltlpoints:=ReadByte(aptr);
      for k:=0 to ltlpoints-1 do
      begin
//writeln('point ',k);
        tlpoint:=AddGroup(tlnode,'TIMELINEPOINT');
        AddFloat(tlpoint,'TIMEPERCENT',ReadFloat(aptr));

        lint:=ReadByte(aptr);
        case lint of
          0: pcw:='Linear';
          1: pcw:='Linear Round';
          2: pcw:='Linear Round Down';
          3: pcw:='Linear Round Up';
          4: pcw:='No interpolation';
          5: pcw:='Quaternion';
          6: pcw:='Spline';
        else
          pcw:=Pointer(WideString(IntToStr(lint)));
        end;
        AddString(tlpoint,'INTERPOLATION',pcw);

        if fver=verTL2 then
        begin
          if ltltype=1 then
          begin
            pcw:=ReadShortString(aptr);
//writeln('point value ',string(widestring(pcw)));
            AddString(tlpoint,'VALUE',pcw);
            FreeMem(pcw);
          end;
        end;

        if fver=verHob then
        begin
          pcw:=ReadShortStringUTF8(aptr);
          if pcw<>nil then
          begin
            ltltype:=1;
            AddString(tlpoint,'VALUE_1',pcw);
            FreeMem(pcw);
          end;

          if (ltltype=0) or (ltltype=1) then
          begin
            pcw:=ReadShortStringUTF8(aptr);
            if pcw<>nil then
            begin
              ltltype:=1;
              AddString(tlpoint,'VALUE',pcw);
              FreeMem(pcw);
            end;
          end;
          if ltltype=2 then
          begin
          end;
        end;

      end;
    end;
  end;
end;

procedure ReadPropertyTL2(var anode:pointer; aobj:pointer; var aptr:pByte);
var
  lptr:pByte;
  pcw,lname:PWideChar;
  ltype,lsize:integer;
begin
  lsize:=ReadWord(aptr);
  if lsize=0 then exit;
  ltype:=ReadByte(aptr);
  lptr:=aptr;

  case GetObjectProperty(aobj,ltype,lname) of
    rgBool     : AddBool     (anode,lname,ReadInteger  (aptr)<>0);
    rgInteger  : AddInteger  (anode,lname,ReadInteger  (aptr));
    rgUnsigned : AddUnsigned (anode,lname,ReadDWord    (aptr));
    rgFloat    : AddFloat    (anode,lname,ReadFloat    (aptr));
    rgInteger64: AddInteger64(anode,lname,ReadInteger64(aptr));
    rgString: begin
	    pcw:=ReadShortString(aptr);
	    AddString(anode,lname,pcw);
	    FreeMem(pcw);
    end;
    rgVector2: begin
      AddFloat(anode,PWideChar(WideString(lname)+'X'),ReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Y'),ReadFloat(aptr));
    end;
    rgVector3: begin
      AddFloat(anode,PWideChar(WideString(lname)+'X'),ReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Y'),ReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Z'),ReadFloat(aptr));
    end;
    rgVector4: begin
      AddFloat(anode,PWideChar(WideString(lname)+'X1'),ReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Y1'),ReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'X2'),ReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Y2'),ReadFloat(aptr));
    end;
  else
    AddInteger(anode,'??UNKNOWN',lsize-4);
    AddString (anode,PWideChar('??'+WideString(lname)),
            PWideChar(WideString(HexStr(aptr-_filestart,8))));
if IsConsole then writeln(HexStr(lptr-_filestart,8),': prop type ',ltype,' size ',lsize);
  end;

  aptr:=lptr+lsize;
end;

procedure ReadPropertyHob(var anode:pointer; var aptr:pByte);
var
  pcw,lname:PWideChar;
  lptr:pByte;
  lsize,llen:integer;
  ldw:dword;
begin
  lsize:=ReadWord(aptr);
  if lsize=0 then exit;
//writeln('prop ',i+1,'/',lcnt,' size ',llsize,' at ',HexStr(aptr-_filestart,8));
  lptr:=aptr;

  lname:=GetStr(ReadDWord(aptr));

  //!!!! We don't have type info atm so trying to guess
  
  // standard: boolean, unsigned, integer, float
  if lsize=8 then
  begin
    ldw:=ReadDWord(aptr);
    //!! can be boolean - we can't get difference
    if ldw in [0,1] then
      AddInteger(anode,lname,integer(ldw))
    else if (ldw shr 24) in [0,$FF] then
      AddInteger(anode,lname,integer(ldw))
    else
    begin
      try
        AddFloat(anode,lname,psingle(@ldw)^);
      except
        AddInteger(anode,lname,integer(ldw));
      end;
    end;
  end
  else
  begin
    //!!
    if lsize<4 then
    begin
      AddInteger(anode,'??UNKNOWNSMALL',lsize);
      AddString (anode,'??UNKNADDR'    ,
          PWideChar(WideString(HexStr(aptr-_filestart,8))));
    end
    else
    begin
      llen:=ReadWord(aptr);
      dec(aptr,2);

      // text
      if llen=lsize-6 then
      begin
        pcw:=ReadShortStringUTF8(aptr);
        AddString(anode,lname,pcw);
        FreeMem(pcw);
      end

      // id OR Vector2
      else if lsize=12 then
      begin
        AddInteger64(anode,lname,ReadInteger64(aptr));
      end

      // Vector3
      else if lsize=16 then
      begin
        AddFloat(anode,PWideChar(WideString(lname)+'X'),ReadFloat(aptr));
        AddFloat(anode,PWideChar(WideString(lname)+'Y'),ReadFloat(aptr));
        AddFloat(anode,PWideChar(WideString(lname)+'Z'),ReadFloat(aptr));
      end

      // Vector4
      else if lsize=20 then
      begin
        AddFloat(anode,PWideChar(WideString(lname)+'X1'),ReadFloat(aptr));
        AddFloat(anode,PWideChar(WideString(lname)+'Y1'),ReadFloat(aptr));
        AddFloat(anode,PWideChar(WideString(lname)+'X2'),ReadFloat(aptr));
        AddFloat(anode,PWideChar(WideString(lname)+'Y2'),ReadFloat(aptr));
      end

      //!! unknown
      else
      begin
        AddInteger(anode,'??UNKNOWN',lsize-4);
        AddString (anode,PWideChar('??'+WideString(lname)),
            PWideChar(WideString(HexStr(aptr-_filestart,8))));
      end;
    end
  end;

  aptr:=lptr+lsize;
end;

//--- TL1
(*
procedure DoParseBlockTL1(var anode:PTL2Node; var aptr:pByte; const aparent:Int64);
var
  lChunkId:Int64;
  lparent:Int64;
  lptr:pByte;
  pcw:PWideChar;
begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');
  lptr:=aptr;
  
{
  //--- Chunk Header

  lChunkSize:=ReadInteger(aptr);
//  if lChunkSize=0 then exit;
  lChunkType:=ReadByte(aptr);
}
  lChunkId:=ReadInteger64(aptr);
  lparent :=ReadInteger64(aptr);

  //--- Chunk Info

{
  lname:=GetStr(lChunkHash);
  AddText(lnode,'DESCRIPTOR',lname,ntString);
}
  AddInteger64(lnode,'ID',lChunkId);
  pcw:=ReadDWordString(aptr);
  if pcw<>nil then
  begin
    AddText(lnode,'NAME',pcw,ntString);
    FreeMem(pcw);
  end
  else
    AddText(lnode,'NAME',lname,ntString);

  AddInteger64(lnode,'PARENTID',lparent);

  //--- Properties

  lcnt:=ReadDWord(aptr);
  for i:=0 to lcnt-1 do
    ReadDword(aptr);

  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  // ALL#0
  inc(aptr,8);
  ReadDWord(aptr); // 1
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);

  ReadDWord(aptr); // 5
  // CLASS:DESTROYER#0
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 1
  ReadDWord(aptr); // children offset
  ReadDWord(aptr); // next "children" (other object) offset

  ReadDWord(aptr); // 0 = tag Group?
{
  lcnt:=ReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyTL1(lnode,lobj,aptr);
  end;
}
  //--- Additional data

  //--- Children


  lcnt:=ReadWord(aptr);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      DoParseBlockTL2(lnode,aptr,lChunkId);
    end;
  end;

  aptr:=lptr+lChunkSize;
end;
*)
//--- TL2

procedure DoParseBlockTL2(var anode:pointer; var aptr:pByte; const aparent:Int64);
var
  bnode,lobj,lnode:pointer;
  lptr:pbyte;
  pname,pcw:PWideChar;

  lChunkSize:integer;
  lChunkType:byte;
  lChunkId  :Int64;

  lsize,i,lcnt:integer;

begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');
  lptr:=aptr;

  //--- Chunk Header

  lChunkSize:=ReadInteger(aptr);
//  if lChunkSize=0 then exit;
  lChunkType:=ReadByte(aptr);
  lChunkId  :=ReadInteger64(aptr);

  //--- Chunk Info

  lobj:=SelectObject(objInfo,lChunkType);
  pname:=GetObjectName(lobj);

  AddString(lnode,'DESCRIPTOR',pname);
  pcw:=ReadShortString(aptr);
  if pcw<>nil then
  begin
    AddString(lnode,'NAME',pcw);
    FreeMem(pcw);
  end
  else
    AddString(lnode,'NAME',pname);
  AddInteger64(lnode,'PARENTID',aparent);
  AddInteger64(lnode,'ID',lChunkId);

  //--- Properties

  lcnt:=ReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyTL2(lnode,lobj,aptr);
  end;

  //--- Additional data

  lsize:=ReadInteger(aptr);
  if lsize>0 then
  begin

    //----- Timeline -----

    if lChunkType=IdTimeline then
    begin
      ParseTimeline(lnode,lChunkId,aptr);
    end

    //----- Logic group -----

    else if lChunkType = idLogicGroup then
    begin
      ParseLogicGroup(lnode,aptr);
    end;

  end;

  //--- Children

  lcnt:=ReadWord(aptr);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      DoParseBlockTL2(lnode,aptr,lChunkId);
    end;
  end;

  aptr:=lptr+lChunkSize;
end;

//--- Hob

procedure DoParseBlockHob(var anode:pointer; var aptr:pByte; const aparent:Int64);
var
  bnode,lnode:pointer;
//  laptr:pByte;
  llptr,lptr:pByte;
  lname,pcw:PWideChar;

  lChunkSize:integer;
  lChunkHash:dword;
  lChunkId  :Int64;

  i,lsize,lcnt:integer;

begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');

  lptr:=aptr;

  //--- Chunk Header

  lChunkSize:=ReadDWord(aptr);
  if lChunkSize=0 then exit;

  lChunkHash:=ReadDWord(aptr);
  lChunkId  :=ReadInteger64(aptr);

  //--- Chunk Info

  lname:=GetStr(lChunkHash);
  AddString(lnode,'DESCRIPTOR',lname);
  AddInteger64(lnode,'ID',lChunkId);
  pcw:=ReadShortStringUTF8(aptr);
  if pcw<>nil then
  begin
    AddString(lnode,'NAME',pcw);
    FreeMem(pcw);
  end
  else
    AddString(lnode,'NAME',lname);

  AddInteger64(lnode,'PARENTID',aparent);

  //--- Properties

  lcnt:=ReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyHob(lnode,aptr);
  end;

  //--- Additional data

  lsize:=ReadInteger(aptr);
  llptr:=aptr;
  if lsize>0 then
  begin

    //----- Logic group -----

    if lChunkHash=2261606130 then
    begin
      ParseLogicGroup(lnode,aptr);
    end

    //----- Timeline -----

    else if lChunkHash=2623981599 then
    begin
      ParseTimeline(lnode,lChunkId,aptr);
    end

    //----- Unknown additional data -----

    else
    begin
    //!!
      AddString(lnode,'??ADDITIONALDATA',
          PWideChar(WideString(HexStr(aptr-_filestart,8))));
      AddInteger(lnode,'??ADDITIONALSIZE',lsize);
    end;

    aptr:=llptr+lsize;
  end;

  //--- Children

  lcnt:=ReadWord(aptr);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      DoParseBlockHob(lnode,aptr,lChunkId);
    end;
  end;

  aptr:=lptr+lChunkSize;
end;

function DoParseLayout(buf:pByte):pointer;
var
  pcw:PWideChar;
  ls:string;
  lobj,lc:pointer;
  lptr:pByte;
  ldata,i,lcnt,llayver:integer;
  b1,b2,b3:boolean;
begin
  result:=nil;

  _filestart:=buf;
  lptr:=buf;

  fver:=ReadByte(lptr);
  if fver=$5A then
  begin
    inc(lptr,7);
  end;

  case fver of
    8  : fver:=verHob;
    11 : fver:=verTL2;
    $5A: fver:=verTL1;
  end;

  if objInfo=pointer(-1) then
    objInfo:=LoadObjectInfo();

  //--- TL1 ---

  if fver=verTL1 then
  begin
{
    result:=AddGroup(nil,'Layout');

    //??
    lcnt:=ReadDWord(lptr);
    if lcnt=0 then lcnt:=ReadDWord(lptr);

    AddUnsigned(result,'COUNT',lcnt);
    ReadDWord(lptr);                     // offset

    lobj:=AddGroup(result,'OBJECTS');
    for i:=0 to lcnt-1 do
      DoParseBlockTL1(lobj,lptr,-1);
}
  end;

  //--- TL2 ---

  if fver=verTL2 then
  begin
    ls:=UpCase(curfname);
    if      pos('MEDIA\UI'       ,ls)>0 then pcw:='UI'
    else if pos('MEDIA\Particles',ls)>0 then pcw:='Particle Creator'
    else pcw:='Layout';
    
    result:=AddGroup(nil,pcw);
    llayver:=ReadByte(lptr);             // Layout version
    AddInteger(result,'VERSION',llayver);

    objcount:=0;
    lc:=AddUnsigned(result,'COUNT',0);
    ReadDWord(lptr);                     // offset

    lobj:=AddGroup(result,'OBJECTS');
    lcnt:=ReadWord (lptr);               // root baseobject count
    for i:=0 to lcnt-1 do
      DoParseBlockTL2(lobj,lptr,-1);

//    lc:=AddUnsigned(result,'COUNT',objcount);
    asUnsigned(lc,objcount);
  end;

  //--- Hob ---

  if fver=verHob then
  begin
    inc(lptr);

    result:=AddGroup(nil,'Layout');
    lcnt:=ReadDWord(lptr);
    AddUnsigned(result,'COUNT',lcnt);
    ReadDword(lptr);                // offset

    ReadByte(lptr);                 // 1
    pcw:=ReadShortStringUTF8(lptr); // LEVEL
    AddString(result,'TYPE',pcw);
    FreeMem(pcw);
    inc(lptr);                      // 0
    inc(lptr);                      // 4
    ldata:=ReadDWord(lptr);         // absolute offset to data
    pcw:=ReadShortString(lptr);
    if pcw<>nil then
    begin
      AddString(result,'BASE',pcw);
      FreeMem(pcw);
    end;
    inc(lptr,6*SizeOf(single));   // 6*4
    b1:=ReadByte(lptr)<>0;          // 1 usually
    b2:=ReadByte(lptr)<>0;          // 0 usually but can be a 1
    b3:=ReadByte(lptr)<>0;          // 0 usually

    if b2 then
    begin
      pcw:=ReadShortStringUTF8(lptr);
      AddString(result,'LAYOUT_TITLE',pcw);
      FreeMem(pcw);
      AddInteger64(result,'LAYOUT_ID',ReadInteger64(lptr));
    end;

    lptr:=_filestart+ldata;

    lobj:=AddGroup(result,'OBJECTS');
    lcnt:=ReadWord (lptr);
    for i:=0 to lcnt-1 do
      DoParseBlockHob(lobj,lptr,-1);
  end;
end;

function IsProperLayout(buf:pByte):boolean;
begin
  result:=buf^ in [5, 8, 11, $5A];
end;

initialization

  aliases:=pointer(-1);
  dict   :=pointer(-1);
  cdict  :=pointer(-1);
  tdict  :=pointer(-1);
  objInfo:=pointer(-1);

finalization
  
  if aliases<>pointer(-1) then FreeTags(aliases);
  if dict   <>pointer(-1) then FreeTags(dict);
  if cdict  <>pointer(-1) then FreeTags(cdict);
  if tdict  <>pointer(-1) then FreeTags(tdict);
  if objInfo<>pointer(-1) then FreeObjectInfo(objInfo);

end.
