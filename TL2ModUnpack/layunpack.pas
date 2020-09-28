unit layunpack;

interface

uses
  inifiles;

function DoParseLayout (buf:pByte):pointer;
function IsProperLayout(buf:pByte):boolean;
procedure ReadLayINI(aini:TINIFile);


implementation

uses
  sysutils,
  rgglobal,
  rgnode,
  rgdict,
  rgmemory,
  deglobal;

var
  dodesc:boolean;
  aliases:pointer;
  _filestart:PByte;
  buffer:WideString;
  objcount:integer;
  objInfo:pointer;
  fver:Byte;
  m00,m01,m02,m10,m11,m12,m20,m21,m22:Widestring;


function ReadStr(var aptr:PByte):PWideChar;
begin
  case fver of
//    verTL1: result:=memReadDWordString(aptr);
    verTL2: result:=memReadShortString(aptr);
    verHob,
    verRG : result:=memReadShortStringUTF8(aptr);
  else
    result:=nil;
  end;
end;

function GetStr(aid:dword):PWideChar;
var
  i:integer;
begin
  if aid=0 then exit(nil);

  result:=nil;

  result:=GetTagStr(aliases,aid);

  if result=nil then
  begin
    for i:=0 to High(dicts) do
    begin
      result:=GetTagStr(dicts[i],aid);
      if result<>nil then break;
    end;
  end;

{$IFDEF DEBUG}
if result<>nil then
begin
  if dodesc then
    laydesclog.Add(IntToStr(aid)+':'+string(WideString(result)))
  else
    laydatlog.Add(IntToStr(aid)+':'+string(WideString(result)));
end;
{$ENDIF}

  if result=nil then
  begin
    Str(aid,buffer);
    result:=pointer(buffer);

    if hashlog<>nil then
    begin
  //writeln(curfname);
      if (ftype<>3) or dodesc then
      hashlog.Add(IntToStr(aid));
      hashlog1.Add('LAY:'+IntToStr(aid));
    end;
  end;
end;

const
  IdLogicGroup = 36;
  IdTimeline   = 35;

procedure ParseLogicGroup(var anode:pointer; var aptr:pByte);
var
  lgobj,lgroup,lglnk:pointer;
  pcw:PWideChar;
  lsize:integer;
  lgroups,lglinks,i,j:integer;
begin
  lgroup:=AddGroup(anode,'LOGICGROUP');
  lgroups:=memReadByte(aptr);
  for i:=0 to lgroups-1 do
  begin
    lgobj:=AddGroup(lgroup,'LOGICOBJECT');
    AddUnsigned (lgobj,'ID'      ,memReadByte     (aptr));
    AddInteger64(lgobj,'OBJECTID',memReadInteger64(aptr));
    AddFloat    (lgobj,'X'       ,memReadFloat    (aptr));
    AddFloat    (lgobj,'Y'       ,memReadFloat    (aptr));

    lsize:=memReadInteger(aptr); // absolute offset of next

    lglinks:=memReadByte(aptr);
    for j:=0 to lglinks-1 do
    begin
      lglnk:=AddGroup(lgobj,'LOGICLINK');
      AddInteger(lglnk,'LINKINGTO' ,memReadByte(aptr));
      case fver of
        verTL2: begin
          pcw :=memReadShortString(aptr); AddString(lglnk,'OUTPUTNAME',pcw); FreeMem(pcw);
          pcw :=memReadShortString(aptr); AddString(lglnk,'INPUTNAME' ,pcw); FreeMem(pcw);
        end;
        verHob,
        verRG : begin
          AddString(lglnk,'OUTPUTNAME',GetStr(memReadDWord(aptr)));
          AddString(lglnk,'INPUTNAME' ,GetStr(memReadDWord(aptr)));
        end;
      end;
    end;
  end;
end;

procedure ParseTimeline(var anode:pointer; aid:Int64; var aptr:pByte);
var
  tlpoint,tlnode,tldata,tlobject:pointer;
  pcw:PWideChar;
  laptr:pByte;
  lint,ltlpoints,ltltype,ltlprops,ltlobjs,i,j,k:integer;
