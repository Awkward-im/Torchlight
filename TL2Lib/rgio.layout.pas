{TODO Float/DoublePrec for Str functions}
unit RGIO.Layout;

interface

uses
  Classes,
  rgglobal;

const
  ltLayout   = 0;
  ltParticle = 1;
  ltUI       = 2;

function ParseLayoutMem   (abuf        :pByte  ; atype:cardinal=ltLayout):pointer;
function ParseLayoutMem   (abuf        :pByte  ; const afname:string):pointer;
function ParseLayoutStream(astream     :TStream; atype:cardinal=ltLayout):pointer;
function ParseLayoutStream(astream     :TStream; const afname:string):pointer;
function ParseLayoutFile  (const afname:string):pointer;

function BuildLayoutMem   (data:pointer; out   bin    :pByte     ; aver:byte=verTL2):integer;
function BuildLayoutStream(data:pointer;       astream:TStream   ; aver:byte=verTL2):integer;
function BuildLayoutFile  (data:pointer; const fname  :AnsiString; aver:byte=verTL2):integer;

function GetLayoutVersion(abuf:PByte):integer;

function GetLayoutType(fname:PUnicodeChar):cardinal;
function GetLayoutType(const afname:string):cardinal;


implementation

uses
  sysutils,

  dict,
  rwmemory,
  logging,

  rgdict,
  rgdictlayout,
  rgstream,
  rgnode;

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

{$i featuretags.inc}

const
  strGameMode : array [1..2] of PWideChar = (
    'NORMAL',
    'NEW GAME PLUS'
  );
const
  strChoice : array [1..2] of PWideChar = (
    'Weight',
    'Random Chance'
  );

