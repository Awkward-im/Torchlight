{}

const
  IdLogicGroupHob = 2261606130;
  IdTimelineHob   = 2623981599;

procedure LogProperty(aname:PWideChar; aid:dword; atype:integer);
begin
  RGLog.Add('<STRING>NAME:'+aname);
  RGLog.Add('<UNSIGNED INT>ID:'+IntToStr(aid));
  RGLog.Add('<STRING>TYPEOFDATA:'+TypeToText(atype));
end;

function ReadPropertyHob(var anode:pointer; var aptr:pByte; ainfo:TRGObject):boolean;
var
  lptr:pByte;
  lhash:dword;
  lsize:integer;
begin
  result:=false;

  lsize:=memReadWord(aptr);
  if lsize=0 then exit;

  lptr:=aptr;
  lhash:=memReadDWord(aptr);

  result:=ReadPropertyValue(lhash,lsize-4, anode,aptr, ainfo);

  aptr:=lptr+lsize;
end;

procedure DoParseBlockHob(var anode:pointer; var aptr:pByte; const aparent:Int64;
        ainfo:TRGObject);
var
  lChunkId  :Int64;
  bnode,lnode:pointer;

  llptr,lptr:pByte;
  lname,pcw:PWideChar;

  lChunkSize:integer;
  lChunkType:dword;

  i,lsize,lcnt:integer;
begin
  
  bnode:=AddGroup(anode,'BASEOBJECT');
  lnode:=AddGroup(bnode,'PROPERTIES');

  lptr:=aptr;

  //--- Chunk Header

  lChunkSize:=memReadDWord(aptr);
  if lChunkSize=0 then exit;

  lChunkType:=memReadDWord(aptr);
  lChunkId  :=memReadInteger64(aptr);

  //--- Chunk Info

  lname:=ainfo.GetObjectName(lChunkType);
  if lname=nil then
    lname:=GetStr(lChunkType);

  AddString(lnode,'DESCRIPTOR',lname);
  AddInteger64(lnode,'ID',lChunkId);

  pcw:=memReadShortStringUTF8(aptr);
  if pcw<>nil then
  begin
    AddString(lnode,'NAME',pcw);
    FreeMem(pcw);
  end
  else
    AddString(lnode,'NAME',lname);

  AddInteger64(lnode,'PARENTID',aparent);

  //--- Properties

  RGLog.Reserve('Object '+lname);
  lcnt:=memReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyHob(lnode,aptr,ainfo);
  end;

  //--- Additional data

  lsize:=memReadInteger(aptr);
  llptr:=aptr;
  if lsize>0 then
  begin

    //----- Logic group -----

    if lChunkType=IdLogicGroupHob then
    begin
      ParseLogicGroup(lnode,aptr);
    end

    //----- Timeline -----

    else if lChunkType=IdTimelineHob then
    begin
try
      ParseTimeline(lnode,lChunkId,aptr);
except
end;
    end

    //----- Unknown additional data -----

    else
    begin
      RGLog.Add('Unknown chunk with size '+IntToStr(lsize)+' at '+HexStr(aptr-_filestart,8));
    //!!
      AddString(lnode,'??ADDITIONALDATA',
          PWideChar(WideString(HexStr(aptr-_filestart,8))));
      AddInteger(lnode,'??ADDITIONALSIZE',lsize);
    end;

    aptr:=llptr+lsize;
  end;

  //--- Children

  lcnt:=memReadWord(aptr);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      DoParseBlockHob(lnode,aptr,lChunkId,ainfo);
    end;
  end;

  aptr:=lptr+lChunkSize;

  RGLog.Reserve('');
end;

function DoParseLayoutHob(aptr:pointer):pointer;
var
  linfo:TRGObject;
  lptr,lobj:pointer;
  pcw:PWideChar;
  ldata,i,lcnt:integer;
  ltmp:dword;
  b1,b2,b3:boolean;
