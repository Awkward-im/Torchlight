{}

function TRGLayoutFile.DoParseBlockTL1(var anode:pointer; const aparent:Int64):integer;
var
  lChunkId:Int64;
  lparent:Int64;
  bnode,lnode:pointer;
  pname:PWideChar;
  lptr:pByte;
  pcw:PWideChar;
  lChunkType:integer;
  lsize,i,lcnt:integer;
begin
  result:=1;

  bnode:=AddGroup(anode,'BASEOBJECT');
  lnode:=AddGroup(bnode,'PROPERTIES');
  lptr:=FPos;
  
  //--- Chunk Header

  lChunkType:=memReadInteger(FPos);
  lChunkId:=memReadInteger64(FPos);
  lparent :=memReadInteger64(FPos);

  //--- Chunk Info

  pname:=info.GetObjectName(lChunkType);
  AddString(lnode,'DESCRIPTOR',pname);

  RGLog.Add('Object type '+IntToStr(lChunkType)+' ('+HexStr(lChunkType,2)+') '+string(pname));

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
    RGLog.Add('Property ('+IntToStr(i)+') with size '+IntToStr(lsize));
  end;

  //--- Additional data

  //--- Children

  lcnt:=memReadDWord(FPos);
  RGLog.Add('Children count='+IntToStr(lcnt));
  if lcnt>0 then
  begin
{
    4 = child absolute binary data offset
    4 = next child (from 2nd object) offset ?
    if one = points to parent ID
}
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
RGLog.Add('From '+HexStr(memReadDWord(FPos),4)+' to '+HexStr(memReadDWord(FPos),4));
//      inc(result,DoParseBlockTL1(lnode,lChunkId));
    end;
  end;

end;

function TRGLayoutFile.DoParseLayoutTL1(atype:cardinal):pointer;
var
  qw:Int64;
  lc,lobj:pointer;
  lobjcnt,i,lcnt:integer;
begin
  info.Version:=verTL1;

  qw:=memReadInteger64(FPos);
  if qw<>$B81A3A0F4348455A then
    RGLog.Add('TL1 Layout signature is not B81A3A0F4348455A but'+HexStr(qw,16));
  
  result:=AddGroup(nil,ltName[ltLayout]);
  info.SelectScene(ltName[ltLayout]);

  AddInteger(result,'VERSION',3);
  lc:=AddUnsigned(result,'COUNT',0);

  lcnt:=memReadDWord(FPos);
  if lcnt=0 then
  begin
    lcnt:=memReadDWord(FPos);
    memReadDWord(FPos);                     // offset
  end;
//  AddUnsigned(result,'COUNT',lcnt);         //!!!! like TL2 - must be TOTAL objects

  lobjcnt:=0;
  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do                   // lcnt is root object count
    inc(lobjcnt,DoParseBlockTL1(lobj,-1));

{
  memReadDword(FPos); // this is filesize-SizeOf(dword)
}

  asUnsigned(lc,lobjcnt);
end;

function TRGLayoutFile.DoBuildLayoutTL1(anode:pointer; astream:TStream):integer;
begin
  result:=0;
end;

