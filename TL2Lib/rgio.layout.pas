unit RGIO.Layout;

interface

uses
//  Classes,
  rgglobal;

const
  ltLayout   = 0;
  ltParticle = 1;
  ltUI       = 2;

function ParseLayoutMem   (abuf        :pByte  ; atype:cardinal=ltLayout):pointer;
function ParseLayoutMem   (abuf        :pByte  ; const afname:string):pointer;
//function ParseLayoutStream(astream     :TStream; atype:cardinal=ltLayout):pointer;
//function ParseLayoutStream(astream     :TStream; const afname:string):pointer;
function ParseLayoutFile  (const afname:string):pointer;
{
function BuildDatMem   (data:pointer; out   bin    :pByte     ; aver:byte=verTL2; dictidx:integer=-1):integer;
function BuildDatStream(data:pointer;       astream:TStream   ; aver:byte=verTL2; dictidx:integer=-1):integer;
function BuildDatFile  (data:pointer; const fname  :AnsiString; aver:byte=verTL2; dictidx:integer=-1):integer;
}

implementation

uses
  sysutils,

  rglogging,
  rgnode,
  rgdict,
  rgmemory;

{$IFDEF DEBUG}  
var
  known,unkn:TRGDict;
{$ENDIF}
var
  aliases:TRGDict;

const
  ltName:array [0..2] of PWideChar = (
    'Layout',
    'Particle Creator',
    'UI'
  );

const
  m00 = 'RIGHTX';
  m01 = 'UPX';
  m02 = 'FORWARDX';
  m10 = 'RIGHTY';
  m11 = 'UPY';
  m12 = 'FORWARDY';
  m20 = 'RIGHTZ';
  m21 = 'UPZ';
  m22 = 'FORWARDZ';

type
  TRGLayoutFile = object
  private
    info:TRGObject;
    FStart:PByte;
    FPos:PByte;
    FBuffer:WideString;
    FVer :integer;
     
  private
    function  ReadStr():PWideChar;
    function  GetStr(aid:dword):PWideChar;
    function  ReadPropertyValue(aid:UInt32;asize:integer; anode:pointer):boolean;
    function  GuessDataType(asize:integer):integer;
    procedure ParseLogicGroup(var anode:pointer);
    procedure ParseTimeline  (var anode:pointer; aid:Int64);

    function  DoParseBlockTL1(var anode:pointer; const aparent:Int64):integer;
    procedure ReadPropertyHob(var anode:pointer);
    function  DoParseBlockHob(var anode:pointer; const aparent:Int64):integer;
    procedure ReadPropertyTL2(var anode:pointer);
    function  DoParseBlockTL2(var anode:pointer; const aparent:Int64):integer;

    function DoParseLayoutTL1(atype:cardinal):pointer;
    function DoParseLayoutTL2(atype:cardinal):pointer;
    function DoParseLayoutHob(atype:cardinal):pointer;
    function DoParseLayoutRG (atype:cardinal):pointer;

  public
    procedure Init;
    procedure Free;
  end;

function TRGLayoutFile.ReadStr():PWideChar;
begin
  case FVer of
    verTL1: result:=memReadDWordString(FPos);
    verTL2: result:=memReadShortString(FPos);
    verHob,
    verRGO,
    verRG : result:=memReadShortStringUTF8(FPos);
  else
    result:=nil;
  end;
end;

function TRGLayoutFile.GetStr(aid:dword):PWideChar;
begin
  if aid=0 then exit(nil);

  result:=aliases.Tag[aid];

  if result=nil then
    result:=RGTags.Tag[aid];

  if result=nil then
  begin
    RGLog.Add('Unknown tag with hash '+IntToStr(aid));

    Str(aid,FBuffer);
    result:=pointer(FBuffer);

{$IFDEF DEBUG}  
    unkn.add(aid,nil);
{$ENDIF}
  end
{$IFDEF DEBUG}  
  else
    known.add(aid,result);
{$ENDIF}
end;

function TRGLayoutFile.GuessDataType(asize:integer):integer;
var
  lptr:PByte;
  ltmp:dword;
  e:byte;
begin
  lptr:=FPos;
  // standard: boolean, unsigned, integer, float
  if asize=4 then
  begin
    ltmp:=memReadDWord(lptr);
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
    case FVer of
      verTL1: begin
      end;

      verTL2: begin
        ltmp:=memReadWord(lptr);
        if ltmp=(asize-2) div SizeOf(WideChar) then
          Exit(rgString);
      end;

      verHob,
      verRGO,
      verRG : begin
        ltmp:=memReadWord(lptr);
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

