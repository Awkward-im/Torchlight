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
  ldata:TLayoutBinRGO;
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
    p:=memReadShortStringUTF8(FBinPos);
    if p<>nil then
    begin
      if FindNode(anode,'GAMEFLAGREQUIREMENT')=nil then
        AddString(anode,'GAMEFLAGREQUIREMENT',p);
      FreeMem(p);
    end;

    p:=memReadShortStringUTF8(FBinPos);
    if p<>nil then
    begin
      if FindNode(anode,'SCENEFLAGREQUIREMENT')=nil then
        AddString(anode,'SCENEFLAGREQUIREMENT',p);
      FreeMem(p);
    end;

    p:=memReadShortStringUTF8(FBinPos);
    if p<>nil then
    begin
      if FindNode(anode,'WORLDTAGREQUIREMENT')=nil then
        AddString(anode,'WORLDTAGREQUIREMENT',p);
      FreeMem(p);
    end
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
      RGLog.Add('"UNIQUE" value presents');
      AddBool(anode,'LEVEL UNIQUE',true)
    end;
  end;
  if ldata.number<>1 then
  begin
    if FindNode(anode,'NUMBER')=nil then
    begin
      AddUnsigned(anode,'NUMBER',ldata.number); // lower byte only
    end;
  end;
  if ldata.random<>1 then
  begin
    if FindNode(anode,'RANDOMIZATION')=nil then
      AddUnsigned(anode,'RANDOMIZATION',ldata.random);
  end;
  if ldata.noflag<>0 then
  begin
    if FindNode(anode,'CREATEWITHNOFLAG')=nil then
      AddBool(anode,'CREATEWITHNOFLAG' ,true);
  end;
  if ldata.noprop<>0 then
  begin
    if FindNode(anode,'DONTPROPAGATE')=nil then
      AddBool(anode,'DONTPROPAGATE' ,true);
  end;
  if ldata.tag>=0 then
  begin
{
    p:=GetTagTL2(ldata.tag);
    if p<>nil then
      AddString(anode,'TAG',p)
    else
}
    begin
      RGLog.Add('"TAG" value presents');
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

//  RGLog.Reserve('');
end;

function TRGLayoutFile.DoParseLayoutHob(atype:cardinal):pointer;
var
  lobj,lsub:pointer;
  pcw:PWideChar;
  ldata,i,lcnt:integer;
  ltmp:dword;
  b1,b2,b3:boolean;
begin
  info.Version:=verHob;
  
  inc(FPos);

  ltmp:=memReadByte(FPos);
  if (ltmp<>0) and (RGDebugLevel=dlDetailed) then
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
    if (RGDebugLevel=dlDetailed) then
      RGLog.Add('Binary chunk at '+HexStr(ltmp,8));
  end;

  ltmp:=memReadByte(FPos);                 // 1
  if (ltmp<>1) and (RGDebugLevel=dlDetailed) then
    RGLog.Add('Byte after binary offset is not 1 but '+IntToStr(ltmp));

  pcw:=memReadShortStringUTF8(FPos);       // LEVEL
  AddString(result,'TYPE',pcw);
  if CompareWide(pcw,'LEVEL')<>0 then
    RGLog.Add('Type is not LEVEL but '+string(pcw));
  FreeMem(pcw);

  ltmp:=memReadByte(FPos);                 // 0
  if (ltmp<>0) and (RGDebugLevel=dlDetailed) then
    RGLog.Add('Byte after type is not 0 but '+IntToStr(ltmp));
  ltmp:=memReadByte(FPos);                 // 4
  if (ltmp<>4) and (RGDebugLevel=dlDetailed) then
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
  if (ltmp<>1) and (RGDebugLevel=dlDetailed) then
    RGLog.Add('Byte (1 of 3) is not 1 but '+IntToStr(ltmp));

  // Warp points
  lcnt:=memReadWord(FPos);
  if lcnt>0 then
  begin
    lobj:=AddGroup(result,'WARPPOINTS');
    for i:=0 to lcnt-1 do
    begin
      lsub:=AddGroup(lobj,'WARP');
      pcw:=memReadShortStringUTF8(FPos);
      AddString(lsub,'WARP_NAME',pcw);
      FreeMem(pcw);
      AddInteger64(lsub,'ID',memReadInteger64(FPos));
    end;
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
  info.Version:=FVer;//verRG;

  inc(FPos);
  i:=memReadByte(FPos);
  if (i<>0) and (RGDebugLevel=dlDetailed) then
    RGLog.Add('Second byte is not 0 but '+HexStr(i,2));

  ltmp:=memReadDword(FPos);                // offset
  FBinStart:=FStart+ltmp;
  if ltmp<>0 then
  begin
    FBinPos:=FBinStart+SizeOf(TLayoutBinRG)+2;
    if FVer=verRGO then
      inc(FBinPos,6);                //!!!!!

    if (RGDebugLevel=dlDetailed) then
      RGLog.Add('Binary chunk at '+HexStr(ltmp,8));
  end;

  ltmp:=memReadByte(FPos);                 // 1
