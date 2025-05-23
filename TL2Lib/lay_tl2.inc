{}
const
  IdGroupTL2      = 1;
  IdLogicGroupTL2 = 36;
  IdTimelineTL2   = 35;

function TRGLayoutFile.GetTagTL2(atag:integer):PWideChar;
var
  i:integer;
begin
  for i:=0 to High(FeatureTags) do
  begin
//    if atag<FeatureTags[i].id then break;
    if atag=FeatureTags[i].id then exit(pointer(FeatureTags[i].name));
  end;
  RGLog.Add('Unknown group TAG code: '+IntToStr(atag));
  result:=nil;
end;

function TRGLayoutFile.GetTagTL2Num(atag:PWideChar):integer;
var
  i:integer;
begin
  for i:=0 to High(FeatureTags) do
  begin
    if CompareWideI(atag,pointer(FeatureTags[i].name))=0 then exit(FeatureTags[i].id);
  end;
  RGLog.Add('Unknown group TAG value '+WideToStr(atag));
  result:=-1;
end;

procedure TRGLayoutFile.ReadBinaryDataTL2(var anode:pointer; aid:Int64);
var
  ldata:TLayoutBin;
  lls,ls:UnicodeString;
  p:PWideChar;
  i,lthemes:integer;
begin
  memReadData(FBinPos,ldata,SizeOf(ldata));
  if ldata.GUID<>QWord(aid) then
     FLog.Add('ID of Group object and binary data are not the same: '+
         IntToStr(aid)+' vs '+IntToStr(Int64(ldata.GUID)));

  if ldata.number<>1 then AddUnsigned(anode,'NUMBER'       ,ldata.number);
  if ldata.random<>1 then AddUnsigned(anode,'RANDOMIZATION',ldata.random);
  if ldata.choice<>0 then
  begin
    if FindNode(anode,'CHOICE')=nil then
    begin
      if ldata.choice<=Length(strChoice) then
        AddString(anode,'CHOICE',strChoice[ldata.choice]);
    end;
  end;
  if ldata.unique<>0 then
  begin
    if FindNode(anode,'LEVEL UNIQUE')=nil then
        AddBool(anode,'LEVEL UNIQUE',true)
  end;

  if ldata.noflag<>0 then AddBool(anode,'NO TAG FOUND' ,true);
  if (ldata.noflag<>0) and (ldata.noflag<>1) then
    RGLog.Add('Notag value is not boolean but '+IntToStr(ldata.noflag));

  if ldata.tag>=0 then
  begin
    p:=GetTagTL2(ldata.tag);
    if p<>nil then
      AddString(anode,'TAG',p)
    else
    begin
      Str(ldata.tag,lls);
      AddString(anode,'TAG',PWideChar(lls));
    end;
  end;

  i:=memReadByte(FBinPos);
  if i<>0 then
  begin
    if FindNode(anode,'GAME MODE')=nil then
    begin
      if i<=Length(strGameMode) then
        AddString(anode,'GAME MODE',strGameMode[i]);
    end;
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

  memReadWord(FBinPos); // child
end;

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
  lbuf:UnicodeString;
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

  lptr:=FPos;

  //--- Chunk Header

  lChunkSize:=memReadInteger(FPos);
//  if lChunkSize=0 then exit;
  lChunkType:=memReadByte(FPos);
  if lChunkType>0 then
  begin
    bnode:=AddGroup(anode,'BASEOBJECT');
    lnode:=AddGroup(bnode,'PROPERTIES');

    lChunkId:=memReadInteger64(FPos);

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

    //--- Place for binary group data translation

    if lChunkType=IdGroupTL2 then
      ReadBinaryDataTL2(lnode,lChunkId);

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
        FLog.Add('Unknown chunk with size '+IntToStr(lsize)+' at '+HexStr(FPos-FStart,8));
      //!!
        AddString (lnode,'??ADDITIONALDATA',PWideChar(UnicodeString(HexStr(FPos-FStart,8))));
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

  end;
  // Really, we can have Children section even for ZERO type

  FPos:=lptr+lChunkSize;
