{}

const
  IdLogicGroupTL2 = 36;
  IdTimelineTL2   = 35;

procedure TRGLayoutFile.ReadPropertyTL2(var anode:pointer);
var
  lptr:pByte;
  ltype,lsize:integer;
begin
  lsize:=memReadWord(FPos);
  if lsize=0 then exit;

  lptr:=FPos;
  ltype:=memReadByte(FPos);

  ReadPropertyValue(ltype,lsize-1, anode);

  FPos:=lptr+lsize;
end;

function TRGLayoutFile.DoParseBlockTL2(var anode:pointer; const aparent:Int64):integer;
var
  lbuf:WideString;
  //  lbuf:array [0..31] of WideChar;
  bnode,lnode:pointer;
  llptr,lptr:pbyte;
  lname,pcw:PWideChar;

  lChunkSize:integer;
  lChunkType:byte;
  lChunkId  :Int64;

  lsize,i,lcnt:integer;

begin
  result:=1;

  bnode:=AddGroup(anode,'BASEOBJECT');
  lnode:=AddGroup(bnode,'PROPERTIES');
  lptr:=FPos;

  //--- Chunk Header

  lChunkSize:=memReadInteger(FPos);
//  if lChunkSize=0 then exit;
  lChunkType:=memReadByte(FPos);
  lChunkId  :=memReadInteger64(FPos);

  //--- Chunk Info

  lname:=info.GetObjectName(lChunkType);
  if lname=nil then
  begin
    Str(lChunkType,lbuf);
    lname:=PWideChar(lbuf);
  end;

  AddString(lnode,'DESCRIPTOR',lname);
  pcw:=memReadShortString(FPos);
  if pcw<>nil then
  begin
    AddString(lnode,'NAME',pcw);
    FreeMem(pcw);
  end
  else
    AddString(lnode,'NAME',lname);
  AddInteger64(lnode,'PARENTID',aparent);
  AddInteger64(lnode,'ID'      ,lChunkId);

  //--- Properties

  lcnt:=memReadByte(FPos);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyTL2(lnode);
  end;

  //--- Additional data

  lsize:=memReadInteger(FPos);
  llptr:=FPos;
  if lsize>0 then
  begin

    //----- Timeline -----

    if lChunkType=IdTimelineTL2 then
    begin
      ParseTimeline(lnode,lChunkId);
    end

    //----- Logic group -----

    else if lChunkType = IdLogicGroupTL2 then
    begin
      ParseLogicGroup(lnode);
    end

    else
    begin
      RGLog.Add('Unknown chunk with size '+IntToStr(lsize)+' at '+HexStr(FPos-FStart,8));
    //!!
      AddString (lnode,'??ADDITIONALDATA',PWideChar(WideString(HexStr(FPos-FStart,8))));
      AddInteger(lnode,'??ADDITIONALSIZE',lsize);
    end;

    FPos:=llptr+lsize;
  end;

  //--- Children

  lcnt:=memReadWord(FPos);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      inc(result,DoParseBlockTL2(lnode,lChunkId));
    end;
  end;

  FPos:=lptr+lChunkSize;
end;

function TRGLayoutFile.DoParseLayoutTL2(atype:cardinal):pointer;
var
  lobj,lc:pointer;
  pcw:PWideChar;
  i,lcnt,lver,lobjcnt:integer;
  ltmp:dword;
begin
  info.Version:=verTL2;

  inc(FPos);
  
  pcw:=ltName[atype];

  result:=AddGroup(nil,pcw);
  info.SelectScene(pcw);

  lver:=memReadByte(FPos);               // Layout version
  AddInteger(result,'VERSION',lver);
  if lver<>4 then
    RGLog.Add('Layout version is not 4 but '+HexStr(lver,2));

  lc:=AddUnsigned(result,'COUNT',0);
  ltmp:=memReadDWord(FPos);              // offset
  if ltmp<>0 then
    RGLog.Add('Binary chunk at '+HexStr(ltmp,8));

  lcnt:=memReadWord(FPos);               // root baseobject count

  lobjcnt:=0;
  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    inc(lobjcnt,DoParseBlockTL2(lobj,-1));

  asUnsigned(lc,lobjcnt);
