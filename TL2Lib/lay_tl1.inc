{}

function DoParseBlockTL1(var anode:pointer; var aptr:pByte; const aparent:Int64;
        var ainfo:TRGObject):integer;
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
  lptr:=aptr;
  
  //--- Chunk Header

  lChunkType:=memReadInteger(aptr);
  lChunkId:=memReadInteger64(aptr);
  lparent :=memReadInteger64(aptr);

  //--- Chunk Info

  pname:=ainfo.GetObjectName(lChunkType);
  AddString(lnode,'DESCRIPTOR',pname);
  RGLog.Add('Object type '+IntToStr(lChunkType)+' ('+HexStr(lChunkType,2)+') '+pname);

  pcw:=memReadDWordString(aptr);
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
//exit;

  for i:=0 to ainfo.GetPropsCount()-1 do
  begin
    lsize:=memReadDWord(aptr);
    ReadPropertyValue(i,lsize*SizeOf(DWord), lnode,aptr, ainfo);
    RGLog.Add('Property ('+IntToStr(i)+') with size '+IntToStr(lsize));
  end;

  //--- Additional data

  //--- Children

  lcnt:=memReadDWord(aptr);
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
RGLog.Add('From '+HexStr(memReadDWord(aptr),4)+' to '+HexStr(memReadDWord(aptr),4));
//      inc(result,DoParseBlockTL1(lnode,aptr,lChunkId,ainfo));
    end;
  end;

end;

function DoParseLayoutTL1(aptr:pointer):pointer;
var
  qw:Int64;
  linfo:TRGObject;
  lc,lptr,lobj:pointer;
  lobjcnt,i,lcnt:integer;
begin
  linfo.Init;
  linfo.Version:=verTL1;

  lptr:=aptr;
  qw:=memReadInteger64(lptr);
  if qw<>$B81A3A0F4348455A then
    RGLog.Add('TL1 Layout signature is not B81A3A0F4348455A but'+HexStr(qw,16));
  
  result:=AddGroup(nil,'Layout');
  linfo.SelectScene('Layout');

  AddInteger(result,'VERSION',3);
  lc:=AddUnsigned(result,'COUNT',0);

  lcnt:=memReadDWord(lptr);
  if lcnt=0 then
  begin
    lcnt:=memReadDWord(lptr);
    memReadDWord(lptr);                     // offset
  end;
//  AddUnsigned(result,'COUNT',lcnt);         //!!!! like TL2 - must be TOTAL objects

  lobjcnt:=0;
  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do                   // lcnt is root object count
    inc(lobjcnt,DoParseBlockTL1(lobj,lptr,-1,linfo));

{
  memReadDword(lptr); // this is filesize-SizeOf(dword)
}

  asUnsigned(lc,lobjcnt);

  linfo.Clear;
end;