const
  strInterpolation : array [0..6] of PWideChar = (
    'Linear',
    'Linear Round',
    'Linear Round Down',
    'Linear Round Up',
    'No interpolation',
    'Quaternion',
    'Spline'
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
  TLayoutBinHob = packed record // "Group" type only
    GUID       :QWord;    // -1 for root
    choice     :Byte;     // (def 0) CHOICE: Weight=1; Random Chance=2
                          //   Presents in decription too (doubling)
    random     :DWord;    // (def 1)RANDOMIZATION
    number     :Byte;     // (def 1 or 0 for root) NUMBER
    offset     :DWord;    // group offset from start of file (6 for root)
    tag        :Integer;  // (def -1) "TAG" from FEATURETAGS.HIE
    // 22 bytes before child count
    unk1       :Word;
    unk2       :Word;
    unk3       :Word;
    idk1       :Byte;     // (def 0) can be 6
    unk        :array [0..14] of Byte;
{
    childs     :Word;     // child groups amount
}
  end;

type
  TLayoutBinRGO = packed record // "Group" type only
    GUID       :QWord;    // -1 for root
    choice     :Byte;     // (def 0) CHOICE: Weight=1; Random Chance=2
                          //   Presents in decription too (doubling)
    random     :DWord;    // (def 1)RANDOMIZATION
    number     :Byte;     // (def 1 or 0 for root) NUMBER
    offset     :DWord;    // group offset from start of file (6 for root)
    tag        :Integer;  // (def -1) "TAG" from FEATURETAGS.HIE
    // 10+ childs
    notag      :Byte;     // (def 0) value transforming to 'NO TAG FOUND'
    unique     :Byte;     // (def 0) LEVEL UNIQUE
                          //   Presents in decription too (doubling)
    gamemode   :Byte;     // (def 0) GAME MODE 1 - Normal ; 2 - NG+
                          //   Presents in decription too (doubling)
    unk        :Byte;
{
    childs     :Word;     // child groups amount
}
  end;

type
  TLayoutBinRG = packed record // "Group" type only
    GUID       :QWord;    // -1 for root
    choice     :Byte;     // (def 0) CHOICE: Weight=1; Random Chance=2
                          //   Presents in decription too (doubling)
    random     :DWord;    // (def 1)RANDOMIZATION
    number     :Byte;     // (def 1 or 0 for root) NUMBER
    offset     :DWord;    // group offset from start of file (6 for root)
    tag        :Integer;  // (def -1) "TAG" from FEATURETAGS.HIE
    // 4+childs
    notag      :Byte;     // (def 0) value transforming to 'NO TAG FOUND'
    unique     :Byte;     // (def 0) LEVEL UNIQUE
                          //   Presents in decription too (doubling)
    gamemode   :Byte;     // (def 0) GAME MODE 1 - Normal ; 2 - NG+
                          //   Presents in decription too (doubling)
    unk        :Byte;
{
    childs     :Word;     // child groups amount
}
  end;

type
  TLayoutBinTL2 = packed record // "Group" type only
    GUID       :QWord;    // -1 for root
    choice     :Byte;     // (def 0) CHOICE: Weight=1; Random Chance=2
                          //   Presents in decription too (doubling)
    random     :DWord;    // (def 1)RANDOMIZATION
    number     :Byte;     // (def 1 or 0 for root) NUMBER
    offset     :DWord;    // group offset from start of file (6 for root)
    tag        :Integer;  // (def -1) "TAG" from FEATURETAGS.HIE
    notag      :Byte;     // (def 0) value transforming to 'NO TAG FOUND'
    unique     :Byte;     // (def 0) LEVEL UNIQUE
                          //   Presents in decription too (doubling)
    gamemode   :Byte;     // (def 0) GAME MODE 1 - Normal ; 2 - NG+
                          //   Presents in decription too (doubling)
{
    ActThemes  :DWord;    // next x8 bytes are Active themes
    DeactThemes:DWord;    // next x8 bytes are DeActive themes
    childs     :Word;     // child groups amount
}
  end;

type

  { TRGLayoutFile }

  TRGLayoutFile = object
  private
    info:TRGObject;
    FStart   :PByte;
    FBinStart:PByte;
    FPos     :PByte;
    FBinPos  :PByte;
    FBuffer:WideString;
    FVer :integer;

  private
    function  ReadStr():PWideChar;
    function  GetStr(aid:dword):PWideChar;
    function  ReadPropertyValue(aid:UInt32;asize:integer; anode:pointer):boolean;
    function  GuessDataType(asize:integer):integer;
    procedure ParseLogicGroup(var anode:pointer);
    procedure ParseTimeline  (var anode:pointer; aid:Int64);

    procedure WriteStr          (astr :PWideChar; astream:TStream);
    procedure WriteVectorValue  (const vct:tVector4; atype:integer; astream:TStream);
    function  WritePropertyValue(anode:pointer     ; atype:integer; astream:TStream):integer;
    function  WriteProperties   (anode:pointer  ; astream:TStream):integer;
    procedure BuildTimeline     (anode:pointer  ; astream:TStream);
    procedure BuildLogicGroup   (anode:pointer  ; astream:TStream);

    // read TL1
    function  DoParseLayoutTL1(atype:cardinal):pointer;
    function  DoParseBlockTL1  (var anode:pointer; const aparent:Int64):integer;

    // read TL2
    function  DoParseLayoutTL2 (atype:cardinal):pointer;
    function  DoParseBlockTL2  (var anode:pointer; const aparent:Int64):integer;
    procedure ReadPropertyTL2  (var anode:pointer);
    procedure ReadBinaryDataTL2(var anode:pointer);
    function  GetTagTL2        (atag:integer):PWideChar;
    function  GetTagTL2Num     (atag:PWideChar):integer;

    // read Hob and RG
    function  DoParseLayoutHob (atype:cardinal):pointer;
    function  DoParseBlockHob  (var anode:pointer; const aparent:Int64):integer;
    procedure ReadPropertyHob  (var anode:pointer);
    procedure ReadBinaryDataHob(var anode: pointer);
    function  DoParseLayoutRG  (atype:cardinal):pointer;
    procedure ReadBinaryDataRG (var anode: pointer);

    // write TL2
    function DoBuildLayoutTL2  (anode:pointer; astream:TStream):integer;
    function DoWriteBlockTL2   (anode:pointer; astream:TStream; abstream:TStream):integer;
    function WritePropertiesTL2(anode:pointer; astream:TStream; var adata:TLayoutBinTL2):integer;

    function DoBuildLayoutTL1(anode:pointer; astream:TStream):integer;
    function DoBuildLayoutHob(anode:pointer; astream:TStream):integer;
    function DoBuildLayoutRG (anode:pointer; astream:TStream):integer;
  public
    procedure Init;
    procedure Free;
  end;

procedure TRGLayoutFile.Init;
begin
  info.Init;
end;

procedure TRGLayoutFile.Free;
begin
  info.Clear;
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

procedure TRGLayoutFile.WriteStr(astr:PWideChar; astream:TStream);
begin
  case FVer of
    verTL1: astream.WriteDWordString(astr);
    verTL2: astream.WriteShortString(astr);
    verHob,
    verRG,
    verRGO: astream.WriteShortStringUTF8(astr);
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
    unkn.add(nil,aid);
{$ENDIF}
  end
{$IFDEF DEBUG}  
  else
    known.add(result,aid);
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

function TRGLayoutFile.ReadPropertyValue(aid:UInt32; asize:integer; anode:pointer):boolean;
var
  lls,ls:WideString;
  lmatrix:TMatrix4x4;
  lq:TVector4;
  valq:Int64;
  vald:Double;
  lname,pcw:PWideChar;
  lptr:PByte;
  i,ltype,vali,lsize:integer;
  valu:UInt32;
  llen:word;
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
    Str(aid,lls);
    ls:='    '+lls+':'+WideString(TypeToText(ltype))+':'+WideString(lname);
    if ltype=rgInteger then
    begin
      Str(PDword(FPos)^,lls);
      ls:=ls+'='+lls;
    end;
    RGLog.AddWide(PWideChar(ls));
  end;

//  RGLog.Add('>>'+IntToStr(aid)+':'+TypeToText(ltype)+':'+lname);

  case ltype of
    rgBool,
    rgInteger,
    rgUnsigned,
    rgFloat:     lsize:=4;
    rgInteger64,
    rgDouble:    lsize:=8;
  else
    lsize:=0;
  end;
  if (lsize>0) and ((asize div lsize)>1) and ((asize mod lsize)=2) then
  begin
    ltype:=ltype or rgList;
//    if      ltype=rgUnsigned then ltype:=rgUIntList
//    else if ltype=rgFloat    then ltype:=rgFloatList;
  end;
  
  case ltype of
    rgBool     : AddBool(anode,lname,memReadInteger(FPos)<>0);
    rgInteger  : begin vali:=memReadInteger  (FPos); {if vali<>0 then} AddInteger  (anode,lname,vali); end;
    rgUnsigned : begin valu:=memReadDWord    (FPos); {if valu<>0 then} AddUnsigned (anode,lname,valu); end;
    rgFloat    : begin lq.X:=memReadFloat    (FPos); {if lq.X<>0 then} AddFloat    (anode,lname,lq.X); end;
    rgInteger64: begin valq:=memReadInteger64(FPos); {if valq<>0 then} AddInteger64(anode,lname,valq); end;
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
          end
          else
            pcw:=nil;
        verTL2: pcw:=memReadShortString(FPos);
        verRG,
        verRGO,
        verHob: pcw:=memReadShortStringUTF8(FPos);
      end;
//      if (pcw<>nil) and (pcw^<>#0) then
      begin
        AddString(anode,lname,pcw);
        FreeMem(pcw);
      end;
    end;
    rgVector2: begin
      lq.X:=memReadFloat(FPos); {if lq.X<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(FPos); {if lq.Y<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
    end;
    rgVector3: begin
      lq.X:=memReadFloat(FPos); {if lq.X<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(FPos); {if lq.Y<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
      lq.Z:=memReadFloat(FPos); {if lq.Z<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'Z'),lq.Z);
    end;
    // Quaternion
    rgVector4: begin
      lq.X:=memReadFloat(FPos); {if lq.X<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'X'),lq.X);
      lq.Y:=memReadFloat(FPos); {if lq.Y<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'Y'),lq.Y);
      lq.Z:=memReadFloat(FPos); {if lq.Z<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'Z'),lq.Z);
      lq.W:=memReadFloat(FPos); {if lq.W<>0 then} AddFloat(anode,PWideChar(WideString(lname)+'W'),lq.W);

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
    if ltype and rgList<>0 then
    begin
      ls:='';
      llen:=memReadWord(FPos);
      for i:=0 to integer(llen)-1 do
      begin
        case ltype and not rgList of
          rgBool: begin
            vali:=memReadInteger(FPos);
            if vali=0 then lls:='false' else lls:='true';
          end;
          rgInteger: begin
            vali:=memReadInteger(FPos);
            Str(vali,lls);
          end;
          rgUnsigned: begin
            valu:=memReadDWord(FPos);
            Str(valu,lls);
          end;
          rgFloat: begin
            lq.x:=memReadFloat(FPos);
            if ABS(lq.x)<1.0E-6 then
//              Str(lq.x,lls)
              Str(lq.x:0:DoublePrec,lls)
            else
              Str(lq.x:0:FloatPrec,lls);
            FixFloatStr(lls);
          end;
          rgInteger64: begin
            valq:=memReadInteger64(FPos)
          end;
          rgDouble: begin
            vald:=memReadDouble(FPos);
            Str(vald:0:DoublePrec,lls);
            FixFloatStr(lls);
          end;
        end;

        ls:=ls+lls+',';
      end;
      if ls<>'' then SetLength(ls,Length(ls)-1);
      AddString(anode,lname,Pointer(ls));
{
      pcw:=StrToWide(ls);
      AddString(anode,lname,pcw);
      FreeMem(pcw);
}
    end
    else
    begin
      AddInteger(anode,'??UNKNOWN',asize);
      AddString (anode,PWideChar('??'+WideString(lname)), PWideChar(WideString(HexStr(FPos-FStart,8))));
      RGLog.Add('Unknown property type '+IntToStr(ltype)+' size '+IntToStr(asize)+' at '+HexStr(FPos-FStart,8));
    end;
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
        if lint<=6 then
          pcw:=strInterpolation[lint]
        else
          pcw:=Pointer(WideString(IntToStr(lint)));

        AddString(tlpoint,'INTERPOLATION',pcw);

        if FVer=verTL2 then
        begin
          if ltltype=1 then
          begin
            pcw:=memReadShortString(FPos);
            AddString(tlpoint,'VALUE',pcw);
            FreeMem(pcw);
          end;
        end;

        if FVer in [verHob, verRG, verRGO] then
        begin
          pcw:=memReadShortStringUTF8(FPos);
          if pcw<>nil then
          begin
            ltltype:=1;
            AddString(tlpoint,'VALUE_1',pcw);
            FreeMem(pcw);
          end;

          // condition can be commented? Not for Hob!
          if (ltltype=0) or (ltltype=1) then
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
            RGLog.Add('Timeline '+IntToStr(aid)+
                ' event. Don''t know what to do. At '+HexStr(laptr-FStart,8));
          end;
        end;

      end;
    end;
  end;
end;

function SearchVector(aprops:pointer; aname:PWideChar; aletter:WideChar):pointer;
var
  buf:array [0..127] of WideChar;
  llen:integer;
begin
  llen:=Length(aname);
  move(aname^,buf[0],llen*SizeOf(WideChar));
  buf[llen]:=aletter;
  buf[llen+1]:=#0;
  result:=FindNode(aprops,buf);
end;

procedure TRGLayoutFile.WriteVectorValue(const vct:tVector4; atype:integer; astream:TStream);
begin
  case atype of
    rgVector2: begin
      astream.WriteFloat(vct.X);
      astream.WriteFloat(vct.Y);
    end;
    rgVector3: begin
      astream.WriteFloat(vct.X);
      astream.WriteFloat(vct.Y);
      astream.WriteFloat(vct.Z);
    end;
    rgVector4: begin
      astream.WriteFloat(vct.X);
      astream.WriteFloat(vct.Y);
      astream.WriteFloat(vct.Z);
      astream.WriteFloat(vct.W);
    end;
  end;
end;

function TRGLayoutFile.WritePropertyValue(anode:pointer; atype:integer; astream:TStream):integer;
var
  lval:array [0..31] of WideChar;
  lint64:Int64;
  ldouble:Double;
  lp:PWideChar;
  lfloat:Single;
  i,lcnt,lidx:integer;
  ltype:integer;
  ltmp:word;
begin
  result:=0;
        
  ltype:=GetNodeType(anode);
  // array
  if (ltype<>atype) and not (atype in [rgString,rgTranslate,rgNote]){and (ltype=rgString)} then
  begin
    lp:=AsString(anode);
    lcnt:=splitCountW(lp,',');
    if lcnt>0 then
    begin
      astream.WriteWord(WORD(lcnt));

      for i:=0 to lcnt-1 do
      begin
        lidx:=0;
        repeat
          while lp^=',' do inc(lp);
          lval[lidx]:=lp^;
          inc(lidx);
          inc(lp);
        until (lp^=',') or (lp^=#0);
        lval[lidx]:=#0;

        case atype of
          rgInteger  : begin Val(lval,lint64 ,ltmp); astream.WriteDWord(dword(lint64));  end;
          rgUnsigned : begin Val(lval,lint64 ,ltmp); astream.WriteDWord(dword(lint64));  end;
          rgInteger64: begin Val(lval,lint64 ,ltmp); astream.WriteQWord(qword(lint64));  end;
          rgFloat    : begin Val(lval,lfloat ,ltmp); astream.WriteFloat(lfloat);         end;
          rgDouble   : begin Val(lval,ldouble,ltmp); astream.WriteQWord(qword(ldouble)); end;
          rgBool     : begin
            if (lval[0]='1') or (
               (lval[0] in ['T','t']) and 
               (lval[0] in ['R','r']) and 
               (lval[0] in ['U','u']) and 
               (lval[0] in ['E','e'])) then
              astream.WriteDWord(1)
            else
              astream.WriteDWord(0);
          end;
        end;
      end;

    end;
  end
  else
  begin
    case ltype of
      rgInteger  : astream.WriteDWord(dword(asInteger(anode)));
      rgFloat    : astream.WriteFloat(asFloat(anode));
      rgDouble   : astream.WriteQWord(qword(asDouble(anode)));
      rgUnsigned : astream.WriteDWord(asUnsigned(anode));
      rgBool     : if AsBool(anode) then astream.WriteDWord(1) else astream.WriteDWord(0);
      rgInteger64: astream.WriteQWord(qword(asInteger64(anode)));
      rgString,
      rgTranslate,
      rgNote     : astream.WriteShortString(AsString(anode));
    end;
  end;
end;

function TRGLayoutFile.WriteProperties(anode:pointer; astream:TStream):integer;
var
  vct:tVector4;
  lpname:PWideChar;
  lprop:PByte;
  ltype:integer;
  l_id:dword;
  lSizePos,lNewPos:integer;
  i:integer;
  lok:boolean;
begin
  result:=0;

  for i:=0 to info.GetPropsCount()-1 do
  begin
    vct.x:=0;
    vct.y:=0;
    vct.z:=0;
    vct.w:=0;
    lok:=false;

    ltype:=info.GetPropInfoByIdx(i,l_id,lpname);
    case ltype of
      rgVector2: begin
//        lprop:=SearchVector(anode,lpname,'X'); if lprop<>nil then begin lok:=true; vct.X:=AsFloat(lprop); end;

        lprop:=SearchVector(anode,lpname,'X'); lok:=lok or (lprop<>nil); vct.X:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Y'); lok:=lok or (lprop<>nil); vct.Y:=AsFloat(lprop);
      end;
      rgVector3: begin
        lprop:=SearchVector(anode,lpname,'X'); lok:=lok or (lprop<>nil); vct.X:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Y'); lok:=lok or (lprop<>nil); vct.Y:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Z'); lok:=lok or (lprop<>nil); vct.Z:=AsFloat(lprop);
      end;
      rgVector4: begin
        lprop:=SearchVector(anode,lpname,'X'); lok:=lok or (lprop<>nil); vct.X:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Y'); lok:=lok or (lprop<>nil); vct.Y:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'Z'); lok:=lok or (lprop<>nil); vct.Z:=AsFloat(lprop);
        lprop:=SearchVector(anode,lpname,'W'); lok:=lok or (lprop<>nil); vct.W:=AsFloat(lprop);
      end;

    else
      lprop:=FindNode(anode,lpname);
      if lprop<>nil then
      begin
        lSizePos:=astream.Position;
        astream.WriteWord(0);
        case FVer of
          verTL2: begin
            astream.WriteByte(l_id);
            WritePropertyValue(lprop,ltype,astream);
          end;
          verHob,
          verRGO,
          verRG : begin
            astream.WriteDWord(l_id);
            WritePropertyValue(lprop,ltype,astream);
          end;
        end;
        lNewPos:=astream.Position;
        astream.Position:=lSizePos;
        astream.WriteWord(lNewPos-lSizePos-2);
        astream.Position:=lNewPos;
        inc(result);
      end;
    end;

    if lok then
    begin
      lSizePos:=astream.Position;
      astream.WriteWord(0);
      case FVer of
        verTL2: begin
          astream.WriteByte(l_id);
          WriteVectorValue(vct,ltype,astream);
        end;
        verHob,
        verRGO,
        verRG : begin
          astream.WriteDWord(l_id);
          WriteVectorValue(vct,ltype,astream);
        end;
      end;
      lNewPos:=astream.Position;
      astream.Position:=lSizePos;
      astream.WriteWord(lNewPos-lSizePos-2);
      astream.Position:=lNewPos;
      inc(result);
    end;

  end;

end;

procedure TRGLayoutFile.BuildTimeline(anode:pointer; astream:TStream);
var
  tlobject,tlprop,tlpoint:pointer;
  pcw:PWideChar;
  i,j,k,ltlpoints,ltlobjs,ltlprops:integer;
  lval,ltype:integer;
begin
  ltlobjs:=GetGroupCount(anode{,'TIMELINEOBJECT'});
  astream.WriteByte(ltlobjs);
  for i:=0 to GetChildCount(anode)-1 do
  begin
    tlobject:=GetChild(anode,i);
    if GetNodeType(tlobject)<>rgGroup then continue;

    astream.WriteQWord(qword(AsInteger64(FindNode(tlobject,'OBJECTID'))));

    ltlprops:=GetGroupCount(tlobject); // Properties and Events
    astream.WriteByte(ltlprops);
    for j:=0 to GetChildCount(tlobject)-1 do
    begin
      tlprop:=GetChild(tlobject,j);
      if GetNodeType(tlprop)<>rgGroup then continue;

      pcw:=GetNodeName(tlprop);
      if CompareWide(pcw,'TIMELINEOBJECTPROPERTY')=0 then
      begin
        ltype:=1;
        pcw:=AsString(FindNode(tlprop,'OBJECTPROPERTYNAME'));
        WriteStr(pcw,astream);
        WriteStr(nil,astream);
      end
      else// if CompareWide(pcw,'TIMELINEOBJECTEVENT')=0 then
      begin
        ltype:=2;
        pcw:=AsString(FindNode(tlprop,'OBJECTEVENTNAME'));
        WriteStr(nil,astream);
        WriteStr(pcw,astream);
      end;

      ltlpoints:=GetGroupCount(tlprop);
      astream.WriteByte(ltlpoints);
      for k:=0 to GetChildCount(tlprop)-1 do
      begin
        tlpoint:=GetChild(tlprop,k);
        if GetNodeType(tlpoint)<>rgGroup then continue;

        astream.WriteFloat(asFloat(FindNode(tlpoint,'TIMEPERCENT')));
        pcw:=AsString(FindNode(tlpoint,'INTERPOLATION'));

        lval:=0;
        while lval<=6 do
        begin
          if CompareWide(pcw,strInterpolation[lval])=0 then break;
          inc(lval);
        end;
        astream.WriteByte(lval);

        if (FVer=verTL2) and (ltype=1) then
          astream.WriteShortString(AsString(FindNode(tlpoint,'VALUE')));

        if FVer in [verHob, verRG, verRGO] then
        begin
//          astream.WriteShortStringUTF8(AsString(FindNode(tlpoint,'VALUE_1')));
//          astream.WriteShortStringUTF8(AsString(FindNode(tlpoint,'VALUE')));
        end;

      end;
    end;
  end;
end;

procedure TRGLayoutFile.BuildLogicGroup(anode:pointer; astream:TStream);
var
  lgobj,lglnk:pointer;
  i,j,lgroups,lglinks,lpos,lnewpos:integer;
begin
  lgroups:=GetChildCount(anode);
  astream.WriteByte(lgroups);

  for i:=0 to lgroups-1 do
  begin
    lgobj:=GetChild(anode,i);

    astream.WriteByte (AsUnsigned(FindNode(lgobj,'ID')));
    astream.WriteQWord(qword(AsInteger64(FindNode(lgobj,'OBJECTID'))));
    astream.WriteFloat(AsFloat(FindNode(lgobj,'X')));
    astream.WriteFloat(AsFloat(FindNode(lgobj,'Y')));

    lpos:=astream.Position;
    astream.WriteDword(0);

    lglinks:=GetGroupCount(lgobj{,'LOGICLINK'});
    astream.WriteByte(lglinks);

    for j:=0 to GetChildCount(lgobj)-1 do
    begin
      lglnk:=GetChild(lgobj,j);

      if GetNodeType(lglnk)=rgGroup then
      begin
        astream.WriteByte(Byte(AsInteger(FindNode(lglnk,'LINKINGTO'))));
        case FVer of
          verTL2: begin
            astream.WriteShortString(AsString(FindNode(lglnk,'OUTPUTNAME')));
            astream.WriteShortString(AsString(FindNode(lglnk,'INPUTNAME' )));
          end;
          verHob,
          verRGO,
          verRG : begin
            astream.WriteDWord(RGTags.Hash[AsString(FindNode(lglnk,'OUTPUTNAME'))]);
            astream.WriteDWord(RGTags.Hash[AsString(FindNode(lglnk,'INPUTNAME' ))]);
          end;
        end;
      end;
    end;

    lnewpos:=astream.Position;
    astream.Position:=lpos;
    astream.WriteDWord(lnewpos);
    astream.Position:=lnewpos;
  end;
end;

{$Include lay_tl1.inc}

{$Include lay_tl2.inc}

{$Include lay_hob.inc}

function IsProperLayout(abuf:pByte):boolean; inline;
begin
  result:=abuf^ in [5, 8, 9, 11, $5A];
end;

function GetLayoutVersion(abuf:PByte):integer;
begin
  if abuf<>nil then
    case abuf^ of
      5  : exit(verRG);
      8  : exit(verHob);
      9  : exit(verRGO);
      11 : exit(verTL2);
      $5A: exit(verTL1);
    end;

  result:=verUnk;
end;

function GetLayoutType(fname:PUnicodeChar):cardinal;
var
  ls:UnicodeString;
  i:integer;
begin
  if fname<>'' then
  begin
    ls:=UnicodeString(fname);
    for i:=1 to Length(ls) do
    begin
      if ls[i]='\' then
        ls[i]:='/'
      else
        ls[i]:=UpCase(ls[i]);
    end;

    if      pos('MEDIA/UI'       ,ls)>0 then exit(ltUI)
    else if pos('MEDIA/PARTICLES',ls)>0 then exit(ltParticle);
  end;
  result:=ltLayout;
end;

function GetLayoutType(const afname:string):cardinal;
var
  ls:string;
  i:integer;
begin
  if afname<>'' then
  begin
    ls:=afname;
    for i:=1 to Length(ls) do
    begin
      if ls[i]='\' then
        ls[i]:='/'
      else
        ls[i]:=UpCase(ls[i]);
    end;

    if      pos('MEDIA/UI'       ,ls)>0 then exit(ltUI)
    else if pos('MEDIA/PARTICLES',ls)>0 then exit(ltParticle);
  end;
  result:=ltLayout;
end;

function ParseLayoutMem(abuf:pByte; atype:cardinal=ltLayout):pointer;
var
  lrgl:TRGLayoutFile;

begin
  lrgl.Init;

  lrgl.FStart:=abuf;
  lrgl.FPos  :=abuf;

  if atype>2 then atype:=0;

  case abuf^ of
    5  : begin lrgl.FVer:=verRG ; result:=lrgl.DoParseLayoutRG (atype); end;
    8  : begin lrgl.FVer:=verHob; result:=lrgl.DoParseLayoutHob(atype); end;
    9  : begin lrgl.FVer:=verRGO; result:=lrgl.DoParseLayoutRG (atype); end; //!!!!!!!!
    11 : begin lrgl.FVer:=verTL2; result:=lrgl.DoParseLayoutTL2(atype); end;
    $5A: begin lrgl.FVer:=verTL1; result:=lrgl.DoParseLayoutTL1(atype); end;
  else
    result:=nil;
  end;

  lrgl.Free;
end;

function ParseLayoutMem(abuf:pByte; const afname:string):pointer;
begin
  if afname<>'' then RGLog.Reserve('Processing '+afname);

  result:=ParseLayoutMem(abuf,GetLayoutType(afname));
end;

function ParseLayoutStream(astream:TStream; atype:cardinal=ltLayout):pointer;
var
  lbuf:PByte;
begin
  if (astream is TMemoryStream) then
  begin
    result:=ParseLayoutMem((astream as TMemoryStream).Memory,atype);
  end
  else
  begin
    GetMem(lbuf,astream.Size);
    aStream.Read(lbuf^,astream.Size);
    result:=ParseLayoutMem(lbuf,atype);
    FreeMem(lbuf);
  end;
end;

function ParseLayoutStream(astream:TStream; const afname:string):pointer;
begin
  if afname<>'' then RGLog.Add('Processing '+afname);

  result:=ParseLayoutStream(astream,GetLayoutType(afname));
end;

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


function BuildLayoutStream(data:pointer; astream:TStream; aver:byte=verTL2):integer;
var
  lrgl:TRGLayoutFile;
begin
  result:=0;
  lrgl.Init;
  lrgl.FVer:=aver;
  case aver of
    verRG : result:=lrgl.DoBuildLayoutRG (data, astream);
    verHob: result:=lrgl.DoBuildLayoutHob(data, astream);
    verRGO: result:=lrgl.DoBuildLayoutRG (data, astream);
    verTL2: result:=lrgl.DoBuildLayoutTL2(data, astream);
    verTL1: result:=lrgl.DoBuildLayoutTL1(data, astream);
  end;
  lrgl.Free;
end;

function BuildLayoutMem(data:pointer; out bin:pByte; aver:byte=verTL2):integer;
var
  ls:TMemoryStream;
begin
  result:=0;
  ls:=TMemoryStream.Create;
  try
    result:=BuildLayoutStream(data,ls,aver);
    GetMem(bin,result);
    move(ls.Memory^,bin^,result);
  finally
    ls.Free;
  end;
end;

function BuildLayoutFile(data:pointer; const fname:AnsiString; aver:byte=verTL2):integer;
var
  ls:TMemoryStream;
begin
  ls:=TMemoryStream.Create;
  try
    result:=BuildLayoutStream(data,ls,aver);
    ls.SaveToFile(fname);
  finally
    ls.Free;
  end;
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
