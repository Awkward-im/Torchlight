{}

const
  // trigger decal react
  IdGroupHob      = 4270653419;
  IdGroupBake     = 4270023114;
  IdGroupMonster  = 3078161015;
  IdLogicGroupHob = 2261606130;
  IdTimelineHob   = 2623981599;

procedure TRGLayoutFile.ReadBinaryDataHob(var anode:pointer);
var
  ldata:TLayoutBin;
  lls,ls:WideString;
  p:PWideChar;
  i,lthemes:integer;
  ltmp:array [0..14] of byte;
begin
  ReadBinaryData(anode, ldata);

  if ldata.noflag<>0 then FLog.Add('Unk1='+IntToStr(ldata.noflag));

  i:=memReadWord(FBinPos); // Unk3
  if word(i)<>0 then FLog.Add('Unk3='+IntToStr(word(i)));

  i:=memReadWord(FBinPos); // Unk4
  if word(i)<>0 then FLog.Add('Unk4='+IntToStr(word(i)));

  i:=memReadByte(FBinPos); // Unk5
  if byte(i)<>0 then
  begin
    if rgDebugLevel=dlDetailed then
    begin
      FLog.Add('Unk5 (0 or 6)='+IntToStr(i))
    //  AddUnsigned(anode,'unk5',ldata.unk5);
    end
    else if rgDebugLevel<>dlNone then
    begin
      if (i<>0) and (i<>6) then
      begin
        FLog.Add('Unk5 (0 or 6)='+IntToStr(i))
      //  AddUnsigned(anode,'unk5',ldata.unk5);
      end
    end;
  end;

  memReadData(FBinPos,ltmp,SizeOf(ltmp));
  if (ltmp[ 0]<>0) or (ltmp[ 1]<>0) or (ltmp[ 2]<>0) or (ltmp[ 3]<>0) or
     (ltmp[ 4]<>0) or (ltmp[ 5]<>0) or (ltmp[ 6]<>0) or (ltmp[ 7]<>0) or
     (ltmp[ 8]<>0) or (ltmp[ 9]<>0) or (ltmp[10]<>0) or (ltmp[11]<>0) or
     (ltmp[12]<>0) or (ltmp[13]<>0) or (ltmp[14]<>0) then
  begin
    AddString(anode,'!!Unknown','not zero');
  end;

  memReadWord(FBinPos); // child
end;

procedure TRGLayoutFile.ReadBinaryDataRGO(var anode:pointer);
var
  ldata:TLayoutBin;
  lls,ls:WideString;
  p:PWideChar;
  lnode:pointer;
  i,lthemes:integer;
begin
  ReadBinaryData(anode, ldata);

  if ldata.noflag<>0 then
  begin
    if FindNode(anode,'CREATEWITHNOFLAG')=nil then
        AddBool(anode,'CREATEWITHNOFLAG',true);
  end;

  i:=memReadByte(FBinPos); // Unk3
  if byte(i)<>0 then FLog.Add('Unk3='+IntToStr(byte(i)));

  i:=memReadByte(FBinPos);
  if byte(i)<>0 then
  begin
    if FindNode(anode,'DONTPROPAGATE')=nil then
        AddBool(anode,'DONTPROPAGATE',true);
  end;

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
  end;

  memReadWord(FBinPos); // child
end;

procedure TRGLayoutFile.ReadBinaryDataRG(var anode:pointer);
var
  ldata:TLayoutBin;
  lls,ls:WideString;
  p:PWideChar;
  i,lthemes:integer;
begin
  ReadBinaryData(anode, ldata);

  if ldata.noflag<>0 then FLog.Add('Unk1='+IntToStr(ldata.noflag));

  i:=memReadByte(FBinPos); // Unk3
  if byte(i)<>0 then FLog.Add('Unk3='+IntToStr(byte(i)));

  i:=memReadByte(FBinPos); // Unk4
  if byte(i)<>0 then FLog.Add('Unk4='+IntToStr(byte(i)));

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

  FLog.Reserve('Object '+UTF8Encode(WideString(lname)));

  lcnt:=memReadByte(FPos);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyHob(lnode);
  end;

  //--- Place for binary group data translation

  if (lChunkType=IdGroupHob    ) or
     (lChunkType=IdGroupBake   ) or
     (lChunkType=IdGroupMonster) then
  begin
    case FVer of
      verHob: ReadBinaryDataHob(lnode);
      verRG : ReadBinaryDataRG (lnode);
      verRGO: ReadBinaryDataRGO(lnode);
    end;
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
      FLog.Add('Unknown chunk with size '+IntToStr(lsize)+' at '+HexStr(FPos-FStart,8));
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

