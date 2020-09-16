unit layunpack;

interface

uses
  TL2DatNode;


function DoParseLayout(buf:pByte):PTL2Node;


implementation

uses
  sysutils,
  rgglobal,
  TL2Memory;

var
  aliases:TDict;
  tried:boolean;
  _filestart:PByte;
  buffer:WideString;
  objcount:integer;
  fver:Byte;


function GetTagStr(aid:dword):PWideChar;
var
  i:integer;
begin
  result:=nil;

  if not tried then
  begin
    tried:=true;
    LoadDictCustom(aliases,'layaliases.txt');
  end;

  if aliases<>nil then
  begin
    for i:=0 to High(aliases) do
    begin
      if aliases[i].hash=aid then
      begin
        buffer:=WideString(aliases[i].name);
        result:=pointer(buffer);
        exit;
      end;
    end;
  end;

  if dict=nil then LoadDict;
  if dict<>nil then
  begin
    for i:=0 to High(dict) do
    begin
      if dict[i].hash=aid then
      begin
        buffer:=WideString(dict[i].name);
        result:=pointer(buffer);
        exit;
      end;
    end;
  end;

  if cdict=nil then LoadDictCustom(cdict,'hashed.txt');
  if cdict<>nil then
  begin
    for i:=0 to High(cdict) do
    begin
      if cdict[i].hash=aid then
      begin
        buffer:=WideString(cdict[i].name);
        result:=pointer(buffer);
        exit;
      end;
    end;
  end;

  Str(aid,buffer);
  result:=pointer(buffer);

  if hashlog<>nil then
  begin
//writeln(curfname);
    hashlog.Add(IntToStr(aid));
  end;
end;

//--- TL2

const
  IdLogicGroup = 36;
  IdTimeline   = 35;

function GetPropInfo(aobj:PTL2Node; atype:integer; out aname:PWideChar):integer;
var
  llobj,lobj:PTL2node;
  pcw:PWideChar;
  i,j:integer;
begin
  result:=ntUnknown;
  llobj:=nil;
  for i:=0 to aobj^.childcount-1 do
  begin
    lobj:=@aobj^.children^[i];
    if (lobj^.nodetype=ntGroup) and CompareWide(lobj^.Name,'PROPERTY') then
    begin
      for j:=0 to lobj^.childcount-1 do
      begin
        if CompareWide(lobj^.children^[j].Name,'ID') then
        begin
          if lobj^.children^[j].asInteger=atype then
          begin
            llobj:=lobj;
          end;
          break;
        end;
      end;
      if llobj<>nil then
      begin
        for j:=0 to llobj^.childcount-1 do
        begin
          if CompareWide(llobj^.children^[j].Name,'NAME') then
            aname:=llobj^.children^[j].asString
          else if CompareWide(llobj^.children^[j].Name,'TYPEOFDATA') then
          begin
            pcw:=llobj^.children^[j].asString;
            if      CompareWide(pcw,'VECTOR3'         ) then result:=ntVector3
            if      CompareWide(pcw,'VECTOR2'         ) then result:=ntVector2
            if      CompareWide(pcw,'VECTOR4'         ) then result:=ntVector4
            else if CompareWide(pcw,'BOOL'            ) then result:=ntBool
            else if CompareWide(pcw,'FLOAT'           ) then result:=ntFloat
            else if CompareWide(pcw,'STRING'          ) then result:=ntString
            else if CompareWide(pcw,'UNSIGNED INTEGER') then result:=ntUnsigned
            else if CompareWide(pcw,'INT64'           ) then result:=ntInteger64
            else if CompareWide(pcw,'INTEGER'         ) then result:=ntInteger
            else
writeln('UNKNOWN PROPERTY TYPE ',string(widestring(pcw)));
          end;
        end;

        exit;
      end;
    end;
  end;
end;

function GetObjectStr(aid:integer; out aobj:PTL2Node):PWideChar;
label GotIt;
var
  sobj,gobj,lobj:PTL2Node;
  lobjs,lchilds,i,j:integer;