function TRGLayoutFile.ReadPropertyValue(aid:UInt32;asize:integer; anode:pointer):boolean;
var
  ls:string;
  lmatrix:TMatrix4x4;
  lq:TVector4;
  valq:Int64;
  lname,pcw:PWideChar;
  lptr:PByte;
  ltype,vali:integer;
  valu:UInt32;
begin
  lptr:=FPos;

  ltype:=info.GetPropInfoById(aid,lname);
  result:=ltype<>rgUnknown;
  if ltype=rgUnknown then
  begin
    ltype:=GuessDataType(asize);
  end;

  if (lname=nil){ and (info.Version in [verHob, verRG, verRGO])} then
    lname:=GetStr(aid);
  
  if not result then
  begin
    ls:='    '+IntToStr(aid)+':'+string(TypeToText(ltype))+':'+string(lname);
    if ltype=rgInteger then ls:=ls+'='+IntToStr(PDword(FPos)^);
    RGLog.Add(ls);
  end;

//  RGLog.Add('>>'+IntToStr(aid)+':'+TypeToText(ltype)+':'+lname);

  case ltype of
    rgBool     : AddBool(anode,lname,memReadInteger(FPos)<>0);
    rgInteger  : begin vali:=memReadInteger  (FPos); if vali<>0 then AddInteger  (anode,lname,vali); end;
    rgUnsigned : begin valu:=memReadDWord    (FPos); if valu<>0 then AddUnsigned (anode,lname,valu); end;
    rgFloat    : begin lq.X:=memReadFloat    (FPos); if lq.X<>0 then AddFloat    (anode,lname,lq.X); end;
    rgInteger64: begin valq:=memReadInteger64(FPos); if valq<>0 then AddInteger64(anode,lname,valq); end;
    rgDouble   : AddDouble(anode,lname,memReadDouble(FPos));
    rgNote,
    rgTranslate,
    rgString: begin
      case FVer of
        verTL1: if asize>0 then
        begin
          GetMem  (pcw ,(asize+1)*SizeOf(DWord));
          FillChar(pcw^,(asize+1)*SizeOf(DWord),0);
          memReadData(FPos,pcw^,asize*SizeOf(DWord));
        end;
        verTL2: pcw:=memReadShortString(FPos);
        verRG,
        verRGO,
        verHob: pcw:=memReadShortStringUTF8(FPos);
      end;
      if (pcw<>nil) and (pcw^<>#0) then
      begin
        AddString(anode,lname,pcw);
        FreeMem(pcw);
      end;
    end;
    rgVector2: begin
      lq.X:=memReadFloat(FPos); if lq.X<>0 then AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(FPos); if lq.Y<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
    end;
    rgVector3: begin
      lq.X:=memReadFloat(FPos); if lq.X<>0 then AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(FPos); if lq.Y<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
      lq.Z:=memReadFloat(FPos); if lq.Z<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Z'),lq.Z);
    end;
    // Quaternion
    rgVector4: begin
      lq.X:=memReadFloat(FPos); if lq.X<>0 then AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(FPos); if lq.Y<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
      lq.Z:=memReadFloat(FPos); if lq.Z<>0 then AddFloat(anode,PWideChar(WideString(lname)+'Z'),lq.Z);
      lq.W:=memReadFloat(FPos); if lq.W<>0 then AddFloat(anode,PWideChar(WideString(lname)+'W'),lq.W);

      // Additional, not sure what it good really
      if CompareWide(lname,'ORIENTATION')=0 then
      begin
         QuaternionToMatrix(lq,lmatrix);
         {if lmatrix[2,0]<>0 then} AddFloat(anode,m20,lmatrix[2,0]);
         {if lmatrix[1,0]<>0 then} AddFloat(anode,m10,lmatrix[1,0]);
         {if lmatrix[0,0]<>0 then} AddFloat(anode,m00,lmatrix[0,0]);
         {if lmatrix[2,1]<>0 then} AddFloat(anode,m21,lmatrix[2,1]);
         {if lmatrix[1,1]<>0 then} AddFloat(anode,m11,lmatrix[1,1]);
         {if lmatrix[0,1]<>0 then} AddFloat(anode,m01,lmatrix[0,1]);
         {if lmatrix[2,2]<>0 then} AddFloat(anode,m22,lmatrix[2,2]);
         {if lmatrix[1,2]<>0 then} AddFloat(anode,m12,lmatrix[1,2]);
         {if lmatrix[0,2]<>0 then} AddFloat(anode,m02,lmatrix[0,2]);
      end;
    end;
  else
    AddInteger(anode,'??UNKNOWN',asize);
    AddString (anode,PWideChar('??'+WideString(lname)), PWideChar(WideString(HexStr(FPos-FStart,8))));
    RGLog.Add('Unknown property type '+IntToStr(ltype)+' size '+IntToStr(asize)+' at '+HexStr(FPos-FStart,8));
  end;

  FPos:=lptr+asize;
end;

procedure TRGLayoutFile.ParseLogicGroup(var anode:pointer);
var
  lgobj,lgroup,lglnk:pointer;
  pcw:PWideChar;
  lsize:integer;
  lgroups,lglinks,i,j:integer;
begin
  lgroup:=AddGroup(anode,'LOGICGROUP');
  lgroups:=memReadByte(FPos);
  for i:=0 to lgroups-1 do
  begin
    lgobj:=AddGroup(lgroup,'LOGICOBJECT');
    AddUnsigned (lgobj,'ID'      ,memReadByte     (FPos));
    AddInteger64(lgobj,'OBJECTID',memReadInteger64(FPos));
    AddFloat    (lgobj,'X'       ,memReadFloat    (FPos));
    AddFloat    (lgobj,'Y'       ,memReadFloat    (FPos));

    lsize:=memReadInteger(FPos); // absolute offset of next

    lglinks:=memReadByte(FPos);
    for j:=0 to lglinks-1 do
    begin
      lglnk:=AddGroup(lgobj,'LOGICLINK');
      AddInteger(lglnk,'LINKINGTO' ,memReadByte(FPos));
      case FVer of
        verTL2: begin
          pcw :=memReadShortString(FPos); AddString(lglnk,'OUTPUTNAME',pcw); FreeMem(pcw);
          pcw :=memReadShortString(FPos); AddString(lglnk,'INPUTNAME' ,pcw); FreeMem(pcw);
        end;
        verHob,
        verRGO,
        verRG : begin
          AddString(lglnk,'OUTPUTNAME',GetStr(memReadDWord(FPos)));
          AddString(lglnk,'INPUTNAME' ,GetStr(memReadDWord(FPos)));
        end;
      end;
    end;
//    FPos:=FStart+lsize;
  end;
end;

procedure TRGLayoutFile.ParseTimeline(var anode:pointer; aid:Int64);
var
//  ltmpq:Int64;
  tlpoint,tlnode,tldata,tlobject:pointer;
  pcw:PWideChar;
  laptr:pByte;
  lint,ltlpoints,ltltype,ltlprops,ltlobjs,i,j,k:integer;
//  ltmp:integer;
begin
  tldata:=AddGroup(anode,'TIMELINEDATA');
  AddInteger64(tldata,'ID',aid);

  ltlobjs:=memReadByte(FPos);
  for i:=0 to ltlobjs-1 do
  begin
    tlobject:=AddGroup(tldata,'TIMELINEOBJECT');
    AddInteger64(tlobject,'OBJECTID',memReadInteger64(FPos));
    
    ltlprops:=memReadByte(FPos);
    for j:=0 to ltlprops-1 do
    begin
      ltltype:=0;
      laptr:=FPos;
{
      if fver=verRGO then
      begin
        ltmpq:=memReadInteger64(FPos);
        RGLog.Add('RGO Timeline Int64='+IntToStr(ltmpq));
        ltmp:=memReadByte(aptr);
        RGLog.Add('RGO Timeline byte='+IntToStr(ltmp));
      end;
}
      // Property
      pcw:=ReadStr();
      if pcw<>nil then
      begin
        ltltype:=1;
        tlnode:=AddGroup(tlobject,'TIMELINEOBJECTPROPERTY');
        AddString(tlnode,'OBJECTPROPERTYNAME',pcw);
        FreeMem(pcw);
      end;

      // Event
      pcw:=ReadStr();
      if pcw<>nil then
      begin
        if ltltype<>0 then
        begin
          RGLog.Add('Double Timeline type at '+HexStr(FPos-FStart,8));
        end;
        ltltype:=2;
        tlnode:=AddGroup(tlobject,'TIMELINEOBJECTEVENT');
        AddString(tlnode,'OBJECTEVENTNAME',pcw);
        FreeMem(pcw);
      end;

      if ltltype=0 then
      begin
        RGLog.Add('Unknown Timeline type at '+HexStr(laptr-FStart,8));
        tlnode:=AddGroup(tlobject,'??TIMELINEUNKNOWN');
      end;

      ltlpoints:=memReadByte(FPos);
      for k:=0 to ltlpoints-1 do
      begin
        tlpoint:=AddGroup(tlnode,'TIMELINEPOINT');
        AddFloat(tlpoint,'TIMEPERCENT',memReadFloat(FPos));

        lint:=memReadByte(FPos);
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
            pcw:=memReadShortString(FPos);
            AddString(tlpoint,'VALUE',pcw);
            FreeMem(pcw);
          end;
        end;

        if fver in [verHob, verRG, verRGO] then
        begin
          pcw:=memReadShortStringUTF8(FPos);
          if pcw<>nil then
          begin
            ltltype:=1;
            AddString(tlpoint,'VALUE_1',pcw);
            FreeMem(pcw);
          end;

//          if (ltltype=0) or (ltltype=1) then
          begin
            pcw:=memReadShortStringUTF8(FPos);
            if pcw<>nil then
            begin
              ltltype:=1;
              AddString(tlpoint,'VALUE',pcw);
              FreeMem(pcw);
            end;
          end;
          if ltltype=2 then
          begin
            RGLog.Add('Timeline event. Don''t know what to do. At '+HexStr(laptr-FStart,8));
          end;
        end;

      end;
    end;
  end;
end;

{$Include lay_tl1.inc}

{$Include lay_tl2.inc}

{$Include lay_hob.inc}

function IsProperLayout(abuf:pByte):boolean; inline;
begin
  result:=abuf^ in [5, 8, 9, 11, $5A];
end;

function GetLayoutType(const afname:string):cardinal;
var
  ls:string;
begin
  if afname<>'' then
  begin
    ls:=UpCase(afname);
    if      (pos('MEDIA\UI'       ,ls)>0) or (pos('MEDIA/UI'       ,ls)>0) then exit(ltUI)
    else if (pos('MEDIA\PARTICLES',ls)>0) or (pos('MEDIA/PARTICLES',ls)>0) then exit(ltParticle);
  end;
  result:=ltLayout;
end;

function ParseLayoutMem(abuf:pByte; atype:cardinal=ltLayout):pointer;
var
  rgl:TRGLayoutFile;

begin
  rgl.Init;

  rgl.FStart:=abuf;
  rgl.FPos  :=abuf;

  if atype>2 then atype:=0;

  case abuf^ of
    5  : begin rgl.FVer:=verRG ; result:=rgl.DoParseLayoutRG (atype); end;
    8  : begin rgl.FVer:=verHob; result:=rgl.DoParseLayoutHob(atype); end;
    9  : begin rgl.FVer:=verRGO; result:=rgl.DoParseLayoutRG (atype); end; //!!!!!!!!
    11 : begin rgl.FVer:=verTL2; result:=rgl.DoParseLayoutTL2(atype); end;
    $5A: begin rgl.FVer:=verTL1; result:=rgl.DoParseLayoutTL1(atype); end;
  else
    result:=nil;
  end;

  rgl.Free;
end;

function ParseLayoutMem(abuf:pByte; const afname:string):pointer;
begin
  if afname<>'' then RGLog.Reserve('Processing '+afname);

  result:=ParseLayoutMem(abuf,GetLayoutType(afname));
end;

{
function ParseLayoutStream(astream:TStream; atype:cardinal=ltLayout):pointer;
var
  lbuf:PByte;
begin
  GetMem(lbuf,astream.Size);
  aStream.Read(lbuf^,astream.Size);
  result:=ParseLayoutMem(lbuf,atype);
  FreeMem(lbuf);
end;

function ParseLayoutStream(astream:TStream; const afname:string):pointer;
begin
  if afname<>'' then RGLog.Add('Processing '+afname);

  result:=ParseLayoutStream(astream,GetLayoutType(afname));
end;
}
function ParseLayoutFile(const afname:string):pointer;
var
  f:file of byte;
  lbuf:PByte;
  l:integer;
begin
  result:=nil;
  AssignFile(f,afname);
  Reset(f);
  if IOResult=0 then
  begin
    l:=FileSize(f);
    GetMem(lbuf,l);
    BlockRead(f,lbuf^,l);
    CloseFile(f);
    if IsProperLayout(lbuf) then
    begin
      result:=ParseLayoutMem(lbuf,afname);
    end;
    FreeMem(lbuf);
  end;
end;

procedure TRGLayoutFile.Init;
begin
  info.Init;
end;

procedure TRGLayoutFile.Free;
begin
  info.Clear;
end;


initialization

{$IFDEF DEBUG}  
  known.init;
  known.options:=[check_hash];

  unkn.init;
  unkn.options:=[check_hash];
{$ENDIF}

  aliases.init;
  aliases.import('layaliases.txt');

finalization
  
{$IFDEF DEBUG}  
  if known.count>0 then
  begin
    known.Sort;
    known.export('known-lay.dict'    ,asText);
    known.export('known-lay-txt.dict',asText,false);
  end;
  known.clear;

  if unkn.count>0 then
  begin
    unkn.Sort;
    unkn.export('unknown-lay.dict',asText);
  end;
  unkn.clear;
{$ENDIF}  
  aliases.Clear;

end.