begin
  tldata:=AddGroup(anode,'TIMELINEDATA');
  AddInteger64(tldata,'ID',aid);

  ltlobjs:=memReadByte(aptr);
  for i:=0 to ltlobjs-1 do
  begin
    tlobject:=AddGroup(tldata,'TIMELINEOBJECT');
    AddInteger64(tlobject,'OBJECTID',memReadInteger64(aptr));
    
    ltlprops:=memReadByte(aptr);
    for j:=0 to ltlprops-1 do
    begin
      ltltype:=0;
      laptr:=aptr;

      // Property
      pcw:=ReadStr(aptr);
      if pcw<>nil then
      begin
        ltltype:=1;
        tlnode:=AddGroup(tlobject,'TIMELINEOBJECTPROPERTY');
        AddString(tlnode,'OBJECTPROPERTYNAME',pcw);
        FreeMem(pcw);
      end;

      // Event
      pcw:=ReadStr(aptr);
      if pcw<>nil then
      begin
        if ltltype<>0 then
        begin
if IsConsole then writeln('Double Timeline type at ',HexStr(aptr-_filestart,8));
        end;
        ltltype:=2;
        tlnode:=AddGroup(tlobject,'TIMELINEOBJECTEVENT');
        AddString(tlnode,'OBJECTEVENTNAME',pcw);
        FreeMem(pcw);
      end;

      if ltltype=0 then
      begin
if IsConsole then writeln('Unknown Timeline type at ',HexStr(laptr-_filestart,8));
        tlnode:=AddGroup(tlobject,'??TIMELINEUNKNOWN');
      end;

      ltlpoints:=memReadByte(aptr);
      for k:=0 to ltlpoints-1 do
      begin
//writeln('point ',k);
        tlpoint:=AddGroup(tlnode,'TIMELINEPOINT');
        AddFloat(tlpoint,'TIMEPERCENT',memReadFloat(aptr));

        lint:=memReadByte(aptr);
        case lint of
          0: pcw:='Linear';
          1: pcw:='Linear Round';
          2: pcw:='Linear Round Down';
          3: pcw:='Linear Round Up';
          4: pcw:='No interpolation';
          5: pcw:='Quaternion';
          6: pcw:='Spline';
        else
          pcw:=Pointer(WideString(IntToStr(lint)));
        end;
        AddString(tlpoint,'INTERPOLATION',pcw);

        if fver=verTL2 then
        begin
          if ltltype=1 then
          begin
            pcw:=memReadShortString(aptr);
//writeln('point value ',string(widestring(pcw)));
            AddString(tlpoint,'VALUE',pcw);
            FreeMem(pcw);
          end;
        end;

        if (fver=verHob) or (fver=verRG) then
        begin
          pcw:=memReadShortStringUTF8(aptr);
          if pcw<>nil then
          begin
            ltltype:=1;
            AddString(tlpoint,'VALUE_1',pcw);
            FreeMem(pcw);
          end;

          if (ltltype=0) or (ltltype=1) then
          begin
            pcw:=memReadShortStringUTF8(aptr);
            if pcw<>nil then
            begin
              ltltype:=1;
              AddString(tlpoint,'VALUE',pcw);
              FreeMem(pcw);
            end;
          end;
          if ltltype=2 then
          begin
          end;
        end;

      end;
    end;
  end;
end;

procedure ReadPropertyTL2(var anode:pointer; aobj:pointer; var aptr:pByte);
var
  lptr:pByte;
  pcw,lname:PWideChar;
  ltype,lsize:integer;
