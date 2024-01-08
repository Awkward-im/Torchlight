{}

const
  IdGroupHob      = 4270653419;
  IdLogicGroupHob = 2261606130;
  IdTimelineHob   = 2623981599;

procedure LogProperty(aname:PWideChar; aid:dword; atype:integer);
begin
  RGLog.Add('<STRING>NAME:'+UTF8Encode(WideString(aname)));
  RGLog.Add('<UNSIGNED INT>ID:'+IntToStr(aid));
  RGLog.Add('<STRING>TYPEOFDATA:'+string(TypeToText(atype)));
end;

procedure TRGLayoutFile.ReadBinaryDataHob(var anode:pointer);
var
  ldata:TLayoutBinHob;
  lls,ls:WideString;
  p:PWideChar;
  i,lthemes:integer;
begin
  // check current group ID. or offset? if the same, process
  // if not: 1 - check position (before/after)
  // 2 - check from start of data
  memReadData(FBinPos,ldata,SizeOf(ldata));
  if ldata.choice<>0 then
  begin
    if FindNode(anode,'CHOICE')=nil then
    begin
      if ldata.choice<=Length(strChoice) then
        AddString(anode,'CHOICE',strChoice[ldata.choice]);
{
      if      ldata.choice=1 then AddString(anode,'CHOICE','Weight')
      else if ldata.choice=2 then AddString(anode,'CHOICE','Random Chance');
}
    end;
  end;

if ldata.unk1<>0 then
begin
  AddUnsigned(anode,'unk1',ldata.unk1);
end;
if ldata.unk3<>0 then
begin
  AddUnsigned(anode,'unk1',ldata.unk2);
end;
if ldata.unk2<>0 then
begin
  AddUnsigned(anode,'unk1',ldata.unk3);
end;
if (ldata.unk[0]<>0) or (ldata.unk[1]<>0) or (ldata.unk[2]<>0) or (ldata.unk[3]<>0) or
   (ldata.unk[4]<>0) or (ldata.unk[5]<>0) or (ldata.unk[6]<>0) or (ldata.unk[7]<>0) or
   (ldata.unk[8]<>0) or (ldata.unk[9]<>0) or (ldata.unk[10]<>0) or (ldata.unk[11]<>0) or
   (ldata.unk[12]<>0) or (ldata.unk[13]<>0) or (ldata.unk[14]<>0) then
begin
  AddString(anode,'!!Unknown','not zero');
end;
(*
  if ldata.gamemode<>0 then
  begin
    if FindNode(anode,'GAME MODE')=nil then
    begin
      if ldata.gamemode<=Length(strGameMode) then
        AddString(anode,'GAME MODE',strGameMode[ldata.gamemode]);
{
      if      ldata.gamemode=1 then AddString(anode,'GAME MODE','NORMAL')
      else if ldata.gamemode=2 then AddString(anode,'GAME MODE','GAME MODE PLUS');
}
    end;
  end;
  if ldata.unique<>0 then
  begin
    if FindNode(anode,'LEVEL UNIQUE')=nil then
    begin
      AddBool(anode,'LEVEL UNIQUE',true)
    end;
  end;
  if ldata.notag <>0 then AddBool    (anode,'NO TAG FOUND' ,true);
*)
  if ldata.number<>1 then AddUnsigned(anode,'NUMBER'       ,ldata.number);
  if ldata.random<>1 then AddUnsigned(anode,'RANDOMIZATION',ldata.random);
  if ldata.idk1  <>0 then AddUnsigned(anode,'UNKNOWN'      ,ldata.idk1);
  if ldata.tag>=0 then
  begin
{
    p:=GetTagTL2(ldata.tag);
    if p<>nil then
      AddString(anode,'TAG',p)
    else
}
    begin
      Str(ldata.tag,lls);
      AddString(anode,'TAG',PWideChar(lls));
    end;
  end;

{
  lthemes:=memReadInteger(FBinPos);
  if lthemes>0 then
  begin
    ls:='';
    for i:=0 to lthemes-1 do
    begin
      if i>0 then ls:=ls+',';
      Str(memReadInteger64(FBinPos),lls);
      ls:=ls+lls;
    end;
    AddString(anode,'ACTIVE THEMES',PWideChar(ls));
  end;
  lthemes:=memReadInteger(FBinPos);
  if lthemes>0 then
  begin
    ls:='';
    for i:=0 to lthemes-1 do
    begin
      if i>0 then ls:=ls+',';
      Str(memReadInteger64(FBinPos),lls);
      ls:=ls+lls;
    end;
    AddString(anode,'DEACTIVE THEMES',PWideChar(ls));
  end;
}
  memReadWord(FBinPos); // child
end;

procedure TRGLayoutFile.ReadBinaryDataRG(var anode:pointer);
var
  ldata:TLayoutBinRG;
  lls,ls:WideString;
  p:PWideChar;
  i,lthemes:integer;