end;

function TRGLayoutFile.DoParseLayoutTL2(atype:cardinal):pointer;
var
  lobj,lc:pointer;
  pcw:PWideChar;
  i,lcnt,lobjcnt:integer;
  ltmp:dword;
begin
  info.Version:=verTL2;

  inc(FPos);
  
  pcw:=ltName[atype];

  result:=AddGroup(nil,pcw);
  info.SelectScene(pcw);

  FLayVer:=memReadByte(FPos);               // Layout version
  AddInteger(result,'VERSION',FLayVer);
  if (FLayVer<>4)  and (RGDebugLevel=dlDetailed) then
    FLog.Add('Layout version is not 4 but '+HexStr(FLayVer,2));

  lc:=AddUnsigned(result,'COUNT',0);
  ltmp:=memReadDWord(FPos);              // offset
  FBinStart:=FStart+ltmp;
  if ltmp<>0 then
  begin
    FBinPos:=FBinStart+SizeOf(TLayoutBin)+9+2;
    if (RGDebugLevel=dlDetailed) then
      FLog.Add('Binary chunk at '+HexStr(ltmp,8));
  end;

  lcnt:=memReadWord(FPos);               // root baseobject count

  lobjcnt:=0;
  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    inc(lobjcnt,DoParseBlockTL2(lobj,-1));

  asUnsigned(lc,lobjcnt);
end;

function TRGLayoutFile.WritePropertiesTL2(anode:pointer; astream:TStream; var adata:TLayoutBin):integer;
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
        if CompareWide(lpname,'LEVEL UNIQUE')=0 then
        begin
          if AsBool(lprop) then adata.unique:=1;
        end;
        // let mean what doubling for case 255+
        if CompareWide(lpname,'NUMBER')=0 then
        begin
          adata.number:=AsUnsigned(lprop);
//          exit;
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
        if CompareWide(lpname,'NO TAG FOUND')=0 then
        begin
          if AsBool(lprop) then adata.noflag:=1;
          exit;
        end;
        if CompareWide(lpname,'ACTIVE THEMES'  )=0 then exit;
        if CompareWide(lpname,'DEACTIVE THEMES')=0 then exit;
      end;
    end;

    if (lprop<>nil) or lok then
    begin
      lSizePos:=astream.Position;
      astream.WriteWord(0);

      astream.WriteByte(l_id);
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

procedure WriteThemesTL2(anode:pointer; aval:PWideChar; astream:TStream);
var
  lval:array [0..31] of WideChar;
  lint64:Int64;
  i,lidx,lcnt:integer;
