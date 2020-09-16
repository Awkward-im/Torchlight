{$I-}

uses
  sysutils,
  classes,
  TL2DatNode,
  TL2Types,
  TL2Memory;

type
  TAttribute = (
      t_unknown,t_integer,t_float,t_double,t_unsigned_int,
      t_string,t_bool,t_integer64,t_translate);

const
  IdLogicGroup = 36;
  IdTimeline   = 35;

type
  TLayChunkHeader = record
    asize:integer; // including size
    atype:integer; // object type
    id   :int64;
  end;
  TLaySubChunkHeader = record
    asize:word;   // excluding size
    atype:byte;   // tag type
  end;

var slglob:TStringList;

var
  dict:array of record hash:dword; name:string end;
var
  slout,otags,tags,ctags:PTL2Node;
  numbuffer:array [0..31] of WideChar;
  strbuf:wideString;
  _filestart:pbyte;
  _filename:string;
  objcount:integer;
  lver:byte;

function ReadString(var aptr:PByte):PWideChar;
begin
  if lver=11 then
    result:=ReadShortString(aptr)
  else // if lver=8 then
    result:=ReadShortStringUtf8(aptr);
end;

function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);
  repeat
    if s1^<>s2^ then exit(false);
    if s1^=#0 then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;

function GetTagStr(aid:integer):PWideChar;
var
  lsw:WideString;
  i:integer;
begin
  if dict<>nil then
  begin
    for i:=0 to High(dict) do
    begin
      if dict[i].hash=dword(aid) then
      begin
        strbuf:=WideString(dict[i].name);
        result:=pointer(strbuf);
        exit;
      end;
    end;
  end
  else if tags<>nil then
  begin
    i:=1;
    while i<tags^.childcount do
    begin
      if tags^.children^[i].asInteger=aid then
      begin
        result:=tags^.children^[i-1].asString;
        exit;
      end;
      inc(i,2);
    end;
  end;

  if ctags<>nil then
  begin
    i:=1;
    while i<ctags^.childcount do
    begin
      if ctags^.children^[i].asInteger=aid then
      begin
        result:=ctags^.children^[i-1].asString;
        exit;
      end;
      inc(i,2);
    end;
  end;
  
  if dict<>nil then
    Str(dword(aid),lsw)
  else
    Str(aid,lsw);
  numbuffer:=lsw;
  result:=@numbuffer;
slglob.Add(IntToStr(dword(aid)));
end;

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
            if      CompareWide(pcw,'VECTOR3'         ) then result:=ntVector
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
  lsw:WideString;
  lobjs,lchilds,i,j:integer;
begin
  aobj:=nil;

  for lobjs:=0 to otags^.childcount-1 do
  begin
    // for all scenes
    if otags^.children^[lobjs].Name='SCENE' then
    begin
      sobj:=@otags^.children^[lobjs];
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

  Str(aid,lsw);
  numbuffer:=lsw;
  result:=@numbuffer;
end;


procedure DoParseBlockTL2(var anode:PTL2Node; var aptr:pByte; const aparent:Int64);
var
  bnode,lobj,lnode:PTL2Node;

  ltltype:integer;
  tlnode:PTL2Node;

  tldata,tlobject,tlpoint:PTL2Node;
  ltlobjs,ltlprops,ltlpoints:integer;

  lgroup,lglnk,lgobj:PTL2Node;
  lgroups,lglinks:integer;

  ch :TLayChunkHeader;
  sch:TLaySubChunkHeader;
  pname,pcw:PWideChar;
  lsize,i,j,k,lcnt:integer;

  laptr,llptr:pbyte;
