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
