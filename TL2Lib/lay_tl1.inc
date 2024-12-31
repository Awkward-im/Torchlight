{
  Last Binary data is ID of last object+offset to this offset
}
const
  IdGroupTL1      = 0;
  IdTimelineTL1   = 34;
  IdLogicGroupTL1 = 35;

procedure TRGLayoutFile.ProcessTLNames();
var
  pcw:PWideChar;
  i,j:integer;
begin
  for i:=0 to cntTLItem-1 do
  begin
    for j:=0 to cntNOItem-1 do
    begin
      if TLItems[i].layid=NOItems[j].layid then
      begin
        info.GetObjectById(NOItems[j].dictid);
        if TLItems[i].isprop then
          info.GetPropInfoById(TLItems[i].propid,pcw)
        else
          pcw:=info.GetFuncById(TLItems[i].propid);

        if pcw<>nil then
          AsString(TLItems[i].nameptr,pcw);
        break;
      end;
    end;
  end;
end;

procedure TRGLayoutFile.PostProcess();
var
  lnode,pnode:pointer;
  i,j,k:integer;
begin
  for i:=0 to cntNOItem-1 do
  begin
    // need to reattach node from root to parent
    if (NOItems[i].dictid=IdGroupTL1) then
    begin
      if (NOItems[i].parent<>-1) then
      begin
        for j:=0 to cntNOItem-1 do
        begin
          if NOItems[i].parent=NOItems[j].layid then
          begin
            // check for CHILDREN
            lnode:=nil;
            pnode:=NOItems[j].node;
            for k:=0 to GetChildCount(pnode)-1 do
            begin
              lnode:=GetChild(pnode,k);
              if CompareWide(GetNodeName(lnode),'CHILDREN')=0 then
                break
              else
                lnode:=nil;
            end;
            if lnode=nil then
              lnode:=AddGroup(pnode,'CHILDREN');
            CutNode(NOItems[i].node);
            AddNode(lnode,NOItems[i].node);
            break;
          end;
        end;
      end;
    end
    else if (NOItems[i].dictid=IdLogicGroupTL1) then
    begin
      lnode:=GetChild(NOItems[i].node,0);
      ParseLogicGroupTL1(lnode,NOItems[i].layid);
    end
    else if (NOItems[i].dictid=IdTimelineTL1) then
    begin
      lnode:=GetChild(NOItems[i].node,0);
      ParseTimelineTL1(lnode,NOItems[i].layid);
    end
  end;
end;

procedure TRGLayoutFile.ParseTimelineTL1(var anode:pointer; aid:Int64);
var
  lid:int64;
  tlpoint,tlprop,tldata,tlobject:pointer;
  lBinPos:PByte;
  ls,lvalue:UnicodeString;
  i,j,k,l:integer;
  lobjid,lcntvalue,lcntevent,lcntobj,lcntpoint:integer;
  isprop:boolean;
begin
  lBinPos:=SeekBinaryData(aid);
  if lBinPos=nil then
  begin
    FLog.Add('Binary data ends already for Timeline ID='+IntToStr(aid));
    exit;
  end;

  tldata:=AddGroup(anode,'TIMELINEDATA');
  AddInteger64(tldata,'ID',aid);

  lcntobj:=memReadDWord(lBinPos);
  for i:=0 to lcntobj-1 do
  begin
    tlobject:=AddGroup(tldata,'TIMELINEOBJECT');
    lid:=memReadInteger64(lBinPos);
    AddInteger64(tlobject,'OBJECTID',lid);

    lcntevent:=memReadDWord(lBinPos);
    for j:=0 to lcntevent-1 do
    begin
      {
        Object name is:"OBJECTID" as ID for FUNCTION for events, PROPERTY for props
      }
      lobjid:=memReadDWord(lBinPos);   // ID to get name
      isprop:=memReadByte (lBinPos)=0; // 0 - property, 1 - event

      if cntTLItem>=Length(TLItems) then
        SetLength(TLItems,Length(TLItems)+100);

      TLItems[cntTLItem].layid :=lid;
      TLItems[cntTLItem].propid:=lobjid;
      TLItems[cntTLItem].isprop:=isprop;

      Str(lobjid,ls);
      if isprop then
      begin
        tlprop:=AddGroup(tlobject,'TIMELINEOBJECTPROPERTY');
        TLItems[cntTLItem].nameptr:=AddString(tlprop,'OBJECTPROPERTYNAME',PWideChar(ls));
      end
      else
      begin
        tlprop:=AddGroup(tlobject,'TIMELINEOBJECTEVENT');
        TLItems[cntTLItem].nameptr:=AddString(tlprop,'OBJECTEVENTNAME',PWideChar(ls));
      end;
      inc(cntTLItem);

      lcntpoint:=memReadDWord(lBinPos);
      for k:=0 to lcntpoint-1 do
      begin
        tlpoint:=AddGroup(tlprop,'TIMELINEPOINT');
        AddFloat (tlpoint,'TIMEPERCENT'  ,memReadFloat(lBinPos));
        AddString(tlpoint,'INTERPOLATION',strInterpolation[memReadDword(lBinPos)]);
        if isprop then
        begin
          lvalue:='';
          lcntvalue:=memReadDWord(lBinPos);
          for l:=0 to lcntvalue-1 do
          begin
            Str(memReadFloat(lBinPos):0:FloatPrec,ls);
            FixFloatStr(ls);
            if lvalue<>'' then lvalue:=lvalue+',';
            lvalue:=lvalue+ls;
          end;
          AddString(tlpoint,'VALUE',PWideChar(lvalue));
        end;
      end;
    end;
  end;