begin
  bnode:=AddGroup(anode,'BASEOBJECT');
  inc(objcount);
  lnode:=AddGroup(bnode,'PROPERTIES');
  llptr:=aptr;
  ch.asize:=ReadInteger(aptr);
  ch.atype:=ReadByte(aptr);
  ch.id   :=ReadInteger64(aptr);
  pname:=GetObjectStr(ch.atype,lobj);
  AddText(lnode,'DESCRIPTOR',pname,ntString);
  pcw:=ReadString(aptr);
  if pcw<>nil then
  begin
    AddText(lnode,'NAME',pcw,ntString);
    FreeMem(pcw);
  end
  else
    AddText(lnode,'NAME',pname,ntString);
  AddInteger64(lnode,'PARENTID',aparent);
  AddInteger64(lnode,'ID',ch.id);

//writeln(HexStr(llptr-_filestart,8),' object start ',ch.atype);

  //--- Properties

  lcnt:=ReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    laptr:=aptr;
    sch.asize:=ReadWord(aptr); // 
    if sch.asize=0 then
    begin
writeln('size=0');
      break;
    end;
    sch.atype:=ReadByte(aptr);
    case GetPropInfo(lobj,sch.atype,pname) of
      ntBool     : AddBool     (lnode,pname,ReadInteger  (aptr)<>0);
      ntInteger  : AddInteger  (lnode,pname,ReadInteger  (aptr));
      ntUnsigned : AddUnsigned (lnode,pname,ReadDWord    (aptr));
      ntFloat    : AddFloat    (lnode,pname,ReadFloat    (aptr));
      ntDouble   : AddDouble   (lnode,pname,ReadDouble   (aptr));
      ntInteger64: AddInteger64(lnode,pname,ReadInteger64(aptr));
      ntString: begin
		    pcw:=ReadString(aptr);
		    AddText(lnode,pname,pcw,ntString);
		    FreeMem(pcw);
      end;
      ntVector: begin
        AddFloat(lnode,PWideChar(WideString(pname)+'X'),ReadFloat(aptr));
        AddFloat(lnode,PWideChar(WideString(pname)+'Y'),ReadFloat(aptr));
        AddFloat(lnode,PWideChar(WideString(pname)+'Z'),ReadFloat(aptr));
      end;
    else
writeln(HexStr(laptr-_filestart,8),' obj type ',ch.atype,'; prop type ',sch.atype,' size ',sch.asize);
      inc(aptr,sch.asize-1);
    end;
  end;

  lsize:=ReadInteger(aptr); //!! exclude, plus 2
  if lsize>0 then
  begin

  //--- Timeline
    if ch.atype = IdTimeline then
    begin
      tldata:=AddGroup(lnode,'TIMELINEDATA');
      AddInteger64(tldata,'ID',ch.id);
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
          pcw:=ReadString(aptr);
          if pcw<>nil then
          begin
            ltltype:=1;
            tlnode:=AddGroup(tlobject,'TIMELINEOBJECTPROPERTY');
            AddText(tlnode,'OBJECTPROPERTYNAME',pcw,ntString);
            FreeMem(pcw);
          end;
          // Event
          pcw:=ReadString(aptr);
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
              pcw:=ReadString(aptr);
//writeln('point value ',string(widestring(pcw)));
              AddText(tlpoint,'VALUE',pcw,ntString);
              FreeMem(pcw);
            end;
          end;
        end;
      end;
    end;

    //--- Logic group
    if ch.atype = idLogicGroup then
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
          pcw :=ReadString(aptr); AddText(lglnk,'OUTPUTNAME',pcw,ntString); FreeMem(pcw);
          pcw :=ReadString(aptr); AddText(lglnk,'INPUTNAME' ,pcw,ntString); FreeMem(pcw);
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
      DoParseBlockTL2(lnode,aptr,ch.id);
    end;
  end;
  aptr:=llptr+ch.asize;
end;

procedure DoParseBlockHob(var anode:PTL2Node; var aptr:pByte; const aparent:Int64);
var
  bnode,lnode,tlnode:PTL2Node;
  laptr,llptr,lptr:pByte;
  lname,pcw:PWideChar;
  ch :TLayChunkHeader;
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
  ch.asize:=ReadDWord(aptr);
