{}
const
  arBinDataIds:array of DWord = (
    4270653419, // Group
    4270023114, // Group Bake
    1006154892, // Group Step Child
    3078161015, // Monster Group
    684627136,  // React Group
    2563527888, // Decal Group
    3247079513, // Area Time Controller
    449428563,  // Pulse Controller
    944695435,  // Jump Start Node
    2384551518  // Warp Filter
  );

const
  IdLogicGroupHob  = 2261606130;
  IdTimelineHob    = 2623981599;
  IdHackId         = 338732389;

function IsBinDataHave(aid:DWord):boolean;
var
  i:integer;
begin
  for i:=0 to High(arBinDataIds) do
    if arBinDataIds[i]=aid then exit(true);
  exit(false);
end;

procedure TRGLayoutFile.ReadBinaryDataHob(var anode:pointer; aid:Int64);
var
  ldata:TLayoutBin;
  lnode:pointer;
  i:integer;
  lval:dword;
begin
  ReadBinaryData(anode, ldata);
  if ldata.GUID<>QWord(aid) then
     FLog.Add('ID of Group object and binary data are not the same: '+
         IntToStr(aid)+' vs '+IntToStr(Int64(ldata.GUID)));

  if ldata.noflag<>0 then FLog.Add('Unk1='+IntToStr(ldata.noflag));

  i:=memReadByte(FBinPos); // Unk3
  if byte(i)<>0 then FLog.Add('Unk3='+IntToStr(byte(i)));

  i:=memReadByte(FBinPos);
  if byte(i)<>0 then
  begin
    if FindNode(anode,'STEPCHILD')=nil then
        AddBool(anode,'STEPCHILD',true);
  end;

  i:=memReadWord(FBinPos); // Unk4
  if word(i)<>0 then FLog.Add('Unk4='+IntToStr(word(i)));

  lval:=memReadDWord(FBinPos); // Operator
  if lval<Length(strOperator) then
  begin
    if FindNode(anode,'OPERATOR')=nil then
      AddString(anode,'OPERATOR',strOperator[lval]);
  end
  else if lval>Length(strOperator) then
    FLog.Add('Operator = '+IntToStr(lval));

  i:=Integer(memReadDWord(FBinPos)); // VALUE_COMPARE
  if i<>0 then
  begin
    lnode:=FindNode(anode,'VALUE_COMPARE');
    if lnode=nil then
      AddInteger(anode,'VALUE_COMPARE',i)
    else if rgDebugLevel=dlDetailed then
    begin
      if AsInteger(lnode)<>i then
        FLog.Add('Value compare is not equ with binary: '+
          IntToStr(AsInteger(lnode))+' vs '+IntToStr(i));
    end;
  end;

  lval:=memReadDWord(FBinPos);
  if lval<>0 then FLog.Add('Unk6='+IntToStr(lval));

  lval:=memReadDWord(FBinPos);
  if lval<>0 then FLog.Add('Unk7='+IntToStr(lval));

  memReadWord(FBinPos); // child
end;

procedure TRGLayoutFile.ReadBinaryDataRGO(var anode:pointer; aid:Int64);
var
  ldata:TLayoutBin;
  p:PWideChar;
  i:integer;
begin
  ReadBinaryData(anode, ldata);
  if ldata.GUID<>QWord(aid) then
     FLog.Add('ID of Group object and binary data are not the same: '+
         IntToStr(aid)+' vs '+IntToStr(Int64(ldata.GUID)));

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

procedure TRGLayoutFile.ReadBinaryDataRG(var anode:pointer; aid:Int64);
var
  ldata:TLayoutBin;
  i:integer;
begin
  ReadBinaryData(anode, ldata);
  if ldata.GUID<>QWord(aid) then
     FLog.Add('ID of Group object and binary data are not the same: '+
         IntToStr(aid)+' vs '+IntToStr(Int64(ldata.GUID)));

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
  ls:array [0..4] of WideChar;
  lhash,ldata:dword;
  lsize:integer;