begin
  lsize:=memReadWord(aptr);
  if lsize=0 then exit;
  lptr:=aptr;
  ltype:=memReadByte(aptr);

  case GetObjectProperty(aobj,ltype,lname) of
    rgBool     : AddBool     (anode,lname,memReadInteger  (aptr)<>0);
    rgInteger  : AddInteger  (anode,lname,memReadInteger  (aptr));
    rgUnsigned : AddUnsigned (anode,lname,memReadDWord    (aptr));
    rgFloat    : AddFloat    (anode,lname,memReadFloat    (aptr));
    rgInteger64: AddInteger64(anode,lname,memReadInteger64(aptr));
    rgString: begin
	    pcw:=memReadShortString(aptr);
	    AddString(anode,lname,pcw);
	    FreeMem(pcw);
    end;
    rgVector2: begin
      AddFloat(anode,PWideChar(WideString(lname)+'X'),memReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Y'),memReadFloat(aptr));
    end;
    rgVector3: begin
      AddFloat(anode,PWideChar(WideString(lname)+'X'),memReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Y'),memReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Z'),memReadFloat(aptr));
    end;
    // Quaternion
    rgVector4: begin
      AddFloat(anode,PWideChar(WideString(lname)+'X'),memReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Y'),memReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'Z'),memReadFloat(aptr));
      AddFloat(anode,PWideChar(WideString(lname)+'W'),memReadFloat(aptr));
    end;
  else
    AddInteger(anode,'??UNKNOWN',lsize-4);
    AddString (anode,PWideChar('??'+WideString(lname)),
            PWideChar(WideString(HexStr(aptr-_filestart,8))));
if IsConsole then writeln(HexStr(lptr-_filestart,8),': prop type ',ltype,' size ',lsize);
  end;

  aptr:=lptr+lsize;
end;

procedure ReadPropertyHob(var anode:pointer; var aptr:pByte);
var
  lmatrix:TMatrix4x4;
  lq:TVector4;
  pcw,lname:PWideChar;
  lptr:pByte;
  lsize,llen:integer;
  ldw:dword;
begin
  lsize:=memReadWord(aptr);
  if lsize=0 then exit;
//writeln('prop ',i+1,'/',lcnt,' size ',llsize,' at ',HexStr(aptr-_filestart,8));
  lptr:=aptr;

  lname:=GetStr(memReadDWord(aptr));

  //!!!! We don't have type info atm so trying to guess
  
  // standard: boolean, unsigned, integer, float
  if lsize=8 then
  begin
    ldw:=memReadDWord(aptr);
    //!! can be boolean - we can't get difference
    if ldw in [0,1] then
      AddInteger(anode,lname,integer(ldw))
    else if (ldw shr 24) in [0,$FF] then
      AddInteger(anode,lname,integer(ldw))
    else
    begin
      try
        AddFloat(anode,lname,psingle(@ldw)^);
      except
        AddInteger(anode,lname,integer(ldw));
      end;
    end;
  end
  else
  begin
    //!!
    if lsize<4 then
    begin
      AddInteger(anode,'??UNKNOWNSMALL',lsize);
      AddString (anode,'??UNKNADDR'    ,
          PWideChar(WideString(HexStr(aptr-_filestart,8))));
    end
    else
    begin
      llen:=memReadWord(aptr);
      dec(aptr,2);

      // text
      if llen=lsize-6 then
      begin
        pcw:=memReadShortStringUTF8(aptr);
        AddString(anode,lname,pcw);
        FreeMem(pcw);
      end

      // id OR Vector2
      else if lsize=12 then
      begin
        AddInteger64(anode,lname,memReadInteger64(aptr));
      end

      // Vector3
      else if lsize=16 then
      begin
        AddFloat(anode,PWideChar(WideString(lname)+'X'),memReadFloat(aptr));
        AddFloat(anode,PWideChar(WideString(lname)+'Y'),memReadFloat(aptr));
        AddFloat(anode,PWideChar(WideString(lname)+'Z'),memReadFloat(aptr));
      end

      // Vector4
      else if lsize=20 then
      begin
        lq.X:=memReadFloat(aptr); AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
        lq.Y:=memReadFloat(aptr); AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
        lq.Z:=memReadFloat(aptr); AddFloat(anode,PWideChar(WideString(lname)+'Z'),lq.Z);
        lq.W:=memReadFloat(aptr); AddFloat(anode,PWideChar(WideString(lname)+'W'),lq.W);

        //!!!!
        if CompareWide(lname,'ORIENTATION') then
        begin
           QuaternionToMatrix(lq,lmatrix);
           if lmatrix[2,0]<>0 then AddFloat(anode,pointer(m20){'FORWARDX'},lmatrix[2,0]);
           if lmatrix[1,0]<>0 then AddFloat(anode,pointer(m10){'FORWARDY'},lmatrix[1,0]);
           if lmatrix[0,0]<>0 then AddFloat(anode,pointer(m00){'FORWARDZ'},lmatrix[0,0]);
           if lmatrix[2,1]<>0 then AddFloat(anode,pointer(m21){'UPX'     },lmatrix[2,1]);
           if lmatrix[1,1]<>0 then AddFloat(anode,pointer(m11){'UPY'     },lmatrix[1,1]);
           if lmatrix[0,1]<>0 then AddFloat(anode,pointer(m01){'UPZ'     },lmatrix[0,1]);
           if lmatrix[2,2]<>0 then AddFloat(anode,pointer(m22){'RIGHTX'  },lmatrix[2,2]);
           if lmatrix[1,2]<>0 then AddFloat(anode,pointer(m12){'RIGHTY'  },lmatrix[1,2]);
           if lmatrix[0,2]<>0 then AddFloat(anode,pointer(m02){'RIGHTZ'  },lmatrix[0,2]);
        end;
      end

      //!! unknown
      else
      begin
        AddInteger(anode,'??UNKNOWN',lsize-4);
        AddString (anode,PWideChar('??'+WideString(lname)),
            PWideChar(WideString(HexStr(aptr-_filestart,8))));
      end;
    end
  end;

  aptr:=lptr+lsize;
end;

//--- TL1
(*
procedure DoParseBlockTL1(var anode:pointer; var aptr:pByte; const aparent:Int64);
var
  lChunkId:Int64;
  lparent:Int64;
  lptr:pByte;
  pcw:PWideChar;
begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');
  lptr:=aptr;
  
{
  //--- Chunk Header

  lChunkSize:=ReadInteger(aptr);
//  if lChunkSize=0 then exit;
  lChunkType:=ReadByte(aptr);
}
  lChunkId:=ReadInteger64(aptr);
  lparent :=ReadInteger64(aptr);

  //--- Chunk Info

{
  lname:=GetStr(lChunkHash);
  AddText(lnode,'DESCRIPTOR',lname,ntString);
}
  AddInteger64(lnode,'ID',lChunkId);
  pcw:=ReadDWordString(aptr);
  if pcw<>nil then
  begin
    AddText(lnode,'NAME',pcw,ntString);
    FreeMem(pcw);
  end
  else
    AddText(lnode,'NAME',lname,ntString);

  AddInteger64(lnode,'PARENTID',lparent);

  //--- Properties

  lcnt:=ReadDWord(aptr);
  for i:=0 to lcnt-1 do
    ReadDword(aptr);

  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  // ALL#0
  inc(aptr,8);
  ReadDWord(aptr); // 1
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);

  ReadDWord(aptr); // 5
  // CLASS:DESTROYER#0
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 2
  ReadDWord(aptr);
  ReadDWord(aptr);
  ReadDWord(aptr); // 1
  ReadDWord(aptr); // children offset
  ReadDWord(aptr); // next "children" (other object) offset

  ReadDWord(aptr); // 0 = tag Group?
{
  lcnt:=ReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyTL1(lnode,lobj,aptr);
  end;
}
  //--- Additional data

  //--- Children


  lcnt:=ReadWord(aptr);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      DoParseBlockTL2(lnode,aptr,lChunkId);
    end;
  end;

  aptr:=lptr+lChunkSize;
end;
*)
//--- TL2