//AddText(lnode,'start',pwidechar(widestring(HexStr(aptr-_filestart,8))),ntstring);
  if ch.asize=0 then exit;

  ch.atype:=ReadInteger(aptr);
  ch.id   :=ReadInteger64(aptr);
//writeln('start ',HexStr(aptr-_filestart,8),' size ',ch.asize);
  lname:=GetTagStr(ch.atype);
  AddText(lnode,'DESCRIPTOR',lname,ntString);
  AddInteger64(lnode,'ID',ch.id);
  pcw:=ReadShortStringUTF8(aptr);
  if pcw<>nil then
  begin
    AddText(lnode,'NAME',pcw,ntString);
    FreeMem(pcw);
  end
  else
    AddText(lnode,'NAME',lname,ntString);

  //--- Properties

  lcnt:=ReadByte(aptr);
  for i:=0 to lcnt-1 do
  begin
    llsize:=ReadWord(aptr);
//writeln('prop ',i+1,'/',lcnt,' size ',llsize,' at ',HexStr(aptr-_filestart,8));
    llptr:=aptr;
    lname:=GetTagStr(Integer(ReadDWord(aptr)));

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
        AddInteger(lnode,'UNKNOWNSMALL',llsize);
        AddText   (lnode,'UNKNADDR'    ,
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
          AddInteger(lnode,'UNKNOWN',llsize-4);
          AddText   (lnode,lname,
              PWideChar(WideString(HexStr(aptr-_filestart,8))),ntString);
        end;
      end
    end;

    aptr:=llptr+llsize;
  end;

  llsize:=ReadInteger(aptr);
  if llsize>0 then
  begin
//writeln('Additional data at ',HexStr(aptr-_filestart,8),' size ',llsize);

    //----- Logic group -----

    if ch.atype=-2033361166 then
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
          AddInteger(lglnk,'LINKINGTO',ReadByte(aptr));
          AddText(lglnk,'OUTPUTNAME',GetTagStr(Integer(ReadDWord(aptr))),ntString);
          AddText(lglnk,'INPUTNAME' ,GetTagStr(Integer(ReadDWord(aptr))),ntString);
        end;
      end;
    end

    //----- Timeline -----

    else if ch.atype=-1670985697 then
    begin
      tldata:=AddGroup(lnode,'TIMELINEDATA');
      AddInteger64(tldata,'ID',ch.id);

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
          laptr:=aptr;

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
writeln('Unknown Timeline type in ',_filename,' at ',HexStr(laptr-_filestart,8));
            tlnode:=AddGroup(tlobject,'TIMELINEUNKNOWN');
//            continue;
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

//if ltltype<>1 then writeln('ltype= ',ltltype,' at ',HexStr(laptr-_filestart,8));

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
                AddText(tlpoint,'VALUE_2',pcw,ntString);
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

//writeln('child ',HexStr(aptr-_filestart,8));
  lcnt:=ReadWord(aptr);
  if lcnt>0 then
  begin
    lnode:=AddGroup(bnode,'CHILDREN');
    for i:=0 to lcnt-1 do
    begin
//writeln('child ',i+1,'/',lcnt,' at ',HexStr(aptr-_filestart,8));
      DoParseBlockHob(lnode,aptr,ch.id);
    end;
  end;

  aptr:=lptr+ch.asize;
end;

procedure DoParse(buf:pByte);
var
  pcw:PWideChar;
  lobj,lc:PTL2Node;
  lptr:pByte;
  ldata,i,lcnt,llayver:integer;
  b1,b2,b3:boolean;
begin
  lptr:=buf;
  lver:=ReadByte(lptr);
  if lver=$5A then
  begin
    inc(lptr,7);
  end;

  //--- TL2 ---

  if lver=11 then
  begin
    slout:=AddGroup(nil,'Layout');
    llayver:=ReadByte(lptr);             // Layout version
    AddInteger(slout,'VERSION',llayver);
    lc:=AddUnsigned(slout,'COUNT',0);
    ReadDWord(lptr);                     // offset

    lcnt:=ReadWord (lptr);               // root baseobject count
    lobj:=AddGroup(slout,'OBJECTS');
    for i:=0 to lcnt-1 do
      DoParseBlockTL2(lobj,lptr,-1);
    lc^.asUnsigned:=objcount;
  end;

  //--- Hob ---

  if lver=8 then
  begin
    inc(lptr);
    lcnt:=ReadDWord(lptr);
    AddUnsigned(slout,'COUNT',lcnt);
    ReadDword(lptr);                // offset

    ReadByte(lptr);                 // 1
    pcw:=ReadShortStringUTF8(lptr); // LEVEL
    slout:=AddGroup(nil,pcw);
    FreeMem(pcw);
    inc(lptr);                      // 0
    inc(lptr);                      // 4
    ldata:=ReadDWord(lptr);         // absolute offset to data
    pcw:=ReadShortString(lptr);
    if pcw<>nil then
    begin
      AddText(slout,'BASE',pcw,ntString);
      FreeMem(pcw);
    end;
    inc(lptr,6*SizeOf(single));   // 6*4
    b1:=ReadByte(lptr)<>0;          // 1 usually
    b2:=ReadByte(lptr)<>0;          // 0 usually but can be a 1
    b3:=ReadByte(lptr)<>0;          // 0 usually

    if b2 then
    begin
      pcw:=ReadShortStringUTF8(lptr);
      AddText(slout,'LAYOUT_TITLE',pcw,ntString);
      FreeMem(pcw);
      AddInteger64(slout,'LAYOUT_ID',ReadInteger64(lptr));
    end;

    lptr:=_filestart+ldata;
    lobj:=AddGroup(slout,'OBJECTS');
    lcnt:=ReadWord (lptr);
    for i:=0 to lcnt-1 do
      DoParseBlockHob(lobj,lptr,-1);
  end;
end;

procedure DoProcessFile(const fname:string);
var
  f:file of byte;
  buf:pByte;
  l:integer;
begin
//writeln(fname);
_filename:=fname;
  Assign(f,fname);
  Reset(f);
  if IOResult=0 then
  begin
    l:=FileSize(f);
    GetMem(buf,l);
    BlockRead(f,buf^,l);
    slout:=nil;
_filestart:=buf;
    objcount:=0;
    DoParse(buf);
    WriteDatTree(slout,PChar(fname+'.TXT'));
    DeleteNode(slout);
    FreeMem(buf);
    Close(f);
  end;
end;

procedure CycleDir(const adir:String);
var
  sr:TSearchRec;
  lext:string;
  lname:AnsiString;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(lname);
      end
      else
      begin
        lext:=UpCase(ExtractFileExt(lname));
        if (lext='.LAYOUT') then
        begin
          DoProcessFile(lname);
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

procedure LoadDict(const aname:string);
var
  sl:TStringList;
  i,p:integer;
begin
  sl:=TStringList.Create;
  try
    sl.LoadFromFile('dictionary.txt');
    SetLength(dict,sl.Count);
    for i:=0 to sl.Count-1 do
    begin
      p:=Pos(':',sl[i]);
      Val(Copy(sl[i],1,p-1),dict[i].hash);
      dict[i].name:=Copy(sl[i],p+1);
    end;
  except
    dict:=nil;
  end;
  sl.Free;
end;

begin

slglob:=TStringList.Create;
slglob.Sorted:=True;
try
slglob.LoadFromFile('hashes.txt');
except
end;

  otags:=ParseDatFile('objects.dat');
  LoadDict('dictionary.txt');
  if dict<>nil then
    tags:=nil
  else
    tags:=ParseDatFile('tags.dat');
  ctags:=ParseDatFile('custom.dat');
  if ParamCount=0 then
    cycleDir('.')
  else
    doprocessfile(paramstr(1));
  SetLength(dict,0);
  DeleteNode(otags);
  DeleteNode(ctags);
  DeleteNode(tags);

slglob.Sort;
slglob.SaveToFile('hashes_lay.txt');
slglob.Free;

end.