begin
  aobj:=nil;

  if objInfo=nil then LoadObjectInfo;

  for lobjs:=0 to objInfo^.childcount-1 do
  begin
    // for all scenes
    if objInfo^.children^[lobjs].Name='SCENE' then
    begin
      sobj:=@objInfo^.children^[lobjs];
      for lchilds:=0 to sobj^.childcount-1 do
      begin
        // for object group
        if sobj^.children^[lchilds].Name='OBJECT GROUP' then
        begin
          gobj:=@sobj^.children^[lchilds];
          
          // for all objects
          for i:=0 to gobj^.childcount-1 do
          begin
            lobj:=@gobj^.children^[i];
            // get object ID
            for j:=0 to lobj^.childcount-1 do
            begin
              if CompareWide(lobj^.children^[j].Name,'ID') then
              begin
                if lobj^.children^[j].asInteger=aid then
                begin
                  aobj:=lobj;
                  goto GotIt;
                end;
                break;
              end;
            end;
          end;

          break;
        end;
      end;
    end;
  end;

GotIt:

  if aobj<>nil then
    for i:=0 to aobj^.childcount-1 do
    begin
      if CompareWide(aobj^.children^[i].Name,'NAME') then
      begin
        result:=aobj^.children^[i].asString;
        exit;
      end;
    end;

  Str(aid,buffer);
  result:=pointer(buffer);
end;

procedure DoParseBlockTL2(var anode:PTL2Node; var aptr:pByte; const aparent:Int64);
var
  bnode,lobj,lnode:PTL2Node;
  laptr,llptr:pbyte;
  pname,pcw:PWideChar;

  ltltype:integer;

  tlnode:PTL2Node;
  tldata,tlobject,tlpoint:PTL2Node;
  ltlobjs,ltlprops,ltlpoints:integer;

  lgroup,lglnk,lgobj:PTL2Node;
  lgroups,lglinks:integer;

  lChunkSize:integer;
  lChunkType:byte;
  lChunkId  :Int64;

  lsize,i,j,k,lcnt:integer;

  lPropSize:word;
  lPropType:byte;

begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');
  llptr:=aptr;

  //--- Chunk Header

  lChunkSize:=ReadInteger(aptr);
//  if lChunkSize=0 then exit;
  lChunkType:=ReadByte(aptr);
  lChunkId  :=ReadInteger64(aptr);

  //--- Chunk Info

  pname:=GetObjectStr(lChunkType,lobj);
  AddText(lnode,'DESCRIPTOR',pname,ntString);
  pcw:=ReadShortString(aptr);
  if pcw<>nil then
  begin
    AddText(lnode,'NAME',pcw,ntString);
    FreeMem(pcw);
  end
  else
    AddText(lnode,'NAME',pname,ntString);
  AddInteger64(lnode,'PARENTID',aparent);
  AddInteger64(lnode,'ID',lChunkId);

  //--- Properties

  lcnt:=ReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    laptr:=aptr;
    lPropSize:=ReadWord(aptr);
    if lPropSize=0 then
    begin
writeln('size=0');
      break;
    end;
    lPropType:=ReadByte(aptr);
    case GetPropInfo(lobj,lPropType,pname) of
      ntBool     : AddBool     (lnode,pname,ReadInteger  (aptr)<>0);
      ntInteger  : AddInteger  (lnode,pname,ReadInteger  (aptr));
      ntUnsigned : AddUnsigned (lnode,pname,ReadDWord    (aptr));
      ntFloat    : AddFloat    (lnode,pname,ReadFloat    (aptr));
      ntDouble   : AddDouble   (lnode,pname,ReadDouble   (aptr));
      ntInteger64: AddInteger64(lnode,pname,ReadInteger64(aptr));
      ntString: begin
		    pcw:=ReadShortString(aptr);
		    AddText(lnode,pname,pcw,ntString);
		    FreeMem(pcw);
      end;
      ntVector2: begin
        AddFloat(lnode,PWideChar(WideString(pname)+'X'),ReadFloat(aptr));
        AddFloat(lnode,PWideChar(WideString(pname)+'Y'),ReadFloat(aptr));
      end;
      ntVector3: begin
        AddFloat(lnode,PWideChar(WideString(pname)+'X'),ReadFloat(aptr));
        AddFloat(lnode,PWideChar(WideString(pname)+'Y'),ReadFloat(aptr));
        AddFloat(lnode,PWideChar(WideString(pname)+'Z'),ReadFloat(aptr));
      end;
      ntVector4: begin
        AddFloat(lnode,PWideChar(WideString(pname)+'X1'),ReadFloat(aptr));
        AddFloat(lnode,PWideChar(WideString(pname)+'Y1'),ReadFloat(aptr));
        AddFloat(lnode,PWideChar(WideString(pname)+'X2'),ReadFloat(aptr));
        AddFloat(lnode,PWideChar(WideString(pname)+'Y2'),ReadFloat(aptr));
      end;
    else
