{}

const
  IdLogicGroupTL2 = 36;
  IdTimelineTL2   = 35;

procedure ReadPropertyTL2(var anode:pointer; var aptr:pByte; var ainfo:TRGObject);
var
  lptr:pByte;
  ltype,lsize:integer;
begin
  lsize:=memReadWord(aptr);
  if lsize=0 then exit;

  lptr:=aptr;
  ltype:=memReadByte(aptr);

  ReadPropertyValue(ltype,lsize-1, anode,aptr, ainfo);

  aptr:=lptr+lsize;
end;

function DoParseBlockTL2(var anode:pointer; var aptr:pByte; const aparent:Int64;
    var ainfo:TRGObject):integer;
var
  lbuf:WideString;
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

  bnode:=AddGroup(anode,'BASEOBJECT');
  lnode:=AddGroup(bnode,'PROPERTIES');
  lptr:=aptr;

  //--- Chunk Header

  lChunkSize:=memReadInteger(aptr);
//  if lChunkSize=0 then exit;
  lChunkType:=memReadByte(aptr);
  lChunkId  :=memReadInteger64(aptr);

  //--- Chunk Info

  lname:=ainfo.GetObjectName(lChunkType);
  if lname=nil then
  begin
    Str(lChunkType,lbuf);
    lname:=PWideChar(lbuf);
  end;

  AddString(lnode,'DESCRIPTOR',lname);
  pcw:=memReadShortString(aptr);
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

  lcnt:=memReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyTL2(lnode,aptr,ainfo);
  end;

  //--- Additional data

  lsize:=memReadInteger(aptr);
  llptr:=aptr;
  if lsize>0 then
  begin

    //----- Timeline -----

    if lChunkType=IdTimelineTL2 then
    begin
      ParseTimeline(lnode,lChunkId,aptr);
    end

    //----- Logic group -----

    else if lChunkType = IdLogicGroupTL2 then
    begin
      ParseLogicGroup(lnode,aptr);
    end

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
      inc(result,DoParseBlockTL2(lnode,aptr,lChunkId,ainfo));
    end;
  end;

  aptr:=lptr+lChunkSize;
end;

function DoParseLayoutTL2(aptr:pointer; fname:string=''):pointer;
var
  ls:string;
  linfo:TRGObject;
  lptr,lobj,lc:pointer;
  pcw:PWideChar;
  i,lcnt,lver,lobjcnt:integer;
  ltmp:dword;
begin
  linfo.Init;
  linfo.Version:=verTL2;

  lptr:=aptr+1;
  
  pcw:='Layout';
  if fname<>'' then
  begin
    ls:=UpCase(fname);
    if      (pos('MEDIA\UI'       ,ls)>0) or (pos('MEDIA/UI'       ,ls)>0) then pcw:='UI'
    else if (pos('MEDIA\Particles',ls)>0) or (pos('MEDIA/Particles',ls)>0) then pcw:='Particle Creator'
  end;
  result:=AddGroup(nil,pcw);
  linfo.SelectScene(pcw);

  lver:=memReadByte(lptr);               // Layout version
  AddInteger(result,'VERSION',lver);
  if lver<>4 then
    RGLog.Add('Layout version is not 4 but '+HexStr(lver,2));

  lc:=AddUnsigned(result,'COUNT',0);
  ltmp:=memReadDWord(lptr);              // offset
  if ltmp<>0 then
    RGLog.Add('Binary chunk at '+HexStr(ltmp,8));

  lcnt:=memReadWord(lptr);               // root baseobject count

  lobjcnt:=0;
  lobj:=AddGroup(result,'OBJECTS');
  for i:=0 to lcnt-1 do
    inc(lobjcnt,DoParseBlockTL2(lobj,lptr,-1,linfo));

  asUnsigned(lc,lobjcnt);

  linfo.Clear;
end;
