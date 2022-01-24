{}

const
  IdLogicGroupHob = 2261606130;
  IdTimelineHob   = 2623981599;

procedure LogProperty(aname:PWideChar; aid:dword; atype:integer);
begin
  RGLog.Add('<STRING>NAME:'+UTF8Encode(WideString(aname)));
  RGLog.Add('<UNSIGNED INT>ID:'+IntToStr(aid));
  RGLog.Add('<STRING>TYPEOFDATA:'+string(TypeToText(atype)));
end;

procedure TRGLayoutFile.ReadPropertyHob(var anode:pointer);
var
  lptr:pByte;
  lhash:dword;
  lsize:integer;
begin
  lsize:=memReadWord(FPos);
  if lsize=0 then exit;

  lptr:=FPos;
  lhash:=memReadDWord(FPos);

  ReadPropertyValue(lhash,lsize-4, anode);

  FPos:=lptr+lsize;
end;

function TRGLayoutFile.DoParseBlockHob(var anode:pointer; const aparent:Int64):integer;
var
  lChunkId  :Int64;
  bnode,lnode:pointer;

  llptr,lptr:pByte;
  lname,pcw:PWideChar;

  lChunkSize:integer;
  lChunkType:dword;

  i,lsize,lcnt:integer;
begin
  result:=1;

  bnode:=AddGroup(anode,'BASEOBJECT');
  lnode:=AddGroup(bnode,'PROPERTIES');

  lptr:=FPos;

  //--- Chunk Header

  lChunkSize:=memReadDWord(FPos);
  if lChunkSize=0 then exit;

  lChunkType:=memReadDWord(FPos);
  lChunkId  :=memReadInteger64(FPos);

  //--- Chunk Info

  lname:=info.GetObjectName(lChunkType);
  if lname=nil then
    lname:=GetStr(lChunkType);

  AddString(lnode,'DESCRIPTOR',lname);
  AddInteger64(lnode,'ID',lChunkId);

  pcw:=memReadShortStringUTF8(FPos);
  if pcw<>nil then
  begin
    AddString(lnode,'NAME',pcw);
    FreeMem(pcw);
  end
  else
    AddString(lnode,'NAME',lname);

  AddInteger64(lnode,'PARENTID',aparent);

  //--- Properties

  RGLog.Reserve('Object '+UTF8Encode(WideString(lname)));

  lcnt:=memReadByte(FPos);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyHob(lnode);
  end;

  //--- Additional data

  lsize:=memReadInteger(FPos);
  llptr:=FPos;
  if lsize>0 then
  begin

    //----- Logic group -----

    if lChunkType=IdLogicGroupHob then
    begin
      ParseLogicGroup(lnode);
    end

    //----- Timeline -----

    else if lChunkType=IdTimelineHob then
    begin
try
      ParseTimeline(lnode,lChunkId);
except
end;
    end

    //----- Unknown additional data -----

    else
    begin
      RGLog.Add('Unknown chunk with size '+IntToStr(lsize)+' at '+HexStr(FPos-FStart,8));
    //!!
      AddString (lnode,'??ADDITIONALDATA', PWideChar(WideString(HexStr(FPos-FStart,8))));
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
      inc(result,DoParseBlockHob(lnode,lChunkId));
    end;
  end;

  FPos:=lptr+lChunkSize;

  RGLog.Reserve('');
end;

function TRGLayoutFile.DoParseLayoutHob(atype:cardinal):pointer;
var
  lobj:pointer;
  pcw:PWideChar;
  ldata,i,lcnt:integer;
  ltmp:dword;
  b1,b2,b3:boolean;
begin
  info.Version:=verHob;
  
  inc(FPos);

  ltmp:=memReadByte(FPos);
  if ltmp<>0 then
    RGLog.Add('Second byte is not 0 but '+HexStr(ltmp,2));

  result:=AddGroup(nil,ltName[ltLayout]);
  info.SelectScene(ltName[ltLayout]);

  lcnt:=memReadDWord(FPos);
  AddUnsigned(result,'COUNT',lcnt);

  ltmp:=memReadDword(FPos);                // offset
  if ltmp<>0 then
    RGLog.Add('Binary chunk at '+HexStr(ltmp,8));

  ltmp:=memReadByte(FPos);                 // 1
  if ltmp<>1 then
    RGLog.Add('Byte after binary offset is not 1 but '+IntToStr(ltmp));

  pcw:=memReadShortStringUTF8(FPos);       // LEVEL
  AddString(result,'TYPE',pcw);
  if CompareWide(pcw,'LEVEL')<>0 then
    RGLog.Add('Type is not LEVEL but '+string(pcw));
  FreeMem(pcw);

  ltmp:=memReadByte(FPos);                 // 0
  if ltmp<>0 then
    RGLog.Add('Byte after type is not 0 but '+IntToStr(ltmp));
  ltmp:=memReadByte(FPos);                 // 4
  if ltmp<>4 then
    RGLog.Add('Byte before main data offset is not 4 but '+IntToStr(ltmp));

  ldata:=memReadDWord(FPos);               // absolute offset to data
  pcw:=memReadShortString(FPos);
  if pcw<>nil then
  begin
    AddString(result,'BASE',pcw);
    FreeMem(pcw);
  end;

  // 2 vector3 or 3 vector2
  AddFloat(result,'X1',memReadFloat(FPos));
  AddFloat(result,'Y1',memReadFloat(FPos));
  AddFloat(result,'Z1',memReadFloat(FPos));
  AddFloat(result,'X2',memReadFloat(FPos));
  AddFloat(result,'Y2',memReadFloat(FPos));
  AddFloat(result,'Z2',memReadFloat(FPos));
  
  ltmp:=memReadByte(FPos);                 // 1 usually
  b1:=ltmp<>0;
  if ltmp<>1 then
    RGLog.Add('Byte (1 of 3) is not 1 but '+IntToStr(ltmp));
  ltmp:=memReadByte(FPos);                 // 0 usually but can be a 1
  b2:=ltmp<>0;
  if (ltmp<>0) and (ltmp<>1) then          // is it posible?!
    RGLog.Add('Byte (2 of 3) is not 0 or 1 but '+IntToStr(ltmp));
  ltmp:=memReadByte(FPos);                 // 0 usually
  b3:=ltmp<>0;
  if ltmp<>0 then
    RGLog.Add('Byte (3 of 3) is not 0 but '+IntToStr(ltmp));

  if b2 then
  begin
    pcw:=memReadShortStringUTF8(FPos);
    AddString(result,'LAYOUT_TITLE',pcw);
    FreeMem(pcw);
    AddInteger64(result,'LAYOUT_ID',memReadInteger64(FPos));
  end;

  FPos:=FStart+ldata;

  lcnt:=memReadWord(FPos);

  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    DoParseBlockHob(lobj,-1);
end;

function TRGLayoutFile.DoParseLayoutRG(atype:cardinal):pointer;
var
  lobj:pointer;
  i,lcnt:integer;
begin
  info.Version:=verRG;

  inc(FPos);
  i:=memReadByte(FPos);
  if i<>0 then
    RGLog.Add('Second byte is not 0 but '+HexStr(i,2));

  memReadDWord(FPos);
  inc(FPos); //??
  result:=AddGroup(nil,'Layout');
  info.SelectScene('Layout');

  lcnt:=memReadWord(FPos);
  AddUnsigned(result,'COUNT',lcnt);

  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    DoParseBlockHob(lobj,-1);
end;