writeln(HexStr(laptr-_filestart,8),' obj type ',lChunkType,'; prop type ',lPropType,' size ',lPropSize);
      inc(aptr,lPropSize-1);
    end;
  end;

  lsize:=ReadInteger(aptr);
  if lsize>0 then
  begin

    //----- Timeline -----

    if lChunkType=IdTimeline then
    begin
      tldata:=AddGroup(lnode,'TIMELINEDATA');
      AddInteger64(tldata,'ID',lChunkId);
      ltlobjs:=ReadByte(aptr);
      for i:=0 to ltlobjs-1 do
      begin
        tlobject:=AddGroup(tldata,'TIMELINEOBJECT');
        AddInteger64(tlobject,'OBJECTID',ReadInteger64(aptr));
        
        ltlprops:=ReadByte(aptr);
        for j:=0 to ltlprops-1 do
        begin
          ltltype:=0;
          laptr:=aptr;

          // Property
          pcw:=ReadShortString(aptr);
          if pcw<>nil then
          begin
            ltltype:=1;
            tlnode:=AddGroup(tlobject,'TIMELINEOBJECTPROPERTY');
            AddText(tlnode,'OBJECTPROPERTYNAME',pcw,ntString);
            FreeMem(pcw);
          end;
          // Event
          pcw:=ReadShortString(aptr);
          if pcw<>nil then
          begin
            if ltltype<>0 then
            begin
writeln('Double Timeline type at ',HexStr(aptr-_filestart,8));
            end;
            ltltype:=2;
            tlnode:=AddGroup(tlobject,'TIMELINEOBJECTEVENT');
            AddText(tlnode,'OBJECTEVENTNAME',pcw,ntString);
            FreeMem(pcw);
          end;

          if ltltype=0 then
          begin
writeln('Unknown Timeline type at ',HexStr(laptr-_filestart,8));
            continue;
          end;

          ltlpoints:=ReadByte(aptr);
          for k:=0 to ltlpoints-1 do
          begin
//writeln('point ',k);
            tlpoint:=AddGroup(tlnode,'TIMELINEPOINT');
            AddFloat(tlpoint,'TIMEPERCENT',ReadFloat(aptr));
            case ReadByte(aptr) of
              0: AddText(tlpoint,'INTERPOLATION','Linear'           ,ntString);
              1: AddText(tlpoint,'INTERPOLATION','Linear Round'     ,ntString);
              2: AddText(tlpoint,'INTERPOLATION','Linear Round Down',ntString);
              3: AddText(tlpoint,'INTERPOLATION','Linear Round Up'  ,ntString);
              4: AddText(tlpoint,'INTERPOLATION','No interpolation' ,ntString);
              5: AddText(tlpoint,'INTERPOLATION','Quaternion'       ,ntString);
              6: AddText(tlpoint,'INTERPOLATION','Spline'           ,ntString);
            end;
            if ltltype=1 then
            begin
              pcw:=ReadShortString(aptr);
//writeln('point value ',string(widestring(pcw)));
              AddText(tlpoint,'VALUE',pcw,ntString);
              FreeMem(pcw);
            end;
          end;
        end;
      end;
    end

    //----- Logic group -----

    else if lChunkType = idLogicGroup then
    begin
      lgroups:=ReadByte(aptr);
      lgroup:=AddGroup(lnode,'LOGICGROUP');
      for i:=0 to lgroups-1 do
      begin
        lgobj:=AddGroup(lgroup,'LOGICOBJECT');
        AddUnsigned (lgobj,'ID'      ,ReadByte     (aptr));
        AddInteger64(lgobj,'OBJECTID',ReadInteger64(aptr));
        AddFloat    (lgobj,'X'       ,ReadFloat    (aptr));
        AddFloat    (lgobj,'Y'       ,ReadFloat    (aptr));

        lsize:=ReadInteger(aptr); //!!

        lglinks:=ReadByte(aptr);
        for j:=0 to lglinks-1 do
        begin
          lglnk:=AddGroup(lgobj,'LOGICLINK');
          AddInteger(lglnk,'LINKINGTO',ReadByte(aptr));
          pcw :=ReadShortString(aptr); AddText(lglnk,'OUTPUTNAME',pcw,ntString); FreeMem(pcw);
          pcw :=ReadShortString(aptr); AddText(lglnk,'INPUTNAME' ,pcw,ntString); FreeMem(pcw);
        end;
      end;
    end;

  end;

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

  aptr:=llptr+lChunkSize;