begin
  anode:=FindNode(anode,aval);
  if anode<>nil then
  begin
    aval:=AsString(anode);
    lcnt:=splitCountW(aval,',');
    if lcnt>0 then
    begin
      astream.WriteDWord(DWORD(lcnt));

      for i:=0 to lcnt-1 do
      begin
        lidx:=0;
        repeat
          while aval^=',' do inc(aval);
          lval[lidx]:=aval^;
          inc(lidx);
          inc(aval);
        until (aval^=',') or (aval^=#0);
        lval[lidx]:=#0;

        Val(lval,lint64);
        astream.WriteQWord(qword(lint64));
      end;

      exit;
    end;
  end;

  astream.WriteDWord(0);
end;

function TRGLayoutFile.DoWriteBlockTL2(anode:pointer; astream:TStream; abstream:TStream):integer;
var
  ldata:TLayoutBin;
  lobj,lprops:pointer;
  {lparent,}ldescr,lname,lid:pointer;
  lpdescr,lpname:PWideChar;
  lchilds,lchild,lgrpcnt,lcnt,i:integer;
  lcpos,lpos,lPropPos,lAddPos,lChildPos:integer;
  lChunkType:byte;
begin
  result:=0;

  lprops:=GetChild(anode,0); // PROPERTIES

  //--- Chunk Header

  ldescr:=FindNode(lprops,'DESCRIPTOR');
  lpdescr:=AsString(ldescr);
  i:=integer(info.GetObjectId(lpdescr));

  if i=-1 then exit(-1);

  lpos:=astream.Position;
  astream.WriteDWord(0); // ChunkSize

  lChunkType:=i;
  astream.WriteByte(lChunkType);

  lid:=FindNode(lprops,'ID');

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

  FillChar(ldata,SizeOf(ldata),0);
  if lChunkType=idGroupTL2 then
  begin
    ldata.GUID  :=QWord(AsInteger64(lid));
    ldata.random:=1;
    ldata.number:=1;
    ldata.offset:=lpos;
    ldata.tag   :=-1;
  end
  else
    ldata.GUID:=QWord(-1);

  lcnt:=WritePropertiesTL2(lprops,astream,ldata);
  astream.WriteByteAt(lcnt,lPropPos);

  //--- Binary data

  if lChunkType=idGroupTL2 then
  begin
    result:=1;
    abstream.Write(ldata,SizeOf(ldata));

    lpdescr:=AsString(FindNode(lprops,'GAME MODE'));
    if lpdescr=nil then
      i:=0
    else
      for lcnt:=1 to Length(strGameMode) do
        if Comparewide(lpdescr,strGameMode[lcnt])=0 then
        begin
          i:=lcnt;
          break;
        end;
    abstream.WriteByte(i);

    WriteThemesTL2(lprops,'ACTIVE THEMES'  ,abstream);
    WriteThemesTL2(lprops,'DEACTIVE THEMES',abstream);
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

    astream.WriteDWordAt(astream.Position-lAddPos-SizeOf(DWord),lAddPos);
  end;

  //--- Children

  lobj:=FindNode(anode,'CHILDREN');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);
  lChildPos:=astream.Position;
  astream.WriteWord(lcnt);

  lgrpcnt:=0;
  lchilds:=0;
  for i:=0 to lcnt-1 do
  begin
    lchild:=DoWriteBlockTL2(GetChild(lobj,i),astream,abstream); // BASEOBJECT
    if lchild>=0 then
    begin
      inc(lchilds);
      lgrpcnt:=lgrpcnt+lchild;
    end;
  end;
  astream.WriteWordAt(lchilds,lChildPos);

  if lChunkType=idGroupTL2 then
    abstream.WriteWordAt(lgrpcnt,lcpos);

  //--- Chunk size

  astream.WriteDWordAt(astream.Position-lpos,lpos);
end;

function TRGLayoutFile.DoBuildLayoutTL2(anode:pointer; astream:TStream):integer;
var
  lbs:TMemoryStream;
  ldata:TLayoutBin;
  lobj:pointer;
  lChildsPos,lchilds,lchild,i,lcnt,lsize,lchildpos:integer;
begin
  result:=astream.Position;
  info.Version:=verTL2;
  info.SelectScene('');

  astream.WriteByte (11); // sign
  astream.WriteByte ( 4); // 'version'
  astream.WriteDWord( 0); // binary offset

  lobj:=FindNode(anode,'OBJECTS');
  if lobj=nil then lcnt:=0
  else lcnt:=GetGroupCount(lobj);
  lChildsPos:=astream.Position;
  astream.WriteWord(lcnt); // root baseobject count

  lsize:=0;
  FillChar(ldata,SizeOf(ldata),0);
  ldata.GUID  :=QWORD(-1);
  ldata.offset:=6;
  ldata.tag   :=-1;
  lbs:=TMemoryStream.Create;
  try
    lbs.Write(ldata,SizeOf(ldata));
    lbs.WriteByte (0); // Game Mode
    lbs.WriteDWord(0); // Active themes
    lbs.WriteDWord(0); // DeActive themes
    lchildpos:=lbs.Position;
    lbs.WriteWord(0);    // reserve for childs

    lchilds:=0;
    for i:=0 to lcnt-1 do
    begin
      lchild:=DoWriteBlockTL2(GetChild(lobj,i),astream,lbs); // BASEOBJECT
      if lchild>=0 then
      begin
        lsize:=lsize+lchild;
        inc(lchilds);
      end;
    end;

    astream.WriteWordAt(lchilds,lChildsPos);
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