end;

procedure TRGLayoutFile.ParseLogicGroupTL1(var anode:pointer; aid:Int64);
type
  TLogicObject = packed record
    id:dword;
    GUID:Int64;
    X:Single;
    Y:Single;
  end;
var
  lo:TLogicObject;
  lbuf:array [0..127] of WideChar;
  lgroup,lgobj,lglnk:pointer;
  lBinPos:PByte;
  lLinkPos:PByte;
  i,j,lcntobj,lcntlink:integer;
begin
  lBinPos:=SeekBinaryData(aid);
  if lBinPos=nil then
  begin
    FLog.Add('Binary data ends already for LogicGroup ID='+IntToStr(aid));
    exit;
  end;

  lgroup:=AddGroup(anode,'LOGICGROUP');
  lcntobj:=memReadDWord(lBinPos);
  lLinkPos:=lBinPos+lcntobj*SizeOf(TLogicObject);
  for i:=0 to lcntobj-1 do
  begin
    memReadData(lBinPos,lo,SizeOf(lo));

    lgobj:=AddGroup(lgroup,'LOGICOBJECT');
    AddUnsigned (lgobj,'ID'      ,lo.id);
    AddInteger64(lgobj,'OBJECTID',lo.GUID);
    AddFloat    (lgobj,'X'       ,lo.X);
    AddFloat    (lgobj,'Y'       ,lo.Y);

    lcntlink:=memReadDWord(lLinkPos);
    for j:=0 to lcntlink-1 do
    begin
      lglnk:=AddGroup(lgobj,'LOGICLINK');
      AddInteger(lglnk,'LINKINGTO' ,memReadDWord(lLinkPos));
      AddString (lglnk,'OUTPUTNAME',memReadDWordStringBuf(lLinkPos,@lbuf,127));
      AddString (lglnk,'INPUTNAME' ,memReadDWordStringBuf(lLinkPos,@lbuf,127));
    end;
  end;
end;

function TRGLayoutFile.DoParseBlockTL1(var anode:pointer; const aparent:Int64):integer;
var
  lChunkId:Int64;
  lparent:Int64;
  bnode,lnode:pointer;
  pname:PWideChar;
  lSavedPos:pByte;
  pcw:PWideChar;
  lChildOffset,lNextOffset,lChunkType:integer;
  lsize,i,lcnt:integer;