end;

//--- Hob

procedure DoParseBlockHob(var anode:PTL2Node; var aptr:pByte; const aparent:Int64);
var
  bnode,lnode,tlnode:PTL2Node;
//  laptr:pByte;
  llptr,lptr:pByte;
  lname,pcw:PWideChar;

  lChunkSize:integer;
  lChunkHash:dword;
  lChunkId  :Int64;

  ldw:DWord;
  llen,i,j,k,llsize,lsize,lcnt:integer;

  tldata,tlobject,tlpoint:PTL2Node;
  ltlobjs,ltlprops,ltlpoints:integer;
  ltltype:integer;

  lgroup,lglnk,lgobj:PTL2Node;
  lgroups,lglinks:integer;

begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');

  lptr:=aptr;

  //--- Chunk Header

  lChunkSize:=ReadDWord(aptr);
  if lChunkSize=0 then exit;

  lChunkHash:=ReadDWord(aptr);
  lChunkId  :=ReadInteger64(aptr);

  //--- Chunk Info

  lname:=GetTagStr(lChunkHash);
  AddText(lnode,'DESCRIPTOR',lname,ntString);
  AddInteger64(lnode,'ID',lChunkId);
  pcw:=ReadShortStringUTF8(aptr);
  if pcw<>nil then
  begin
    AddText(lnode,'NAME',pcw,ntString);
    FreeMem(pcw);
  end
  else
    AddText(lnode,'NAME',lname,ntString);

  AddInteger64(lnode,'PARENTID',aparent);

  //--- Properties

  lcnt:=ReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    llsize:=ReadWord(aptr);