(*
  if (RGDebugLevel=dlDetailed) then
  begin
    if FVer=verRGO then
    begin
      if ltmp<>1 then
        RGLog.Add('Byte after binary offset is not 1 but '+IntToStr(ltmp));
    end
    else
    begin
      if ltmp<>0 then
        RGLog.Add('Byte after binary offset is not 0 but '+IntToStr(ltmp));
    end;
  end;
*)
  result:=AddGroup(nil,ltName[ltLayout]);
  info.SelectScene(ltName[ltLayout]);

  lcnt:=memReadWord(FPos);
  AddUnsigned(result,'COUNT',lcnt);

  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    DoParseBlockHob(lobj,-1);
end;


function TRGLayoutFile.WritePropertiesHob(anode:pointer; astream:TStream; var adata:TLayoutBinRG):integer;
var
  vct:tVector4;
  lpname,lpval:PWideChar;
  lprop:PByte;
  ltype:integer;
  l_id:dword;
  lSizePos,lNewPos:integer;
  i,j:integer;
  lok:boolean;
begin
  result:=0;

  for i:=0 to info.GetPropsCount()-1 do
  begin
    vct.x:=0;
    vct.y:=0;
    vct.z:=0;
    vct.w:=0;
    lok:=false;
    lprop:=nil;

    ltype:=info.GetPropInfoByIdx(i,l_id,lpname);
{
    case ltype of
      rgVector2: begin
//        lprop:=SearchVector(anode,lpname,'X'); if lprop<>nil then begin lok:=true; vct.X:=AsFloat(lprop); end;

        lprop:=SearchVector(anode,lpname,'X'); lok:=lok or (lprop<>nil); vct.X:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Y'); lok:=lok or (lprop<>nil); vct.Y:=AsFloat(lprop);
      end;
      rgVector3: begin
        lprop:=SearchVector(anode,lpname,'X'); lok:=lok or (lprop<>nil); vct.X:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Y'); lok:=lok or (lprop<>nil); vct.Y:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Z'); lok:=lok or (lprop<>nil); vct.Z:=AsFloat(lprop);
      end;
      rgVector4: begin
        lprop:=SearchVector(anode,lpname,'X'); lok:=lok or (lprop<>nil); vct.X:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Y'); lok:=lok or (lprop<>nil); vct.Y:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Z'); lok:=lok or (lprop<>nil); vct.Z:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'W'); lok:=lok or (lprop<>nil); vct.W:=AsFloat(lprop);
      end;
}
    if ltype in [rgVector2,rgVector3,rgVector4] then
    begin