//  FLog.Reserve('');
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
    FLog.Add('Second byte is not 0 but '+HexStr(ltmp,2));

  result:=AddGroup(nil,ltName[ltLayout]);
  info.SelectScene(ltName[ltLayout]);

  lcnt:=memReadDWord(FPos);                // TOTAL object amount
  AddUnsigned(result,'COUNT',lcnt);

  ltmp:=memReadDword(FPos);                // offset
  FBinStart:=FStart+ltmp;
  if ltmp<>0 then
  begin
    FBinPos:=FBinStart+SizeOf(TLayoutBin)+20+2;
    if (RGDebugLevel=dlDetailed) then
      FLog.Add('Binary chunk at '+HexStr(ltmp,8));
  end;

  //--- Header

  ltmp:=memReadByte(FPos);                 // 1
  if (ltmp<>1) and (RGDebugLevel=dlDetailed) then
    FLog.Add('Byte after binary offset is not 1 but '+IntToStr(ltmp));

  pcw:=memReadShortStringUTF8(FPos);       // LEVEL
  AddString(result,'TYPE',pcw);
  if CompareWide(pcw,'LEVEL')<>0 then
    FLog.Add('Type is not LEVEL but '+string(pcw));
  FreeMem(pcw);

  ltmp:=memReadByte(FPos);                 // 0
  if (ltmp<>0) and (RGDebugLevel=dlDetailed) then
    FLog.Add('Byte after type is not 0 but '+IntToStr(ltmp));
  ltmp:=memReadByte(FPos);                 // 4
  if (ltmp<>4) and (RGDebugLevel=dlDetailed) then
    FLog.Add('Byte before main data offset is not 4 but '+IntToStr(ltmp));

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
    FLog.Add('Byte (1 of 3) is not 1 but '+IntToStr(ltmp));

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

  //--- Main layout data

  FPos:=FStart+ldata;

  lcnt:=memReadWord(FPos);   // ROOT object amoun

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
    FLog.Add('Second byte is not 0 but '+HexStr(i,2));

  ltmp:=memReadDword(FPos);                // offset
  FBinStart:=FStart+ltmp;
  if ltmp<>0 then
  begin
    if FVer=verRG then i:=2 // unk3+unk4
    else i:=8;              // unk3+noprop+game+scene+world

    FBinPos:=FBinStart+SizeOf(TLayoutBin)+i+2; // +child count

    if (RGDebugLevel=dlDetailed) then
      FLog.Add('Binary chunk at '+HexStr(ltmp,8));
  end;

  ltmp:=memReadByte(FPos);                 // 1
  if (ltmp<>0) and (RGDebugLevel=dlDetailed) then
    FLog.Add('Byte after binary offset is not 0 but '+IntToStr(ltmp));
//  if (RGDebugLevel=dlDetailed) then
//    FLog.Add('Byte after binary offset is '+IntToStr(ltmp));
(*
  if (RGDebugLevel=dlDetailed) then
  begin
    if FVer=verRGO then
    begin
      if ltmp<>1 then
        FLog.Add('Byte after binary offset is not 1 but '+IntToStr(ltmp));
    end
    else
    begin
      if ltmp<>0 then
        FLog.Add('Byte after binary offset is not 0 but '+IntToStr(ltmp));
    end;
  end;
*)
  result:=AddGroup(nil,ltName[ltLayout]);
  info.SelectScene(ltName[ltLayout]);

  //--- Main layout data

  lcnt:=memReadWord(FPos);                // ROOT object amoun
  AddUnsigned(result,'COUNT',lcnt);

  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    DoParseBlockHob(lobj,-1);
end;