//writeln('prop ',i+1,'/',lcnt,' size ',llsize,' at ',HexStr(aptr-_filestart,8));
    llptr:=aptr;
    lname:=GetTagStr(ReadDWord(aptr));

    //!!!! We don't have type info atm so trying to guess
    
    // standard: boolean, unsigned, integer, float
    if llsize=8 then
    begin
      ldw:=ReadDWord(aptr);
      //!! can be boolean - we can't get difference
      if ldw in [0,1] then
        AddInteger(lnode,lname,integer(ldw))
      else if (ldw shr 24) in [0,$FF] then
        AddInteger(lnode,lname,integer(ldw))
      else
      begin
        try
          AddFloat(lnode,lname,psingle(@ldw)^);
        except
          AddInteger(lnode,lname,integer(ldw));
        end;
      end;
    end
    else
    begin
      //!!
      if llsize<4 then
      begin
        AddInteger(lnode,'??UNKNOWNSMALL',llsize);
        AddText   (lnode,'??UNKNADDR'    ,
            PWideChar(WideString(HexStr(aptr-_filestart,8))),ntString);
      end
      else
      begin
        llen:=ReadWord(aptr);
        dec(aptr,2);

        // text
        if llen=llsize-6 then
        begin
          pcw:=ReadShortStringUTF8(aptr);
          AddText(lnode,lname,pcw,ntString);
          FreeMem(pcw);
        end

        // id
        else if llsize=12 then
        begin
          AddInteger64(lnode,lname,ReadInteger64(aptr));
        end

        // vector
        else if llsize=16 then
        begin
          AddFloat(lnode,PWideChar(WideString(lname)+'X'),ReadFloat(aptr));
          AddFloat(lnode,PWideChar(WideString(lname)+'Y'),ReadFloat(aptr));
          AddFloat(lnode,PWideChar(WideString(lname)+'Z'),ReadFloat(aptr));
        end

        // idk really
        else if llsize=20 then
        begin
          AddFloat(lnode,PWideChar(WideString(lname)+'_1'),ReadFloat(aptr));
          AddFloat(lnode,PWideChar(WideString(lname)+'_2'),ReadFloat(aptr));
          AddFloat(lnode,PWideChar(WideString(lname)+'_3'),ReadFloat(aptr));
          AddFloat(lnode,PWideChar(WideString(lname)+'_4'),ReadFloat(aptr));
        end

        //!! unknown
        else
        begin
          AddInteger(lnode,'??UNKNOWN',llsize-4);
          AddText   (lnode,PWideChar('??'+WideString(lname)),
              PWideChar(WideString(HexStr(aptr-_filestart,8))),ntString);
        end;
      end
    end;

    aptr:=llptr+llsize;
  end;

  //--- Additional data

  llsize:=ReadInteger(aptr);
  if llsize>0 then
  begin

    //----- Logic group -----

    if lChunkHash=2261606130 then
    begin
      lgroup:=AddGroup(lnode,'LOGICGROUP');
      lgroups:=ReadByte(aptr);
      for i:=0 to lgroups-1 do
      begin
        lgobj:=AddGroup(lgroup,'LOGICOBJECT');
        AddUnsigned (lgobj,'ID'      ,ReadByte     (aptr));
        AddInteger64(lgobj,'OBJECTID',ReadInteger64(aptr));
        AddFloat    (lgobj,'X'       ,ReadFloat    (aptr));
        AddFloat    (lgobj,'Y'       ,ReadFloat    (aptr));

        lsize:=ReadInteger(aptr); // absolute offset of next

        lglinks:=ReadByte(aptr);
        for j:=0 to lglinks-1 do
        begin
          lglnk:=AddGroup(lgobj,'LOGICLINK');
          AddInteger(lglnk,'LINKINGTO' ,ReadByte(aptr));
          AddText   (lglnk,'OUTPUTNAME',GetTagStr(ReadDWord(aptr)),ntString);
          AddText   (lglnk,'INPUTNAME' ,GetTagStr(ReadDWord(aptr)),ntString);
        end;
      end;
    end

    //----- Timeline -----

    else if lChunkHash=2623981599 then
    begin
      tldata:=AddGroup(lnode,'TIMELINEDATA');
      AddInteger64(tldata,'ID',lChunkId);

      // objects
      ltlobjs:=ReadByte(aptr);
      for i:=0 to ltlobjs-1 do
      begin
        tlobject:=AddGroup(tldata,'TIMELINEOBJECT');
        AddInteger64(tlobject,'OBJECTID',ReadInteger64(aptr));

        // properties
        ltlprops:=ReadByte(aptr);
        for j:=0 to ltlprops-1 do
        begin
          ltltype:=0;
//          laptr:=aptr;

          pcw:=ReadShortStringUTF8(aptr);
          if pcw<>nil then
          begin
            ltltype:=1;
            tlnode:=AddGroup(tlobject,'TIMELINEOBJECTPROPERTY');
            AddText(tlnode,'OBJECTPROPERTYNAME',pcw,ntString);
            FreeMem(pcw);
          end;
          pcw:=ReadShortStringUTF8(aptr);
          if pcw<>nil then
          begin
            if ltltype<>0 then
            begin
            end;
            ltltype:=2;
            tlnode:=AddGroup(tlobject,'TIMELINEOBJECTEVENT');
            AddText(tlnode,'OBJECTEVENTNAME',pcw,ntString);
            FreeMem(pcw);
          end;

          if ltltype=0 then
          begin
