{%TODO replace aptr by info: filename (if only), buffer start, position. Looks like TMemoryStream}
unit rglayunpack;

interface

uses
  inifiles;

function DoParseLayout    (buf:pByte; const fname:string=''):pointer;
function DoParseLayoutFile(const afname:string):pointer;
function IsProperLayout(buf:pByte):boolean;
procedure ReadLayINI(aini:TINIFile);


implementation

uses
  sysutils,
  rgglobal,
  rglog,
  rgnode,
  rgdict,
  rgmemory;

var
  known,unkn:TRGDict;
var
  aliases:TRGDict;
  _filestart:PByte;
  m00,m01,m02,m10,m11,m12,m20,m21,m22:Widestring;
  buffer:WideString;
  fver:Byte;


function ReadStr(var aptr:PByte):PWideChar;
begin
  case fver of
    verTL1: result:=memReadDWordString(aptr);
    verTL2: result:=memReadShortString(aptr);
    verHob,
    verRGO,
    verRG : result:=memReadShortStringUTF8(aptr);
  else
    result:=nil;
  end;
end;

function GetStr(aid:dword):PWideChar;
begin
  if aid=0 then exit(nil);

  result:=nil;

  result:=aliases.Tag[aid];

  if result=nil then
    result:=RGTags.Tag[aid];

  if result=nil then
  begin
    RGLog.Add('Unknown tag with hash '+IntToStr(aid));
    Str(aid,buffer);
    result:=pointer(buffer);
    unkn.add(aid,nil);
  end
  else
    known.add(aid,result);
end;

function GuessDataType(asize:integer; aptr:pByte; aver:integer):integer;
var
  ltmp:dword;
  e:byte;
begin
  // standard: boolean, unsigned, integer, float
  if asize=4 then
  begin
    ltmp:=memReadDWord(aptr);
    //!! can be boolean - we can't get difference
    if ltmp in [0,1] then
      result:=rgInteger // or rgBool
    else if (ltmp shr 24) in [0,$FF] then
      result:=rgInteger
    else
    begin
      e:=(ltmp shr 23) and $FF;
      if (e=$FF) or ((e=0) and ((ltmp and $7FFFFF)<>0)) then
        result:=rgInteger
      else
        result:=rgFloat;
    end;
  end
  else if asize<0 then result:=rgUnknown
  else
  begin
    // check for string
    case aver of
      verTL1: begin
      end;

      verTL2: begin
        ltmp:=memReadWord(aptr);
        if ltmp=(asize-2) div SizeOf(WideChar) then
          Exit(rgString);
      end;

      verHob,
      verRGO,
      verRG : begin
        ltmp:=memReadWord(aptr);
        if ltmp=asize-2 then     // UTF8 text
          Exit(rgString);
      end;
    end;

         if asize= 8 then result:=rgInteger64 // or Vector2
    else if asize=12 then result:=rgVector3
    else if asize=16 then result:=rgVector4
    else                  result:=rgUnknown;
  end;
end;

function ReadPropertyValue(aid:UInt32;asize:integer; anode:pointer; var aptr:PByte; ainfo:TRGObject):boolean;
var
  lmatrix:TMatrix4x4;
  lq:TVector4;
  valq:Int64;
  lname,pcw:PWideChar;
  lptr:PByte;
  ltype,vali:integer;
  valu:UInt32;
begin
  lptr:=aptr;

  ltype:=ainfo.GetPropInfoById(aid,lname);
  result:=ltype<>rgUnknown;
  if ltype=rgUnknown then
  begin
    ltype:=GuessDataType(asize,aptr,ainfo.Version);
  end;

  if (lname=nil) and (ainfo.Version in [verHob, verRG, verRGO]) then
    lname:=GetStr(aid);
  
  if not result then
  begin
    if ltype=rgInteger then
      RGLog.Add('    '+IntToStr(aid)+':'+TypeToText(ltype)+':'+lname+'='+IntToStr(PDword(aptr)^))
    else
      RGLog.Add('    '+IntToStr(aid)+':'+TypeToText(ltype)+':'+lname);
  end;