function TRGLayoutFile.WritePropertiesHob(anode:pointer; astream:TStream; var adata:TLayoutBin):integer;
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
        // 'CHOICE' and 'LEVEL UNIQUE' are doubling
        if CompareWide(lpname,'CHOICE')=0 then
        begin
          lpval:=AsString(lprop);
          for j:=1 to Length(strChoice) do
            if Comparewide(lpval,strChoice[j])=0 then begin adata.choice:=j; break; end;
        end;
        if CompareWide(lpname,'LEVEL UNIQUE')=0 then
        begin
          if AsBool(lprop) then adata.unique:=1;
        end;
        // double for case 255+
        if CompareWide(lpname,'NUMBER')=0 then
        begin
          adata.number:=byte(AsUnsigned(lprop));
//          exit;
        end;
        if (FVer=verRG) or (FVer=verRGO) then
        begin
          if CompareWide(lpname,'CREATEWITHNOFLAG')=0 then
          begin
            if AsBool(lprop) then adata.noflag:=1;
          end;
        end;
        // next properties presents in binary data only
        if CompareWide(lpname,'RANDOMIZATION')=0 then
        begin
          adata.random:=AsUnsigned(lprop);
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
  ldata:TLayoutBin;
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
  inc(FCount);

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
  if (lChunkType=idGroupHob    ) or
     (lChunkType=idGroupBake   ) or
     (lChunkType=idGroupMonster) then
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

  if (lChunkType=idGroupHob    ) or
     (lChunkType=idGroupBake   ) or
     (lChunkType=idGroupMonster) then
  begin
    result:=1;
    // CHOICE, NUMBER, RANDOMIZATION and LEVEL_UNIQUE are all inside ldata
    abstream.Write(ldata,SizeOf(ldata));
    case FVer of
      verHob: begin
        abstream.WriteWord(0);  // 1
        abstream.WriteWord(0);  // 2
        abstream.WriteWord(0);  // 3 can be =6
        abstream.WriteWord(0);  // 4
        abstream.WriteWord(0);  // 5
        abstream.WriteWord(0);  // 6
        abstream.WriteWord(0);  // 7
        abstream.WriteWord(0);  // 8
        abstream.WriteWord(0);  // 9
        abstream.WriteWord(0);  // 10
      end;

      verRGO: begin
        abstream.WriteByte(0); // unk3

         // if set, must be in props too
        lobj:=FindNode(lprops,'DONTPROPAGATE');
        if AsBool(lobj) then i:=1 else i:=0;
        abstream.WriteByte(i);

        // lobj=nil -> lpdescr=nil -> WriteWord(0)
        lobj:=FindNode(lprops,'GAMEFLAGREQUIREMENT');
        lpdescr:=AsString(lobj);
        abstream.WriteShortStringUTF8(lpdescr);

        lobj:=FindNode(lprops,'SCENEFLAGREQUIREMENT');
        lpdescr:=AsString(lobj);
        abstream.WriteShortStringUTF8(lpdescr);

        lobj:=FindNode(lprops,'WORLDTAGREQUIUREMENT');
        lpdescr:=AsString(lobj);
        abstream.WriteShortStringUTF8(lpdescr);
      end;

      verRG: begin
        abstream.WriteWord(0);
      end;
    end; 

    lcpos:=abstream.Position;
    abstream.WriteWord(0);
  end;

  //--- Additional Data

  lAddPos:=astream.Position;
  astream.WriteDWord(0);

  if (lChunkType=idTimelineHob) or
     (lChunkType=idLogicGroupHob) then
  begin

    if lChunkType=idTimelineHob then
    begin
      BuildTimeline(FindNode(lprops,'TIMELINEDATA'), astream);
    end
    else //if lChunkType=idLogicGroupHob then
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

  if (lChunkType=idGroupHob    ) or
     (lChunkType=idGroupBake   ) or
     (lChunkType=idGroupMonster) then
    abstream.WriteWordAt(lgrpcnt,lcpos);

  //--- Chunk size

  astream.WriteDWordAt(astream.Position-lpos,lpos);
end;

function TRGLayoutFile.DoBuildLayoutHob(anode:pointer; astream:TStream):integer;
var
  lbs:TMemoryStream;
  ldata:TLayoutBin;
  lobj,lsub:pointer;
  pc:PWideChar;
  i,lcnt,lsize,ldatapos,lchildpos:integer;