procedure DoParseBlockTL2(var anode:pointer; var aptr:pByte; const aparent:Int64);
var
  bnode,lobj,lnode:pointer;
  lptr:pbyte;
  pname,pcw:PWideChar;

  lChunkSize:integer;
  lChunkType:byte;
  lChunkId  :Int64;

  lsize,i,lcnt:integer;

begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');
  lptr:=aptr;

  //--- Chunk Header

  lChunkSize:=memReadInteger(aptr);
//  if lChunkSize=0 then exit;
  lChunkType:=memReadByte(aptr);
  lChunkId  :=memReadInteger64(aptr);

  //--- Chunk Info

  lobj:=SelectObject(objInfo,lChunkType);
  pname:=GetObjectName(lobj);

  AddString(lnode,'DESCRIPTOR',pname);
  pcw:=memReadShortString(aptr);
  if pcw<>nil then
  begin
    AddString(lnode,'NAME',pcw);
    FreeMem(pcw);
  end
  else
    AddString(lnode,'NAME',pname);
  AddInteger64(lnode,'PARENTID',aparent);
  AddInteger64(lnode,'ID',lChunkId);

  //--- Properties

  lcnt:=memReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyTL2(lnode,lobj,aptr);
  end;

  //--- Additional data

  lsize:=memReadInteger(aptr);
  if lsize>0 then
  begin

    //----- Timeline -----

    if lChunkType=IdTimeline then
    begin
      ParseTimeline(lnode,lChunkId,aptr);
    end

    //----- Logic group -----

    else if lChunkType = idLogicGroup then
    begin
      ParseLogicGroup(lnode,aptr);
    end;

  end;

  //--- Children

  lcnt:=memReadWord(aptr);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
      DoParseBlockTL2(lnode,aptr,lChunkId);
    end;
  end;

  aptr:=lptr+lChunkSize;