//      lprop:=SearchVector(anode,lpname,'X'); if lprop<>nil then begin lok:=true; vct.X:=AsFloat(lprop); end;
        lprop:=SearchVector(anode,lpname,'X'); lok:=lok or (lprop<>nil); vct.X:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Y'); lok:=lok or (lprop<>nil); vct.Y:=AsFloat(lprop);
      if ltype in [rgVector3,rgVector4] then
      begin
        lprop:=SearchVector(anode,lpname,'Z'); lok:=lok or (lprop<>nil); vct.Z:=AsFloat(lprop);
      end;
      if ltype=rgVector4 then
      begin
        lprop:=SearchVector(anode,lpname,'W'); lok:=lok or (lprop<>nil); vct.W:=AsFloat(lprop);
      end;
    end
    else
    begin
      lprop:=FindNode(anode,lpname);
      // Skip these properties for Group coz they are placed into binary section
      if (adata.GUID<>QWord(-1)) and (lprop<>nil) then
      begin
        // 'CHOICE', 'LEVEL UNIQUE' and 'GAME MODE' are doubling
        if CompareWide(lpname,'CHOICE')=0 then
        begin
          lpval:=AsString(lprop);
          for j:=1 to Length(strChoice) do
            if Comparewide(lpval,strChoice[j])=0 then begin adata.choice:=j; break; end;
        end;
        if CompareWide(lpname,'GAME MODE')=0 then
        begin
          lpval:=AsString(lprop);
          for j:=1 to Length(strGameMode) do
            if Comparewide(lpval,strGameMode[j])=0 then begin adata.gamemode:=j; break; end;
        end;
        if CompareWide(lpname,'LEVEL UNIQUE')=0 then
        begin
          if AsBool(lprop) then adata.unique:=1;
        end;
        // next properties presents in binary data only
        if CompareWide(lpname,'RANDOMIZATION')=0 then
        begin
          adata.random:=AsUnsigned(lprop);
          exit;
        end;
        if CompareWide(lpname,'TAG')=0 then
        begin
          adata.tag:=GetTagTL2Num(AsString(lprop));
          exit;
        end;
        if CompareWide(lpname,'NUMBER')=0 then
        begin
          adata.number:=AsUnsigned(lprop);
          exit;
        end;
        if CompareWide(lpname,'NO TAG FOUND')=0 then
        begin
          if AsBool(lprop) then adata.notag:=1;
          exit;
        end;
      end;
    end;

    if (lprop<>nil) or lok then
    begin
      lSizePos:=astream.Position;
      astream.WriteWord(0);

      astream.WriteDWord(l_id);
      if lok then WriteVectorValue  (vct  ,ltype,astream)
      else        WritePropertyValue(lprop,ltype,astream);

      lNewPos:=astream.Position;
      astream.Position:=lSizePos;
      astream.WriteWord(lNewPos-lSizePos-2);
      astream.Position:=lNewPos;
      inc(result);
    end;

  end;

end;

function TRGLayoutFile.DoWriteBlockHob(anode:pointer; astream:TStream; abstream:TStream):integer;
var
  ldata:TLayoutBinRG; //!!!!!!!
  lobj,lprops:pointer;
  {lparent,}ldescr,lname,lid:pointer;
  lpdescr,lpname:PWideChar;
  lgrpcnt,lcnt,i:integer;
  lcpos,lpos,lPropPos,lAddPos:integer;
  lChunkType:dword;
begin
  result:=0;

  lprops:=GetChild(anode,0); // PROPERTIES

  //--- Chunk Header

  lpos:=astream.Position;
  astream.WriteDWord(0); // ChunkSize

  ldescr:=FindNode(lprops,'DESCRIPTOR');
  lpdescr:=AsString(ldescr);
  lChunkType:=info.GetObjectId(lpdescr);

  if lChunkType=dword(-1) then exit;

  astream.WriteDword(lChunkType);

  lid:=FindNode(lprops,'ID');

  astream.WriteQWord(QWord(AsInteger64(lid)));

  //--- Chunk Info

  lname:=FindNode(lprops,'NAME');
  lpname:=AsString(lname);
  if CompareWide(lpdescr,lpname)=0 then
    astream.WriteShortStringUTF8('')
  else
    astream.WriteShortStringUTF8(lpname);

  //--- Properties

  lPropPos:=astream.Position;
  astream.WriteByte(0);

  FillChar(ldata,SizeOf(ldata),0);
  if lChunkType=idGroupHob then
  begin
    ldata.GUID  :=QWord(AsInteger64(lid));
    ldata.random:=1;
    ldata.number:=1;
    ldata.offset:=lpos;
    ldata.tag   :=-1;
  end
  else
    ldata.GUID:=QWord(-1);

  lcnt:=WritePropertiesHob(lprops,astream,ldata);
  astream.WriteByteAt(lcnt,lPropPos);

  //--- Binary data

  if lChunkType=idGroupHob then
  begin
    result:=1;
    abstream.Write(ldata,SizeOf(ldata));
    case info.version of
      verHob: begin
// 22 in header already
      end;
      verRGO: begin
        abstream.WriteWord(0);
        abstream.WriteWord(0);
        abstream.WriteWord(0);
      end;
      verRG: begin
