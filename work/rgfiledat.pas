{
save another type copy or not
keep UTF8 and UTF16 at same time?
}
unit RGFileDat;

interface

uses
  Classes,
  rgglobal,
  rgfilebase,
  rgdict;

type
  TRGDATFile = object(TRGFileBase)
  private
    FLocals:TRGDict;
    FDictIndex:integer;

  private
    function  GetStr(aid:dword):PWideChar;
    procedure ParseBlock(var anode:pointer; var aptr:PByte);
    function  ParseFile ():integer;
    procedure CompileBlock(st:TStream; adata:pointer);
    function  CompileFile (aStream:TStream):integer;

  public
    procedure Init(aOpts:TRGFileBaseOpts=[dfoKeepData]);

    property  DictIndex:integer read FDictIndex write FDictIndex;
  end;

function ParseDat(abuf:pByte         ):pointer;
function ParseDat(const afname:string):pointer;

function CompileDat(data:pointer          ; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;
function CompileDat(const fname:AnsiString; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;


implementation

uses
  SysUtils,

  rgmemory,
  rgnode,
  rglogging;

var
  known,unkn:TRGDict;
var
  aliases:TRGDict;

{%REGION DAT decode}

function TRGDATFile.GetStr(aid:dword):PWideChar;
begin
  if FVer=verTL1 then
  begin
    result:=FLocals.Tag[aid];
    exit;
  end;

  result:=aliases.Tag[aid];

  if result=nil then
    result:=RGTags.Tag[aid];

  if result=nil then
  begin
    RGLog.Add('Unknown tag with hash '+IntToStr(aid));

    Str(aid,FBuffer);
    result:=pointer(FBuffer);

    unkn.add(aid,nil);
  end
  else
    known.add(aid,result);
end;

procedure TRGDATFile.ParseBlock(var anode:pointer; var aptr:PByte);
var
  lnode:pointer;
  lname:PWideChar;
  i,lcnt,lsub,ltype:integer;
begin
  lnode:=AddGroup(anode,GetStr(memReadDWord(aptr)));
  if anode=nil then anode:=lnode;

  lcnt:=memReadInteger(aptr);
  for i:=0 to lcnt-1 do
  begin
    lname:=GetStr (memReadDWord(aptr));
    ltype:=integer(memReadDword(aptr));

    case ltype of
		  rgInteger  : AddInteger  (lnode,lname,memReadInteger  (aptr));
		  rgUnsigned : AddUnsigned (lnode,lname,memReadDWord    (aptr));
		  rgBool     : AddBool     (lnode,lname,memReadInteger  (aptr)<>0);
		  rgFloat    : AddFloat    (lnode,lname,memReadFloat    (aptr));
		  rgDouble   : AddDouble   (lnode,lname,memReadDouble   (aptr));
		  rgInteger64: AddInteger64(lnode,lname,memReadInteger64(aptr));
		  rgString   : AddString   (lnode,lname,FLocals.Tag[memReadDWord(aptr)]);
		  rgTranslate: AddTranslate(lnode,lname,FLocals.Tag[memReadDWord(aptr)]);
		  rgNote     : AddNote     (lnode,lname,FLocals.Tag[memReadDWord(aptr)]);
		else
      lsub:=memReadInteger(aptr);
		  AddCustom(lnode,lname,
		      PWideChar(WideString(IntToStr(lsub ))),  //!!!!!!!!
		      PWideChar(WideString(IntToStr(ltype)))); //!!!!!!!!
		  RGLog.Add('Non-standard tag '+IntToStr(ltype)+' with possible value '+IntToStr(lsub));
    end;
  end;

  lsub:=memReadInteger(aptr);
  for i:=0 to lsub-1 do
    ParseBlock(lnode,aptr);
end;

function TRGDATFile.ParseFile():integer;
var
  pc:PWideChar;
  lptr:PByte;
  lid:dword;
  lcnt,i:integer;
begin
  lptr:=FData;

  case lptr^ of
    1: begin FVer:=verTL1; inc(lptr,3); end;
    2: begin FVer:=verTL2; inc(lptr,3); end;
    6: begin FVer:=verHob; inc(lptr  ); end;
  else
    exit(-1);
  end;

  lcnt:=memReadInteger(lptr);
  if lcnt<0 then
  begin
    RGLog.Add('Dictionary size < 0');
    exit(0);
  end;

  FLocals.Init;
  FLocals.Capacity:=lcnt;

  for i:=0 to lcnt-1 do
  begin
    lid:=memReadDWord(lptr);
    case FVer of
      verTL1: pc:=memReadDwordString(lptr);
      verTL2: pc:=memReadShortString(lptr);
      verHob,
      verRGO,
      verRG : pc:=memReadShortStringUTF8(lptr);
    end;
    FLocals.Add(lid,pc,true);
  end;

  ParseBlock(FNode,lptr);

  FLocals.Clear;
end;

{%ENDREGION}

{%REGION DAT encode}

procedure TRGDATFile.CompileBlock(st:TStream; adata:pointer);
var
  lptr:pByte;
  i,cnt,sub,ltype:integer;
  lidx:dword;
begin
  // write name

  if FVer=verTL1 then
  begin
    lidx:=FLocals.Add(FDictIndex,GetNodeName(adata));
    if lidx=FDictIndex then inc(FDictIndex);
    st.WriteDWord(lidx);
  end
  else
    st.WriteDWord(RGTags.Hash[GetNodeName(adata)]);

  // write properties

  cnt:=GetChildCount(adata);
  sub:=GetChildGroupCount(adata);

  // count
  st.WriteDWord(cnt-sub);
  for i:=0 to cnt-1 do
  begin
    lptr:=GetChild(adata,i);
    ltype:=GetNodeType(lptr);
    if ltype in [rgInteger..rgNote] then
    begin
      // name
      if FVer=verTL1 then
      begin
        lidx:=FLocals.Add(FDictIndex,GetNodeName(lptr));
        if lidx=FDictIndex then inc(FDictIndex);
        st.WriteDWord(lidx);
      end
      else
        st.WriteDWord(RGTags.Hash[GetNodeName(lptr)]);
      // type
      st.WriteDWord(ltype);
      // value
      case ltype of
        rgInteger  : st.WriteDWord(dword(AsInteger  (lptr)));
        rgFloat    : st.WriteDWord(dword(AsFloat    (lptr)));
        rgDouble   : st.WriteQWord(qword(AsDouble   (lptr)));
        rgUnsigned : st.WriteDWord(      AsUnsigned (lptr));
        rgInteger64: st.WriteQWord(qword(AsInteger64(lptr)));
        rgBool     : if AsBool(lptr) then st.WriteDWord(1) else st.WriteDWord(0);

        rgString   : begin
          lidx:=FLocals.Add(FDictIndex,AsString(lptr));
          if lidx=FDictIndex then inc(FDictIndex);
          st.WriteDWord(lidx);
        end;
        rgNote     : begin
          lidx:=FLocals.Add(FDictIndex,AsNote(lptr));
          if lidx=FDictIndex then inc(FDictIndex);
          st.WriteDWord(lidx);
        end;
        rgTranslate: begin
          lidx:=FLocals.Add(FDictIndex,AsTranslate(lptr));
          if lidx=FDictIndex then inc(FDictIndex);
          st.WriteDWord(lidx);
        end;
      end;
    end;
  end;

  // write children

  st.WriteDWord(word(sub));
  if sub>0 then
    for i:=0 to cnt-1 do
    begin
      lptr:=GetChild(adata,i);
      if GetNodeType(lptr)=rgGroup then
      begin
        CompileBlock(st,lptr);
        dec(sub);
        if sub=0 then break;
      end;
    end;

end;

function TRGDATFile.CompileFile(aStream:TStream):integer;
var
  lstream:TMemoryStream;
  p:PWideChar;
  a:UTF8String;
  i,j:integer;
begin
  result:=aStream.Position;

  case ABS(FVer) of
    verTL1: aStream.WriteDWord(1);
    verTL2: aStream.WriteDWord(2);
    verHob,
    verRGO,
    verRG : aStream.WriteByte(6);
  else
    exit(0);
  end;

  // create text list
  FLocals.Init;
  FLocals.Options:=[check_text];

  // write block to temporal buffer
  lstream:=TMemoryStream.Create();
  CompileBlock(lstream,FNode);

  // write list
  a:=Default(UTF8String);
  aStream.WriteDword(FLocals.Count);
  for i:=0 to FLocals.Count-1 do
  begin
    aStream.WriteDWord(FLocals.IdxHash[i]);
    p:=FLocals.IdxTag[i];
    j:=Length(p);
    case ABS(FVer) of
      verTL1: begin
        aStream.WriteDWord(j);
        aStream.Write(p^,j*SizeOf(WideChar));
      end;
      verTL2: begin
        aStream.WriteWord(j);
        aStream.Write(p^,j*SizeOf(WideChar));
      end;
      verHob,
      verRGO,
      verRG : begin
        if Length(a)<(j*3) then SetLength(a,j*3);
        j:=UnicodeToUtf8(PAnsiChar(a),Length(a)+1,p,j);
        aStream.WriteWord(j);
        aStream.Write(PAnsiChar(a)^,j);
      end;
    end;
  end;
  FLocals.Clear;

  // write data
  lstream.Position:=0;
  aStream.CopyFrom(lstream,lstream.Size);
  lstream.Free;

  result:=aStream.Position-result;
end;

{%ENDREGION}

{%REGION TRGDATFile publics}

procedure TRGDATFile.Init(aOpts:TRGFileBaseOpts=[dfoKeepData]);
begin
  inherited Init(aOpts);

  Parse:=@ParseFile;
  Compile:=nil;
  CompileToStream:=@CompileFile;

  FDictIndex:=0;
end;

{%ENDREGION}

{%REGION Functions}

function ParseDat(abuf:pByte):pointer;
var
  lrgd:TRGDATFile;
begin
  lrgd.Init([]);
  lrgd.LoadFromMemory(abuf);
  result:=lrgd.Node;
  lrgd.Free;
end;

function ParseDat(const afname:string):pointer;
begin
end;

function CompileDat(data:pointer; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;
begin
end;

function CompileDat(const fname:AnsiString; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;
begin
end;

{%ENDREGION}

{%REGION Initialization}

initialization

  aliases.Init;
  aliases.Import('dataliases.txt');

  known.init;
  known.options:=[check_hash];

  unkn.init;
  unkn.options:=[check_hash];

finalization

{$IFDEF DEBUG}  
  if known.count>0 then
  begin
    known.Sort;
    known.export('known-dat.dict'    ,false);
    known.export('known-dat-txt.dict',false,false);
  end;
{$ENDIF}
  known.clear;

{$IFDEF DEBUG}  
  if unkn.count>0 then
  begin
    unkn.Sort;
    unkn.export('unknown-dat.dict',false);
  end;
{$ENDIF}
  unkn.clear;
  
  aliases.Clear;

{%ENDREGION}

end.