begin
  result:=astream.Position;
  info.Version:=verHob;
  info.SelectScene(ltName[ltLayout]);

  astream.WriteByte (8); // sign
  astream.WriteByte (0);
  astream.WriteDWord(0); // total object Count
  astream.WriteDWord(0); // binary offset

  //--- Header

  astream.WriteByte(0);

  pc:=AsString(FindNode(anode,'TYPE'));
  astream.WriteShortStringUTF8(AsString(FindNode(anode,'TYPE')));

  astream.WriteByte(0);
  astream.WriteByte(4);

  ldatapos:=astream.Position;
  astream.WriteDWord(0); // real layout data offset

  astream.WriteShortString(AsString(FindNode(anode,'BASE')));

  astream.WriteFloat(AsFloat(FindNode(anode,'X1')));
  astream.WriteFloat(AsFloat(FindNode(anode,'Y1')));
  astream.WriteFloat(AsFloat(FindNode(anode,'Z1')));
  astream.WriteFloat(AsFloat(FindNode(anode,'X2')));
  astream.WriteFloat(AsFloat(FindNode(anode,'Y2')));
  astream.WriteFloat(AsFloat(FindNode(anode,'Z2')));

  astream.WriteByte(1);

  lobj:=FindNode(anode,'WARPPOINTS');
  lcnt:=GetGroupCount(lobj);
  astream.WriteWord(lcnt);
  for i:=0 to lcnt-1 do
  begin
    lsub:=GetChild(lobj,i);
    astream.WriteShortStringUTF8(AsString   (FindNode(lsub,'WARP_NAME')));
    astream.WriteQWord(QWord    (AsInteger64(FindNode(lsub,'ID'))));
  end;

  //--- Main layout data
  
  lsize:=0;
  FillChar(ldata,SizeOf(ldata),0);
  ldata.GUID  :=QWORD(-1);
  ldata.offset:=astream.Position;
  ldata.tag   :=-1;
  astream.WriteDWordAt(ldata.offset,ldatapos);

  lobj:=FindNode(anode,'OBJECTS');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);
  astream.WriteWord(lcnt); // root baseobject count
//!!
  lbs:=TMemoryStream.Create;
  try
    lbs.Write(ldata,SizeOf(ldata));

    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);
    lbs.WriteWord(0);

    lchildpos:=lbs.Position;
    lbs.WriteWord(0); // reserve for childs

    FCount:=0; // count of all objects

    for i:=0 to lcnt-1 do
    begin
      lsize:=lsize+DoWriteBlockHob(GetChild(lobj,i),astream,lbs); // BASEOBJECT
    end;

    astream.WriteDWordAt(FCount,2); // total object count

    if lsize>0 then
    begin
      lbs.WriteWordAt(lsize,lchildpos);

      astream.WriteDWordAt(astream.Position,6); // write binary offset

      lsize:=lbs.Position;
      lbs.Position:=0;
      astream.CopyFrom(lbs,lsize);
    end;  
  finally
    lbs.Free;
  end;

  result:=astream.Position-result;

end;

function TRGLayoutFile.DoBuildLayoutRG(anode:pointer; astream:TStream):integer;
var
  lbs:TMemoryStream;
  ldata:TLayoutBin;
  lobj:pointer;
  i,lcnt,lsize,lchildpos:integer;
begin
  result:=astream.Position;
  info.Version:=FVer;
  info.SelectScene(ltName[ltLayout]);

  if FVer=verRG then
  begin
    astream.WriteByte (5); // sign
    astream.WriteByte (0);
    astream.WriteDWord(0); // binary offset
    astream.WriteByte (0);
  end
  else
  begin
    astream.WriteByte (9); // sign
    astream.WriteByte (0);
    astream.WriteDWord(0); // binary offset
    astream.WriteByte (1);
  end;

  lsize:=0;
  FillChar(ldata,SizeOf(ldata),0);
  ldata.GUID  :=QWORD(-1);
  ldata.offset:=astream.Position; // 7
  ldata.tag   :=-1;

  lobj:=FindNode(anode,'OBJECTS');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);

  astream.WriteWord(lcnt); // root baseobject count

  lbs:=TMemoryStream.Create;
  try
    lbs.Write(ldata,SizeOf(ldata));
    if FVer=verRG then
    begin
      lbs.WriteByte(0);
      lbs.WriteByte(0);
    end
    else
    begin
      lbs.WriteByte(0);
      lbs.WriteByte(0);
      lbs.WriteWord(0);
      lbs.WriteWord(0);
      lbs.WriteWord(0);
    end;
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