begin
  // check current group ID. or offset? if the same, process
  // if not: 1 - check position (before/after)
  // 2 - check from start of data
  memReadData(FBinPos,ldata,SizeOf(ldata));

  if FVer=verRGO then
  begin
    lthemes:=memReadByte(FBinPos);
    if lthemes<>0 then
      AddUnsigned(anode,'UN_1',lthemes);
    lthemes:=memReadByte(FBinPos);
    if lthemes<>0 then
      AddUnsigned(anode,'UN_2',lthemes);
    lthemes:=memReadByte(FBinPos);
    if lthemes<>0 then
      AddUnsigned(anode,'UN_3',lthemes);
    lthemes:=memReadByte(FBinPos);
    if lthemes<>0 then
      AddUnsigned(anode,'UN_4',lthemes);
    lthemes:=memReadByte(FBinPos);
    if lthemes<>0 then
      AddUnsigned(anode,'UN_5',lthemes);
    lthemes:=memReadByte(FBinPos);
    if lthemes<>0 then
      AddUnsigned(anode,'UN_6',lthemes);
    //    inc(FBinPos,6); //!!!!
  end;

  if ldata.choice<>0 then
  begin
    if FindNode(anode,'CHOICE')=nil then
    begin
      if ldata.choice<=Length(strChoice) then
        AddString(anode,'CHOICE',strChoice[ldata.choice]);
{
      if      ldata.choice=1 then AddString(anode,'CHOICE','Weight')
      else if ldata.choice=2 then AddString(anode,'CHOICE','Random Chance');
}
    end;
  end;
  if ldata.gamemode<>0 then
  begin
    if FindNode(anode,'GAME MODE')=nil then
    begin
      if ldata.gamemode<=Length(strGameMode) then
        AddString(anode,'GAME MODE',strGameMode[ldata.gamemode]);
{
      if      ldata.gamemode=1 then AddString(anode,'GAME MODE','NORMAL')
      else if ldata.gamemode=2 then AddString(anode,'GAME MODE','GAME MODE PLUS');
}
    end;
  end;
  if ldata.unique<>0 then
  begin
    if FindNode(anode,'LEVEL UNIQUE')=nil then
    begin
      AddBool(anode,'LEVEL UNIQUE',true)
    end;
  end;
  if ldata.notag <>0 then AddBool    (anode,'NO TAG FOUND' ,true);
  if ldata.number<>1 then AddUnsigned(anode,'NUMBER'       ,ldata.number);
  if ldata.random<>1 then AddUnsigned(anode,'RANDOMIZATION',ldata.random);
  if ldata.unk   <>0 then AddUnsigned(anode,'UNKNOWN'      ,ldata.unk);
  if ldata.tag>=0 then
  begin
{
    p:=GetTagTL2(ldata.tag);
    if p<>nil then
      AddString(anode,'TAG',p)
    else
}
    begin
      Str(ldata.tag,lls);
      AddString(anode,'TAG',PWideChar(lls));
    end;
  end;

{
  lthemes:=memReadInteger(FBinPos);
  if lthemes>0 then
  begin
    ls:='';
    for i:=0 to lthemes-1 do
    begin
      if i>0 then ls:=ls+',';
      Str(memReadInteger64(FBinPos),lls);
      ls:=ls+lls;
    end;
    AddString(anode,'ACTIVE THEMES',PWideChar(ls));
  end;
  lthemes:=memReadInteger(FBinPos);
  if lthemes>0 then
  begin
    ls:='';
    for i:=0 to lthemes-1 do
    begin
      if i>0 then ls:=ls+',';
      Str(memReadInteger64(FBinPos),lls);
      ls:=ls+lls;
    end;
    AddString(anode,'DEACTIVE THEMES',PWideChar(ls));
  end;
}
  memReadWord(FBinPos); // child
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

  lptr:=FPos;

  //--- Chunk Header

  lChunkSize:=memReadDWord(FPos);
  if lChunkSize=0 then exit;

  bnode:=AddGroup(anode,'BASEOBJECT');
  lnode:=AddGroup(bnode,'PROPERTIES');

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

  //--- Place for binary group data translation

  if lChunkType=IdGroupHob then
  begin
    if FVer=verHob then
      ReadBinaryDataHob(lnode)
    else
      ReadBinaryDataRG(lnode);
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
  FBinStart:=FStart+ltmp;
  if ltmp<>0 then
  begin
    FBinPos:=FBinStart+SizeOf(TLayoutBinHob)+2;
    RGLog.Add('Binary chunk at '+HexStr(ltmp,8));
  end;

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
  ltmp:dword;
begin
  info.Version:=verRG;

  inc(FPos);
  i:=memReadByte(FPos);
  if i<>0 then
    RGLog.Add('Second byte is not 0 but '+HexStr(i,2));

  ltmp:=memReadDword(FPos);                // offset
  FBinStart:=FStart+ltmp;
  if ltmp<>0 then
  begin
    FBinPos:=FBinStart+SizeOf(TLayoutBinRG)+2;
    if FVer=verRGO then
      inc(FBinPos,6);                //!!!!!

    RGLog.Add('Binary chunk at '+HexStr(ltmp,8));
  end;

  ltmp:=memReadByte(FPos);                 // 1
  if ltmp<>1 then
    RGLog.Add('Byte after binary offset is not 1 but '+IntToStr(ltmp));

  result:=AddGroup(nil,'Layout');
  info.SelectScene('Layout');

  lcnt:=memReadWord(FPos);
  AddUnsigned(result,'COUNT',lcnt);

  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    DoParseBlockHob(lobj,-1);
end;

function TRGLayoutFile.DoBuildLayoutHob(anode:pointer; astream:TStream):integer;
begin
  result:=0;
end;

function TRGLayoutFile.DoBuildLayoutRG(anode:pointer; astream:TStream):integer;
begin
  result:=0;
end;