begin
  lsize:=memReadWord(FPos);
  if lsize=0 then exit;

  lptr:=FPos;
  lhash:=memReadDWord(FPos);

  //!!!!!!!!!!!!!!1
  if lhash=IdHackId then
  begin
    ldata:=memReadDword(FPos);
    if (ldata<>0) and (ldata<>dword(-1)) then
    begin
      ls[3]:=WideChar((ldata and $FF000000) shr 24);
      if ord(ls[3]) in [33..127] then
      begin
        ls[2]:=WideChar((ldata and $00FF0000) shr 16);
        if ord(ls[2]) in [33..127] then
        begin
          ls[1]:=WideChar((ldata and $0000FF00) shr 8);
          if ord(ls[1]) in [33..127] then
          begin
            ls[0]:=WideChar(ldata and $000000FF);
            if ord(ls[0]) in [33..127] then
            begin
              ls[4]:=#0;
              AddString(anode,'HACKID-VALUE',ls);
            end;
          end;
        end;
      end;
    end;
  end;
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

  FLog.Reserve('Object '+UTF8Encode(UnicodeString(lname))+', ID='+IntToStr(lChunkId));

  lcnt:=memReadByte(FPos);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyHob(lnode);
  end;

  //--- Place for binary group data translation
{
  if (lChunkType=IdGroupHob      ) or
     (lChunkType=IdGroupBake     ) or
     (lChunkType=IdGroupStepChild) or
     (lChunkType=IdReactGroup    ) or
     (lChunkType=IdGroupMonster  ) then
}
  if IsBinDataHave(lChunkType) then
  begin
    case FVer of
      verHob: ReadBinaryDataHob(lnode,lChunkId);
      verRG : ReadBinaryDataRG (lnode,lChunkId);
      verRGO: ReadBinaryDataRGO(lnode,lChunkId);
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
      AddString (lnode,'??ADDITIONALDATA', PWideChar(UnicodeString(HexStr(FPos-FStart,8))));
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
//    if (RGDebugLevel=dlDetailed) then FLog.Add('Binary chunk at '+HexStr(ltmp,8));
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

//    if (RGDebugLevel=dlDetailed) then FLog.Add('Binary chunk at '+HexStr(ltmp,8));
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
{
  if (lChunkType=idGroupHob      ) or
     (lChunkType=idGroupBake     ) or
     (lChunkType=idGroupStepChild) or
     (lChunkType=IdReactGroup    ) or
     (lChunkType=idGroupMonster  ) then
}
  if IsBinDataHave(lChunkType) then
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
{
  if (lChunkType=idGroupHob      ) or
     (lChunkType=idGroupBake     ) or
     (lChunkType=idGroupStepChild) or
     (lChunkType=IdReactGroup    ) or
     (lChunkType=idGroupMonster  ) then
}
  if IsBinDataHave(lChunkType) then
  begin
    result:=1;
    // CHOICE, NUMBER, RANDOMIZATION and LEVEL_UNIQUE are all inside ldata
    abstream.Write(ldata,SizeOf(ldata));
    case FVer of
      verHob: begin
        abstream.WriteByte(0);  // Unk3

        lobj:=FindNode(lprops,'STEPCHILD');
        if AsBool(lobj) then i:=1 else i:=0;
        abstream.WriteByte(i);

        abstream.WriteWord(0);  // Unk4

        lobj:=FindNode(lprops,'OPERATOR');
        lpdescr:=AsString(lobj);
        i:=0;
        repeat
          if CompareWide(lpdescr,strOperator[i])=0 then break;
          inc(i);
        until i=Length(strOperator);
        abstream.WriteDWord(i);

        lobj:=FindNode(lprops,'VALUE_COMPARE');
        i:=AsInteger(lobj);
        abstream.WriteDWord(dword(i));

        abstream.WriteDWord(0);  // Unk6
        abstream.WriteDWord(0);  // Unk7
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
{
  if (lChunkType=idGroupHob    ) or
     (lChunkType=idGroupBake   ) or
     (lChunkType=idGroupMonster) then
}
  if IsBinDataHave(lChunkType) then
    abstream.WriteWordAt(lgrpcnt,lcpos);

  //--- Chunk size

  astream.WriteDWordAt(astream.Position-lpos,lpos);
end;

function TRGLayoutFile.DoBuildLayoutHob(anode:pointer; astream:TStream):integer;
var
  lbs:TMemoryStream;
  ldata:TLayoutBin;
  lobj,lsub:pointer;
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