end;

function TRGLayoutFile.DoWriteBlockTL2(anode:pointer; astream:TStream):integer;
var
  lobj,lprops:pointer;
  {lparent,}ldescr,lname,lid:pointer;
  lpdescr,lpname:PWideChar;
  lcnt,i:integer;
  lpos,lPropPos,lAddPos:integer;
  lChunkType:byte;
begin
  result:=0;

  lprops:=GetChild(anode,0); // PROPERTIES

  //--- Chunk Header

  lpos:=astream.Position;
  astream.WriteDWord(0); // ChunkSize

  ldescr:=FindNode(lprops,'DESCRIPTOR');
  lpdescr:=AsString(ldescr);
  i:=info.GetObjectId(lpdescr);

  if i=-1 then exit;

  lChunkType:=i;
  astream.WriteByte(lChunkType);
  // select object

//  lparent:=FindNode(lprops,'PARENTID');

  lid:=FindNode(lprops,'ID');
//  lChunkId  :=AsInteger64(FPos);
  astream.WriteQWord(QWord(AsInteger64(lid)));

  //--- Chunk Info

  lname:=FindNode(lprops,'NAME');
  lpname:=AsString(lname);
  if CompareWide(lpdescr,lpname)=0 then
    astream.WriteShortString('')
  else
    astream.WriteShortString(lpname);

  //--- Properties

  lPropPos:=astream.Position;
  astream.WriteByte(0);

  lcnt:=WritePropertyValue(lprops,astream);

  lAddPos:=astream.Position;
  astream.Position:=lPropPos;
  astream.WriteByte(lcnt);
  astream.Position:=lAddPos;

  //--- Additional Data

  if (lChunkType=idTimelineTL2) or
     (lChunkType=idLogicGroupTL2) then
  begin
    astream.WriteDWord(0);

    if lChunkType=idTimelineTL2 then
    begin
      BuildTimeline(FindNode(lprops,'TIMELINEDATA'), astream);
    end
    else //if lChunkType=idLogicGroupTL2 then
    begin
      BuildLogicGroup(FindNode(lprops,'LOGICGROUP'), astream);
    end;

    lcnt:=astream.Position-lAddPos;
    astream.Position:=lAddPos;
    astream.WriteDWord(lcnt-SizeOf(dword));
    astream.Position:=lAddPos+lcnt;
  end
  else
    astream.WriteDWord(0);

  //--- Children

  lobj:=FindNode(anode,'CHILDREN');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);
  astream.WriteWord(lcnt);

  for i:=0 to lcnt-1 do
    DoWriteBlockTL2(GetChild(lobj,i),astream); // BASEOBJECT

  //--- Chunk size

  lcnt:=astream.Position-lpos;
  astream.Position:=lpos;
  astream.WriteDWord(lcnt);
  astream.Position:=lpos+lcnt;
end;

function TRGLayoutFile.DoBuildLayoutTL2(anode:pointer; astream:TStream):integer;
var
  lobj:pointer;
  i,lcnt:integer;
begin
  result:=astream.Position;
  info.Version:=verTL2;
  info.SelectScene('');

  astream.WriteByte (11); // sign
  astream.WriteByte ( 4); // 'version'  <INTEGER>VERSION:54
  astream.WriteDWord( 0); // binary offset

  lobj:=FindNode(anode,'OBJECTS');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);
  astream.WriteWord(lcnt); // root baseobject count <UNSIGNED INT>COUNT:322

  for i:=0 to lcnt-1 do
    DoWriteBlockTL2(GetChild(lobj,i),astream); // BASEOBJECT

  result:=astream.Position-result;
end;
