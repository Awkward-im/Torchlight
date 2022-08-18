{
save another type copy or not
keep UTF8 and UTF16 at same time?
}
unit RGIO.DAT;

interface

uses
  Classes,
  rgglobal;

function ParseDatMem   (abuf        :pByte  ):pointer;
function ParseDatStream(astream     :TStream):pointer;
function ParseDatFile  (const afname:string ):pointer;

function BuildDatMem   (data:pointer; out   bin    :pByte     ; aver:byte=verTL2; dictidx:integer=-1):integer;
function BuildDatStream(data:pointer;       astream:TStream   ; aver:byte=verTL2; dictidx:integer=-1):integer;
function BuildDatFile  (data:pointer; const fname  :AnsiString; aver:byte=verTL2; dictidx:integer=-1):integer;


implementation

uses
  SysUtils,

  dict,
  rwmemory,
  logging,

  rgdict,
  rgnode;

{$IFDEF DEBUG}  
var
  known,unkn:TRGDict;
{$ENDIF}
var
  aliases:TRGDict;

type
  TRGDATFile = object
  private
    FVer :integer;
    FBuffer:WideString;
    FLocals:TRGDict;
    FDictIndex:integer;

  private
    function  GetStr(aid:dword):PWideChar;
    procedure ParseBlock (var aptr:PByte; var anode:pointer);
    function  ParseBuffer(    abuf:PByte; out anode:pointer):integer;
    procedure BuildBlock (aStream:TStream; anode:pointer);
    function  BuildStream(aStream:TStream; anode:pointer):integer;

  public
    procedure Init;
    procedure Free;

    property  DictIndex:integer read FDictIndex write FDictIndex;
  end;

{%REGION DAT decode}

function TRGDATFile.GetStr(aid:dword):PWideChar;
var
  pc:PWideChar;
  lhash:dword;
  i:integer;
begin
  if FVer=verTL1 then
  begin
    result:=FLocals.Tag[aid];
    exit;
  end;

  result:=aliases.Tag[aid];

  if result=nil then
    result:=RGTags.Tag[aid];

  // like UNITTYPES directory
  // looks like TL read 'NAME' tag value for it
  if result=nil then
  begin
    for i:=0 to FLocals.Count-1 do
    begin
      pc:=FLocals.Tags[i];
      lhash:=RGHash(pc);
      if aid=lhash then
      begin
        aliases.Add(pc,lhash);
        result:=pc;
        break;
      end;
    end;
  end;

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

procedure TRGDATFile.ParseBlock(var aptr:PByte; var anode:pointer);
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
    ParseBlock(aptr,lnode);
end;

function TRGDATFile.ParseBuffer(abuf:PByte; out anode:pointer):integer;
var
  pc:PWideChar;
  lptr:PByte;
  lid:dword;
  lcnt,i:integer;
begin
  anode:=nil;

  lptr:=abuf;

  case lptr^ of
    1: begin FVer:=verTL1; inc(lptr,4); end;
    2: begin FVer:=verTL2; inc(lptr,4); end;
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
    else
      pc:=nil;
    end;
    FLocals.Add(pc,lid);
    FreeMem(pc);
  end;

  anode:=nil;
  ParseBlock(lptr,anode);

  FLocals.Clear;
end;

{%ENDREGION}

{%REGION DAT encode}

procedure TRGDATFile.BuildBlock(aStream:TStream; anode:pointer);
var
  lptr:pByte;
  i,cnt,sub,ltype:integer;
  lidx:dword;
