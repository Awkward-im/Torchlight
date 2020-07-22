{$I-}

uses
  sysutils,
  TL2DatNode,
  TL2Memory;

type
  TAttribute = (
      t_unknown,t_integer,t_float,t_double,t_unsigned_int,
      t_string,t_bool,t_integer64,t_translate);

const
  IdLogicGroup = 36;
  IdTimeline   = 35;

type
  TLayChunkHeader = packed record
    asize:integer; // including size
    atype:byte;    // object type
    id   :int64;
  end;
  TLaySubChunkHeader = packed record
    asize:word;   // excluding size
    atype:byte;   // tag type
  end;

  
var
  objcount:integer;
  _filestart:pbyte;
  lver:byte;
  slout,tags:PTL2Node;
  numbuffer:array [0..31] of WideChar;

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
writeln('UNKNOWN PROPRETY TYPE ',string(widestring(pcw)));
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

  for lobjs:=0 to tags^.childcount-1 do
  begin
    // for all scenes
    if tags^.children^[lobjs].Name='SCENE' then
    begin
      sobj:=@tags^.children^[lobjs];
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


procedure DoParseBlock(var anode:PTL2Node; var aptr:pByte; const aparent:Int64);
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
  pcw:=ReadShortString(aptr);
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
		    pcw:=ReadShortString(aptr);
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
      DoParseBlock(lnode,aptr,ch.id);
    end;
  end;
  aptr:=llptr+ch.asize;
end;

procedure DoParse(buf:pByte);
var
  lobj,lc:PTL2Node;
  lptr:pByte;
  i,lcnt,llayver:integer;
begin
  lptr:=buf;
  lver:=ReadByte(lptr);
  if lver=$5A then
  begin
    inc(lptr,7);
  end;
  if lver=11 then
  begin
    slout:=AddGroup(nil,'Layout');
    llayver:=ReadByte(lptr); // Layout version
    AddInteger(slout,'VERSION',llayver);
    lc:=AddUnsigned(slout,'COUNT',0);
    ReadDWord(lptr); // offset
    lcnt:=ReadWord (lptr); // root baseobject count
    lobj:=AddGroup(slout,'OBJECTS');
    for i:=0 to lcnt-1 do
      DoParseBlock(lobj,lptr,-1);
    lc^.asUnsigned:=objcount;
  end;
end;

procedure DoProcessFile(const fname:string);
var
  f:file of byte;
  buf:pByte;
  l:integer;
begin
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

begin
  tags:=ParseDatFile('objects.dat');
  if ParamCount=0 then
    cycleDir('.')
  else
    doprocessfile(paramstr(1));
  DeleteNode(tags);
end.