begin
  linfo.Init;
  linfo.Version:=verHob;
  
  lptr:=aptr+1;
  ltmp:=memReadByte(lptr);
  if ltmp<>0 then
    RGLog.Add('Second byte is not 0 but '+HexStr(ltmp,2));

  result:=AddGroup(nil,'Layout');
  linfo.SelectScene('Layout');

  lcnt:=memReadDWord(lptr);
  AddUnsigned(result,'COUNT',lcnt);

  ltmp:=memReadDword(lptr);                // offset
  if ltmp<>0 then
    RGLog.Add('Binary chunk at '+HexStr(ltmp,8));

  ltmp:=memReadByte(lptr);                 // 1
  if ltmp<>1 then
    RGLog.Add('Byte after binary offset is not 1 but '+IntToStr(ltmp));

  pcw:=memReadShortStringUTF8(lptr);       // LEVEL
  AddString(result,'TYPE',pcw);
  if CompareWide(pcw,'LEVEL')<>0 then
    RGLog.Add('Type is not LEVEL but '+pcw);
  FreeMem(pcw);

  ltmp:=memReadByte(lptr);                 // 0
  if ltmp<>0 then
    RGLog.Add('Byte after type is not 0 but '+IntToStr(ltmp));
  ltmp:=memReadByte(lptr);                 // 4
  if ltmp<>4 then
    RGLog.Add('Byte before main data offset is not 4 but '+IntToStr(ltmp));

  ldata:=memReadDWord(lptr);               // absolute offset to data
  pcw:=memReadShortString(lptr);
  if pcw<>nil then
  begin
    AddString(result,'BASE',pcw);
    FreeMem(pcw);
  end;

  // 2 vector3 or 3 vector2
  AddFloat(result,'X1',memReadFloat(lptr));
  AddFloat(result,'Y1',memReadFloat(lptr));
  AddFloat(result,'Z1',memReadFloat(lptr));
  AddFloat(result,'X2',memReadFloat(lptr));
  AddFloat(result,'Y2',memReadFloat(lptr));
  AddFloat(result,'Z2',memReadFloat(lptr));
  
  ltmp:=memReadByte(lptr);                 // 1 usually
  b1:=ltmp<>0;
  if ltmp<>1 then
    RGLog.Add('Byte (1 of 3) is not 1 but '+IntToStr(ltmp));
  ltmp:=memReadByte(lptr);                 // 0 usually but can be a 1
  b2:=ltmp<>0;
  if (ltmp<>0) and (ltmp<>1) then          // is it posible?!
    RGLog.Add('Byte (2 of 3) is not 0 or 1 but '+IntToStr(ltmp));
  ltmp:=memReadByte(lptr);                 // 0 usually
  b3:=ltmp<>0;
  if ltmp<>0 then
    RGLog.Add('Byte (3 of 3) is not 0 but '+IntToStr(ltmp));

  if b2 then
  begin
    pcw:=memReadShortStringUTF8(lptr);
    AddString(result,'LAYOUT_TITLE',pcw);
    FreeMem(pcw);
    AddInteger64(result,'LAYOUT_ID',memReadInteger64(lptr));
  end;

  lptr:=_filestart+ldata;

  lcnt:=memReadWord(lptr);

  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    DoParseBlockHob(lobj,lptr,-1,linfo);

  linfo.Clear;
end;

function DoParseLayoutRG(aptr:pointer):pointer;
var
  linfo:TRGObject;
  lptr,lobj:pointer;
  i,lcnt:integer;
begin
  linfo.Init;
  linfo.Version:=verRG;

  lptr:=aptr+1;
  i:=memReadByte(lptr);
  if i<>0 then
    RGLog.Add('Second byte is not 0 but '+HexStr(i,2));

  memReadDWord(lptr);
  inc(lptr);
  result:=AddGroup(nil,'Layout');
  linfo.SelectScene('Layout');

  lcnt:=memReadWord(lptr);
  AddUnsigned(result,'COUNT',lcnt);

  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    DoParseBlockHob(lobj,lptr,-1,linfo);

  linfo.Clear;
end;