//writeln('Unknown Timeline type in ',_filename,' at ',HexStr(laptr-_filestart,8));
            tlnode:=AddGroup(tlobject,'??TIMELINEUNKNOWN');
          end;

          ltlpoints:=ReadByte(aptr);
          for k:=0 to ltlpoints-1 do
          begin
            tlpoint:=AddGroup(tlnode,'TIMELINEPOINT');
            AddFloat(tlpoint,'TIMEPERCENT',ReadFloat(aptr));

            lcnt:=ReadByte(aptr);
            case lcnt of
              0: AddText(tlpoint,'INTERPOLATION','Linear'           ,ntString);
              1: AddText(tlpoint,'INTERPOLATION','Linear Round'     ,ntString);
              2: AddText(tlpoint,'INTERPOLATION','Linear Round Down',ntString);
              3: AddText(tlpoint,'INTERPOLATION','Linear Round Up'  ,ntString);
              4: AddText(tlpoint,'INTERPOLATION','No interpolation' ,ntString);
              5: AddText(tlpoint,'INTERPOLATION','Quaternion'       ,ntString);
              6: AddText(tlpoint,'INTERPOLATION','Spline'           ,ntString);
            else
              AddByte(tlpoint,'??CODE',lcnt);
            end;

            pcw:=ReadShortStringUTF8(aptr);
            if pcw<>nil then
            begin
              ltltype:=1;
              AddText(tlpoint,'VALUE_1',pcw,ntString);
              FreeMem(pcw);
            end;

            if (ltltype=0) or (ltltype=1) then
            begin
              pcw:=ReadShortStringUTF8(aptr);
              if pcw<>nil then
              begin
                ltltype:=1;
                AddText(tlpoint,'VALUE',pcw,ntString);
                FreeMem(pcw);
              end;
            end;
            if ltltype=2 then
            begin
            end;
          end;
        end;
      end;
    end

    //----- Unknown additional data -----

    else
    begin
    //!!
      AddText(lnode,'??ADDITIONALDATA',
          PWideChar(WideString(HexStr(aptr-_filestart,8))),ntString);
      AddInteger(lnode,'??ADDITIONALSIZE',llsize);
      inc(aptr,llsize);
    end;
  end;

  //--- Children

  lcnt:=ReadWord(aptr);
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

function DoParseLayout(buf:pByte):PTL2Node;
var
  pcw:PWideChar;
  ls:string;
  lobj,lc:PTL2Node;
  lptr:pByte;
  ldata,i,lcnt,llayver:integer;
  b1,b2,b3:boolean;
begin
  result:=nil;

  _filestart:=buf;
  lptr:=buf;

  fver:=ReadByte(lptr);
  if fver=$5A then
  begin
    inc(lptr,7);
  end;

  case fver of
    8  : fver:=verHob;
    11 : fver:=verTL2;
    $5A: fver:=verTL1;
  end;

  //--- TL2 ---

  if fver=verTL2 then
  begin
    ls:=UpCase(curfname);
    if      pos('MEDIA\UI'       ,ls)>0 then pcw:='UI'
    else if pos('MEDIA\Particles',ls)>0 then pcw:='Particle Creator'
    else pcw:='Layout';
    
    result:=AddGroup(nil,pcw);
    llayver:=ReadByte(lptr);             // Layout version
    AddInteger(result,'VERSION',llayver);

    objcount:=0;
    lc:=AddUnsigned(result,'COUNT',0);
    ReadDWord(lptr);                     // offset

    lobj:=AddGroup(result,'OBJECTS');
    lcnt:=ReadWord (lptr);               // root baseobject count
    for i:=0 to lcnt-1 do
      DoParseBlockTL2(lobj,lptr,-1);

    lc^.asUnsigned:=objcount;
  end;

  //--- Hob ---

  if fver=verHob then
  begin
    inc(lptr);

    result:=AddGroup(nil,'Layout');
    lcnt:=ReadDWord(lptr);
    AddUnsigned(result,'COUNT',lcnt);
    ReadDword(lptr);                // offset

    ReadByte(lptr);                 // 1
    pcw:=ReadShortStringUTF8(lptr); // LEVEL
    AddText(result,'TYPE',pcw,ntString);
    FreeMem(pcw);
    inc(lptr);                      // 0
    inc(lptr);                      // 4
    ldata:=ReadDWord(lptr);         // absolute offset to data
    pcw:=ReadShortString(lptr);
    if pcw<>nil then
    begin
      AddText(result,'BASE',pcw,ntString);
      FreeMem(pcw);
    end;
    inc(lptr,6*SizeOf(single));   // 6*4
    b1:=ReadByte(lptr)<>0;          // 1 usually
    b2:=ReadByte(lptr)<>0;          // 0 usually but can be a 1
    b3:=ReadByte(lptr)<>0;          // 0 usually

    if b2 then
    begin
      pcw:=ReadShortStringUTF8(lptr);
      AddText(result,'LAYOUT_TITLE',pcw,ntString);
      FreeMem(pcw);
      AddInteger64(result,'LAYOUT_ID',ReadInteger64(lptr));
    end;

    lptr:=_filestart+ldata;

    lobj:=AddGroup(result,'OBJECTS');
    lcnt:=ReadWord (lptr);
    for i:=0 to lcnt-1 do
      DoParseBlockHob(lobj,lptr,-1);
  end;
end;

initialization

  tried:=false;

end.