// 4 in header already
      end;
    end; 

    lcpos:=abstream.Position;
    abstream.WriteWord(0);
  end;

  //--- Additional Data

  lAddPos:=astream.Position;
  astream.WriteDWord(0);

  if (lChunkType=idTimelineTL2) or
     (lChunkType=idLogicGroupTL2) then
  begin

    if lChunkType=idTimelineTL2 then
    begin
      BuildTimeline(FindNode(lprops,'TIMELINEDATA'), astream);
    end
    else //if lChunkType=idLogicGroupTL2 then
    begin
      BuildLogicGroup(FindNode(lprops,'LOGICGROUP'), astream);
    end;

    astream.WriteDWordAt(astream.Position-lAddPos,lAddPos);
  end;

  //--- Children

  lobj:=FindNode(anode,'CHILDREN');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);
  astream.WriteWord(lcnt);

  lgrpcnt:=0;
  for i:=0 to lcnt-1 do
    lgrpcnt:=lgrpcnt+DoWriteBlockHob(GetChild(lobj,i),astream,abstream); // BASEOBJECT

  if lChunkType=idGroupHob then
    abstream.WriteWordAt(lgrpcnt,lcpos);

  //--- Chunk size

  astream.WriteDWordAt(astream.Position-lpos,lpos);
end;

function TRGLayoutFile.DoBuildLayoutHob(anode:pointer; astream:TStream):integer;
begin
  result:=astream.Position;
  info.Version:=verHob;
  info.SelectScene('');

  astream.WriteByte ( 8); // sign
  astream.WriteByte ( 0);
  astream.WriteDWord( 0); // binary offset
end;

function TRGLayoutFile.DoBuildLayoutRGO(anode:pointer; astream:TStream):integer;
var
  lbs:TMemoryStream;
  ldata:TLayoutBinRGO;
  lobj:pointer;
  i,lcnt,lsize,lchildpos:integer;
begin
  result:=astream.Position;
  info.Version:=verRGO;
  info.SelectScene('');

  astream.WriteByte ( 9); // sign
  astream.WriteByte ( 0);
  astream.WriteDWord( 0); // binary offset
  astream.WriteByte ( 1);

  lobj:=FindNode(anode,'OBJECTS');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);
  astream.WriteWord(lcnt); // root baseobject count

{
  lsize:=0;
  FillChar(ldata,SizeOf(ldata),0);
  ldata.GUID  :=QWORD(-1);
  ldata.offset:=7;
  ldata.tag   :=-1;
  lbs:=TMemoryStream.Create;
  try
    lbs.Write(ldata,SizeOf(ldata));
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lchildpos:=lbs.Position;
    lbs.WriteWord(0); // reserve for childs

    for i:=0 to lcnt-1 do
      lsize:=lsize+DoWriteBlockHob(GetChild(lobj,i),astream,lbs); // BASEOBJECT

    if lsize>0 then
    begin
      lbs.WriteWordAt(lsize,lchildpos);

      astream.WriteDWordAt(astream.Position,2);

      lsize:=lbs.Position;
      lbs.Position:=0;
      astream.CopyFrom(lbs,lsize);
    end;  
  finally
    lbs.Free;
  end;
}
  result:=astream.Position-result;
end;

function TRGLayoutFile.DoBuildLayoutRG(anode:pointer; astream:TStream):integer;
var
  lbs:TMemoryStream;
  ldata:TLayoutBinRG;
  lobj:pointer;
  i,lcnt,lsize,lchildpos:integer;
begin
  result:=astream.Position;
  info.Version:=verRG;
  info.SelectScene('Layout');

  astream.WriteByte ( 5); // sign
  astream.WriteByte ( 0);
  astream.WriteDWord( 0); // binary offset
  astream.WriteByte ( 0);

  lobj:=FindNode(anode,'OBJECTS');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);
  astream.WriteWord(lcnt); // root baseobject count

  lsize:=0;
  FillChar(ldata,SizeOf(ldata),0);
  ldata.GUID  :=QWORD(-1);
  ldata.offset:=7;
  ldata.tag   :=-1;
  lbs:=TMemoryStream.Create;
  try
    lbs.Write(ldata,SizeOf(ldata));
    lchildpos:=lbs.Position;
    lbs.WriteWord(0); // reserve for childs

    for i:=0 to lcnt-1 do
      lsize:=lsize+DoWriteBlockHob(GetChild(lobj,i),astream,lbs); // BASEOBJECT

    if lsize>0 then
    begin
      lbs.WriteWordAt(lsize,lchildpos);

      astream.WriteDWordAt(astream.Position,2);

      lsize:=lbs.Position;
      lbs.Position:=0;
      astream.CopyFrom(lbs,lsize);
    end;  
  finally
    lbs.Free;
  end;

  result:=astream.Position-result;
end;