end;

//--- Hob

procedure DoParseBlockHob(var anode:pointer; var aptr:pByte; const aparent:Int64);
var
  bnode,lnode:pointer;
//  laptr:pByte;
  llptr,lptr:pByte;
  lname,pcw:PWideChar;

  lChunkSize:integer;
  lChunkHash:dword;
  lChunkId  :Int64;

  i,lsize,lcnt:integer;

begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');

  lptr:=aptr;

  //--- Chunk Header

  lChunkSize:=memReadDWord(aptr);
  if lChunkSize=0 then exit;

  lChunkHash:=memReadDWord(aptr);
  lChunkId  :=memReadInteger64(aptr);

  //--- Chunk Info

  dodesc:=true;
  lname:=GetStr(lChunkHash);
  dodesc:=false;
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

  lcnt:=memReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    ReadPropertyHob(lnode,aptr);
  end;

  //--- Additional data

  lsize:=memReadInteger(aptr);
  llptr:=aptr;
  if lsize>0 then
  begin

    //----- Logic group -----

    if lChunkHash=2261606130 then
    begin
      ParseLogicGroup(lnode,aptr);
    end

    //----- Timeline -----

    else if lChunkHash=2623981599 then
    begin
      ParseTimeline(lnode,lChunkId,aptr);
    end

    //----- Unknown additional data -----

    else
    begin
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
      DoParseBlockHob(lnode,aptr,lChunkId);
    end;
  end;

  aptr:=lptr+lChunkSize;
end;

function DoParseLayout(buf:pByte):pointer;
var
  pcw:PWideChar;
  ls:string;
  lobj,lc:pointer;
  lptr:pByte;
  ldata,i,lcnt,llayver:integer;
  b1,b2,b3:boolean;
begin
  result:=nil;

  dodesc:=false;
  _filestart:=buf;
  lptr:=buf;

  fver:=memReadByte(lptr);
  if fver=$5A then
  begin
    inc(lptr,7);
  end;

  case fver of
    5  : fver:=verRG;
    8  : fver:=verHob;
    11 : fver:=verTL2;
    $5A: fver:=verTL1;
  else
    exit;
  end;

  //--- TL1 ---

  if fver=verTL1 then
  begin
{
    result:=AddGroup(nil,'Layout');

    //??
    lcnt:=ReadDWord(lptr);
    if lcnt=0 then lcnt:=ReadDWord(lptr);

    AddUnsigned(result,'COUNT',lcnt);
    ReadDWord(lptr);                     // offset

    lobj:=AddGroup(result,'OBJECTS');
    for i:=0 to lcnt-1 do
      DoParseBlockTL1(lobj,lptr,-1);
}
  end;

  //--- TL2 ---

  if fver=verTL2 then
  begin
    ls:=UpCase(curfname);
    if      pos('MEDIA\UI'       ,ls)>0 then pcw:='UI'
    else if pos('MEDIA\Particles',ls)>0 then pcw:='Particle Creator'
    else pcw:='Layout';
    
    result:=AddGroup(nil,pcw);
    llayver:=memReadByte(lptr);             // Layout version
    AddInteger(result,'VERSION',llayver);

    objcount:=0;
    lc:=AddUnsigned(result,'COUNT',0);
    memReadDWord(lptr);                     // offset

    lobj:=AddGroup(result,'OBJECTS');
    lcnt:=memReadWord (lptr);               // root baseobject count
    for i:=0 to lcnt-1 do
      DoParseBlockTL2(lobj,lptr,-1);