begin
  result:=1;

  bnode:=AddGroup(anode,'BASEOBJECT');
  lnode:=AddGroup(bnode,'PROPERTIES');

  //--- Chunk Header

  lChunkType:=memReadInteger(FPos);
  lChunkId:=memReadInteger64(FPos);
  lparent :=memReadInteger64(FPos);

  if cntNOItem>=Length(NOItems) then
    SetLength(NOItems,Length(NOItems)+100);

  NOITems[cntNOItem].layid :=lChunkId;
  NOITems[cntNOItem].dictid:=lChunkType;
  NOITems[cntNOItem].parent:=lparent;
  NOITems[cntNOItem].node  :=bnode;
  inc(cntNOItem);

  //--- Chunk Info

  pname:=info.GetObjectName(lChunkType);
  AddString(lnode,'DESCRIPTOR',pname);

  if rgDebugLevel=dlDetailed then
    FLog.Add('Object type '+IntToStr(lChunkType)+' ('+HexStr(lChunkType,2)+') '+string(pname));

  pcw:=memReadDWordString(FPos);
  if pcw<>nil then
  begin
    AddString(lnode,'NAME',pcw);
    FreeMem(pcw);
  end
  else
    AddString(lnode,'NAME',pname);

  AddInteger64(lnode,'ID'      ,lChunkId);
  AddInteger64(lnode,'PARENTID',lparent);

  //--- Properties

  for i:=0 to info.GetPropsCount()-1 do
  begin
    lsize:=memReadDWord(FPos);
    ReadPropertyValue(i,lsize*SizeOf(DWord), lnode);
    if rgDebugLevel=dlDetailed then
      FLog.Add('Property ('+IntToStr(i)+') with size '+IntToStr(lsize));
  end;

  //--- Additional data
{
  if lChunkType=IdGroupTL1 then
  begin
    lcnt:=memReadDWord(aptr); // children count
    memReadDWord(aptr); // children start
    memReadDword(aptr); // first outside group
  end

  //----- Logic group -----

   else}{ if lChunkType=IdLogicGroupTL1 then
   begin
     ParseLogicGroupTL1(lnode,lChunkId);
   end

   //----- Timeline -----

   else if lChunkType=IdTimelineTL1 then
   begin
     ParseTimelineTL1(lnode,lChunkId);
   end;
}
  //--- Children

  lcnt:=memReadDWord(FPos);
  if rgDebugLevel=dlDetailed then
    FLog.Add('Children count='+IntToStr(lcnt));

  if lChunkType=IdGroupTL1 then
  begin
    lChildOffset:=memReadDword(FPos); // offset to children
    lNextOffset :=memReadDword(FPos); // offset of next?
    lSavedPos:=FPos;
    FPos:=FStart+lChildOffset;
  end
  else
  begin
    lChildOffset:=0;
    lNextOffset :=0;
  end;

  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      inc(result,DoParseBlockTL1(lnode,lChunkId));
    end;
  end;

  //!!!!!!!!!!!!!!
  if lChildOffset<>0 then FPos:=lSavedPos;
end;

function TRGLayoutFile.DoParseLayoutTL1(atype:cardinal):pointer;
var
  qw:Int64;
  lc,lobj:pointer;
  lobjcnt,i,lcnt,ltmp:integer;
begin
  info.Version:=verTL1;

  SetLength(TLItems,0); cntTLItem:=0;
  SetLength(NOItems,0); cntNOItem:=0;
  
  qw:=memReadInteger64(FPos);
  if qw<>$B81A3A0F4348455A then
    FLog.Add('TL1 Layout signature is not B81A3A0F4348455A but'+HexStr(qw,16));
  
  result:=AddGroup(nil,ltName[ltLayout]);
  info.SelectScene(ltName[ltLayout]);

  AddInteger(result,'VERSION',3);
  lc:=AddUnsigned(result,'COUNT',0);

  lobj:=AddGroup(result,'OBJECTS');

  lcnt:=memReadDWord(FPos);     // count of Group
  if (RGDebugLevel=dlDetailed) then
    FLog.Add('Old format, groups: '+IntToStr(lcnt));

  lobjcnt:=0;
  for i:=0 to lcnt-1 do
  begin
    inc(lobjcnt,DoParseBlockTL1(lobj,-1));
  end;

  lcnt:=memReadDWord(FPos);    // count of root elements except groups
  ltmp:=memReadDWord(FPos);    // binary offset (last: id of last object, offset of itself)
  FBinStart:=FStart+ltmp;
  if ltmp<>0 then
  begin
    if (RGDebugLevel=dlDetailed) then
      FLog.Add('Binary chunk at '+HexStr(ltmp,8));
  end;

  for i:=0 to lcnt-1 do                   // lcnt is root object count
    inc(lobjcnt,DoParseBlockTL1(lobj,-1));

  PostProcess();

  ProcessTLNames();
{
  memReadDword(FPos); // this is filesize-SizeOf(dword)
}

  asUnsigned(lc,lobjcnt);

  SetLength(TLItems,0);
  SetLength(NOItems,0);
end;

function TRGLayoutFile.DoBuildLayoutTL1(anode:pointer; astream:TStream):integer;
begin
  result:=0;
end;