begin
  // write name

  if FVer=verTL1 then
  begin
    lidx:=FLocals.Add(GetNodeName(anode),FDictIndex);
    if lidx=FDictIndex then inc(FDictIndex);
    aStream.WriteDWord(lidx);
  end
  else
    aStream.WriteDWord(RGTags.Hash[GetNodeName(anode)]);

  // write properties

  cnt:=GetChildCount(anode);
  sub:=GetGroupCount(anode);

  // count
  aStream.WriteDWord(cnt-sub);
  for i:=0 to cnt-1 do
  begin
    lptr:=GetChild(anode,i);
    ltype:=GetNodeType(lptr);
    if ltype in [rgInteger..rgNote] then
    begin
      // name
      if FVer=verTL1 then
      begin
        lidx:=FLocals.Add(GetNodeName(lptr),FDictIndex);
        if lidx=FDictIndex then inc(FDictIndex);
        aStream.WriteDWord(lidx);
      end
      else
        aStream.WriteDWord(RGTags.Hash[GetNodeName(lptr)]);
      // type
      aStream.WriteDWord(ltype);
      // value
      case ltype of
        rgInteger  : aStream.WriteDWord(dword(AsInteger  (lptr)));
        rgFloat    : aStream.WriteDWord(dword(AsFloat    (lptr)));
        rgDouble   : aStream.WriteQWord(qword(AsDouble   (lptr)));
        rgUnsigned : aStream.WriteDWord(      AsUnsigned (lptr));
        rgInteger64: aStream.WriteQWord(qword(AsInteger64(lptr)));
        rgBool     : if AsBool(lptr) then aStream.WriteDWord(1) else aStream.WriteDWord(0);

        rgString   : begin
          lidx:=FLocals.Add(AsString(lptr),FDictIndex);
          if lidx=FDictIndex then inc(FDictIndex);
          aStream.WriteDWord(lidx);
        end;
        rgNote     : begin
          lidx:=FLocals.Add(AsNote(lptr),FDictIndex);
          if lidx=FDictIndex then inc(FDictIndex);
          aStream.WriteDWord(lidx);
        end;
        rgTranslate: begin
          lidx:=FLocals.Add(AsTranslate(lptr),FDictIndex);
          if lidx=FDictIndex then inc(FDictIndex);
          aStream.WriteDWord(lidx);
        end;
      end;
    end;
  end;

  // write children

  aStream.WriteDWord(word(sub));
  if sub>0 then
    for i:=0 to cnt-1 do
    begin
      lptr:=GetChild(anode,i);
      if GetNodeType(lptr)=rgGroup then
      begin
        BuildBlock(aStream,lptr);
        dec(sub);
        if sub=0 then break;
      end;
    end;

end;

function TRGDATFile.BuildStream(aStream:TStream; anode:pointer):integer;
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
  BuildBlock(lstream,anode);

  // write list
  a:=Default(UTF8String);
  aStream.WriteDword(FLocals.Count);
  for i:=0 to FLocals.Count-1 do
  begin
    aStream.WriteDWord(FLocals.Hashes[i]);
    p:=FLocals.Tags[i];
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

procedure TRGDATFile.Init;
begin

  FDictIndex:=0;
end;

procedure TRGDATFile.Free;
begin
end;

{%ENDREGION}

{%REGION Functions}

function ParseDatMem(abuf:pByte):pointer;
var
  lrgd:TRGDATFile;
begin
  lrgd.Init();
  lrgd.ParseBuffer(abuf,result);
  lrgd.Free;
end;

function ParseDatStream(astream:TStream):pointer;
var
  lbuf:PByte;
begin
  GetMem(lbuf,astream.Size);
  aStream.Read(lbuf^,astream.Size);
  result:=ParseDatMem(lbuf);
  FreeMem(lbuf);
end;

function ParseDatFile(const afname:string):pointer;
var
  f:file of byte;
  lbuf:PByte;
  lsize:integer;
begin
  result:=nil;
  Assign(f,afname);
  Reset(f);
  if IOResult=0 then
  begin
    lsize:=FileSize(f);
    GetMem(lbuf,lsize);
    BlockRead(f,lbuf^,lsize);
    Close(f);
    result:=ParseDatMem(lbuf);
    FreeMem(lbuf);
  end;
end;

function BuildDatMem(data:pointer; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;
var
  ls:TMemoryStream;
begin
  result:=0;
  ls:=TMemoryStream.Create;
  try
    result:=BuildDatStream(data,ls,aver,dictidx);
    GetMem(bin,result);
    move(ls.Memory^,bin^,result);
  finally
    ls.Free;
  end;
end;

function BuildDatStream(data:pointer; astream:TStream; aver:byte=verTL2; dictidx:integer=-1):integer;
var
  lrgd:TRGDATFile;
begin
  result:=0;
  lrgd.Init;
  lrgd.FVer:=aver; //!!!!
  lrgd.BuildStream(astream,data);
  lrgd.Free;
end;

function BuildDatFile(data:pointer; const fname:AnsiString; aver:byte=verTL2; dictidx:integer=-1):integer;
var
  ls:TMemoryStream;
begin
  ls:=TMemoryStream.Create;
  try
    result:=BuildDatStream(data,ls,aver,dictidx);
    ls.SaveToFile(fname);
  finally
    ls.Free;
  end;
end;


{%ENDREGION}

{%REGION Initialization}

initialization

  aliases.Init;
  aliases.Import('dataliases.txt');

{$IFDEF DEBUG}  
  known.init;
  known.options:=[check_hash];

  unkn.init;
  unkn.options:=[check_hash];
{$ENDIF}

finalization

{$IFDEF DEBUG}  
  if known.count>0 then
  begin
    known.Sort;
    known.export('known-dat.dict'    ,asText);
    known.export('known-dat-txt.dict',asText,false);
  end;
  known.clear;

  if unkn.count>0 then
  begin
    unkn.Sort;
    unkn.export('unknown-dat.dict',asText);
  end;
  unkn.clear;
{$ENDIF}
  
  aliases.Clear;

{%ENDREGION}

end.