//    lc:=AddUnsigned(result,'COUNT',objcount);
    asUnsigned(lc,objcount);
  end;

  //--- Hob ---

  if fver=verHob then
  begin
    inc(lptr);

    result:=AddGroup(nil,'Layout');
    lcnt:=memReadDWord(lptr);
    AddUnsigned(result,'COUNT',lcnt);
    memReadDword(lptr);                // offset

    memReadByte(lptr);                 // 1
    pcw:=memReadShortStringUTF8(lptr); // LEVEL
    AddString(result,'TYPE',pcw);
    FreeMem(pcw);
    inc(lptr);                      // 0
    inc(lptr);                      // 4
    ldata:=memReadDWord(lptr);         // absolute offset to data
    pcw:=memReadShortString(lptr);
    if pcw<>nil then
    begin
      AddString(result,'BASE',pcw);
      FreeMem(pcw);
    end;
    inc(lptr,6*SizeOf(single));   // 6*4
    b1:=memReadByte(lptr)<>0;          // 1 usually
    b2:=memReadByte(lptr)<>0;          // 0 usually but can be a 1
    b3:=memReadByte(lptr)<>0;          // 0 usually

    if b2 then
    begin
      pcw:=memReadShortStringUTF8(lptr);
      AddString(result,'LAYOUT_TITLE',pcw);
      FreeMem(pcw);
      AddInteger64(result,'LAYOUT_ID',memReadInteger64(lptr));
    end;

    lptr:=_filestart+ldata;

    lobj:=AddGroup(result,'OBJECTS');
    lcnt:=memReadWord (lptr);
    for i:=0 to lcnt-1 do
      DoParseBlockHob(lobj,lptr,-1);
  end;

  //--- RG ---
  if fver=verRG then
  begin
    inc(lptr);
    memReadDWord(lptr);
    inc(lptr);
    result:=AddGroup(nil,'Layout');
    lcnt:=memReadWord(lptr);
    AddUnsigned(result,'COUNT',lcnt);
    lobj:=AddGroup(result,'OBJECTS');
    for i:=0 to lcnt-1 do
      DoParseBlockHob(lobj,lptr,-1);
  end;
end;

function IsProperLayout(buf:pByte):boolean;
begin
  result:=buf^ in [5, 8, 11, $5A];
end;

procedure ReadLayINI(aini:TINIFile);
begin
  m00:=aini.ReadString('matrix_xy','00','RIGHTX');
  m01:=aini.ReadString('matrix_xy','01','UPX');
  m02:=aini.ReadString('matrix_xy','02','FORWARDX');
  m10:=aini.ReadString('matrix_xy','10','RIGHTY');
  m11:=aini.ReadString('matrix_xy','11','UPY');
  m12:=aini.ReadString('matrix_xy','12','FORWARDY');
  m20:=aini.ReadString('matrix_xy','20','RIGHTZ');
  m21:=aini.ReadString('matrix_xy','21','UPZ');
  m22:=aini.ReadString('matrix_xy','22','FORWARDZ');
end;

initialization

  LoadTags(aliases,'layaliases.txt');
  objInfo:=LoadObjectInfo();

finalization
  
  if aliases<>nil then FreeTags(aliases);
  if objInfo<>nil then FreeObjectInfo(objInfo);

end.