//  RGLog.Add('>>'+IntToStr(aid)+':'+TypeToText(ltype)+':'+lname);

  case ltype of
    rgBool     : AddBool(anode,lname,memReadInteger(aptr)<>0);
    rgInteger  : begin vali:=memReadInteger  (aptr); if vali<>0 then AddInteger  (anode,lname,vali); end;
    rgUnsigned : begin valu:=memReadDWord    (aptr); if valu<>0 then AddUnsigned (anode,lname,valu); end;
    rgFloat    : begin lq.X:=memReadFloat    (aptr); if lq.X<>0 then AddFloat    (anode,lname,lq.X); end;
    rgInteger64: begin valq:=memReadInteger64(aptr); if valq<>0 then AddInteger64(anode,lname,valq); end;
    rgDouble   : AddDouble(anode,lname,memReadDouble(aptr));
    rgNote,
    rgTranslate,
    rgString: begin
      case ainfo.Version of
        verTL1: if asize>0 then
        begin
          GetMem  (pcw ,(asize+1)*SizeOf(DWord));
          FillChar(pcw^,(asize+1)*SizeOf(DWord),0);
          memReadData(aptr,pcw^,asize*SizeOf(DWord));
        end;
        verTL2: pcw:=memReadShortString(aptr);
        verRG,
        verRGO,
        verHob: pcw:=memReadShortStringUTF8(aptr);
      end;
      if (pcw<>nil) and (pcw^<>#0) then
      begin
        AddString(anode,lname,pcw);
        FreeMem(pcw);
      end;
    end;
    rgVector2: begin
      lq.X:=memReadFloat(aptr); if lq.X<>0 then AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(aptr); if lq.Y<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
    end;
    rgVector3: begin
      lq.X:=memReadFloat(aptr); if lq.X<>0 then AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(aptr); if lq.Y<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
      lq.Z:=memReadFloat(aptr); if lq.Z<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Z'),lq.Z);
    end;
    // Quaternion
    rgVector4: begin
      lq.X:=memReadFloat(aptr); if lq.X<>0 then AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(aptr); if lq.Y<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
      lq.Z:=memReadFloat(aptr); if lq.Z<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Z'),lq.Z);
      lq.W:=memReadFloat(aptr); if lq.W<>0 then AddFloat(anode,PWideChar(WideString(lname)+'W'),lq.W);

      // Additional, not sure what it good really
      if CompareWide(lname,'ORIENTATION')=0 then
      begin
         QuaternionToMatrix(lq,lmatrix);
         {if lmatrix[2,0]<>0 then} AddFloat(anode,pointer(m20),lmatrix[2,0]);
         {if lmatrix[1,0]<>0 then} AddFloat(anode,pointer(m10),lmatrix[1,0]);
         {if lmatrix[0,0]<>0 then} AddFloat(anode,pointer(m00),lmatrix[0,0]);
         {if lmatrix[2,1]<>0 then} AddFloat(anode,pointer(m21),lmatrix[2,1]);
         {if lmatrix[1,1]<>0 then} AddFloat(anode,pointer(m11),lmatrix[1,1]);
         {if lmatrix[0,1]<>0 then} AddFloat(anode,pointer(m01),lmatrix[0,1]);
         {if lmatrix[2,2]<>0 then} AddFloat(anode,pointer(m22),lmatrix[2,2]);
         {if lmatrix[1,2]<>0 then} AddFloat(anode,pointer(m12),lmatrix[1,2]);
         {if lmatrix[0,2]<>0 then} AddFloat(anode,pointer(m02),lmatrix[0,2]);
      end;
    end;
  else
    AddInteger(anode,'??UNKNOWN',asize);
    AddString (anode,PWideChar('??'+WideString(lname)),
            PWideChar(WideString(HexStr(aptr-_filestart,8))));
    RGLog.Add('Unknown property type '+IntToStr(ltype)+' size '+IntToStr(asize)+
              ' at '+HexStr(aptr-_filestart,8));
  end;

  aptr:=lptr+asize;
end;

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
        verRGO,
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
  ltmpq:Int64;
  tlpoint,tlnode,tldata,tlobject:pointer;
  pcw:PWideChar;
  laptr:pByte;
  lint,ltlpoints,ltltype,ltlprops,ltlobjs,i,j,k:integer;
  ltmp:integer;
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
{
      if fver=verRGO then
      begin
        ltmpq:=memReadInteger64(aptr);
        RGLog.Add('RGO Timeline Int64='+IntToStr(ltmpq));
        ltmp:=memReadByte(aptr);
        RGLog.Add('RGO Timeline byte='+IntToStr(ltmp));
      end;
}
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
          RGLog.Add('Double Timeline type at '+HexStr(aptr-_filestart,8));
        end;
        ltltype:=2;
        tlnode:=AddGroup(tlobject,'TIMELINEOBJECTEVENT');
        AddString(tlnode,'OBJECTEVENTNAME',pcw);
        FreeMem(pcw);
      end;

      if ltltype=0 then
      begin
        RGLog.Add('Unknown Timeline type at '+HexStr(laptr-_filestart,8));
        tlnode:=AddGroup(tlobject,'??TIMELINEUNKNOWN');
      end;

      ltlpoints:=memReadByte(aptr);
      for k:=0 to ltlpoints-1 do
      begin
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
            AddString(tlpoint,'VALUE',pcw);
            FreeMem(pcw);
          end;
        end;

        if fver in [verHob, verRG, verRGO] then
        begin
          pcw:=memReadShortStringUTF8(aptr);
          if pcw<>nil then
          begin
            ltltype:=1;
            AddString(tlpoint,'VALUE_1',pcw);
            FreeMem(pcw);
          end;

//          if (ltltype=0) or (ltltype=1) then
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
            RGLog.Add('Timeline event. Don''t know what to do. At '+HexStr(laptr-_filestart,8));
          end;
        end;

      end;
    end;
  end;
end;

{$Include lay_tl1.inc}

{$Include lay_tl2.inc}

{$Include lay_hob.inc}

function DoParseLayout(buf:pByte; const fname:string=''):pointer;
begin
  _filestart:=buf;

  case buf^ of
    5  : begin fver:=verRG ; result:=DoParseLayoutRG (buf); end;
    8  : begin fver:=verHob; result:=DoParseLayoutHob(buf); end;
    9  : begin fver:=verRGO; result:=DoParseLayoutRG (buf); end; //!!!!!!!!
    11 : begin fver:=verTL2; result:=DoParseLayoutTL2(buf,fname); end;
    $5A: begin fver:=verTL1; result:=DoParseLayoutTL1(buf); end;
  else
    result:=nil;
  end;

end;

function DoParseLayoutFile(const afname:string):pointer;
var
  f:file of byte;
  buf:PByte;
  l:integer;
begin
  AssignFile(f,afname);
  Reset(f);
  if IOResult=0 then
  begin
    l:=FileSize(f);
    GetMem(buf,l);
    BlockRead(f,buf^,l);
    CloseFile(f);
    if IsProperLayout(buf) then
    begin
      RGLog.Add('Processing '+afname);
      result:=DoParseLayout(buf,afname);
    end;

    FreeMem(buf);
 end;
end;

function IsProperLayout(buf:pByte):boolean;
begin
  result:=buf^ in [5, 8, 9, 11, $5A];
end;

procedure ReadLayINI(aini:TINIFile);
begin
  m00:=UnicodeString(aini.ReadString('matrix_xy','00','RIGHTX'));
  m01:=UnicodeString(aini.ReadString('matrix_xy','01','UPX'));
  m02:=UnicodeString(aini.ReadString('matrix_xy','02','FORWARDX'));
  m10:=UnicodeString(aini.ReadString('matrix_xy','10','RIGHTY'));
  m11:=UnicodeString(aini.ReadString('matrix_xy','11','UPY'));
  m12:=UnicodeString(aini.ReadString('matrix_xy','12','FORWARDY'));
  m20:=UnicodeString(aini.ReadString('matrix_xy','20','RIGHTZ'));
  m21:=UnicodeString(aini.ReadString('matrix_xy','21','UPZ'));
  m22:=UnicodeString(aini.ReadString('matrix_xy','22','FORWARDZ'));
end;

initialization

  known.init;
  known.options:=[check_hash];

  unkn.init;
  unkn.options:=[check_hash];

  aliases.init;
  aliases.import('layaliases.txt');

  LoadLayoutDict('compact-tl1.txt', verTL1);
  LoadLayoutDict('compact-tl2.txt', verTL2);
  LoadLayoutDict('compact-rg.txt' , verRG);
  LoadLayoutDict('compact-rgo.txt', verRGO);
  LoadLayoutDict('compact-hob.txt', verHob);

finalization
  
  if known.count>0 then
  begin
    known.Sort;
    known.export('known-lay.dict',false);
    known.export('known-lay-txt.dict',false,false);
  end;
  known.clear;

  if unkn.count>0 then
  begin
    unkn.Sort;
    unkn.export('unknown-lay.dict',false);
  end;
  unkn.clear;
  
  aliases.Clear;

end.
