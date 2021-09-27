{
save another type copy or not
keep UTF8 and UTF16 at same time?
}
unit RGDat;

interface

uses
  Classes,
  rgdict;

type
  TRGDATFile = object
  public
    type
      TRGDATFileOpts = set of (dfoKeepData);
  private
    FData:PByte;
    FText:PWideChar;
    FNode:pointer;
    FVer :integer;
    FOpts:TRGDATFileOpts;

    FLocals:TRGDict;
    FBuffer:WideString;

    function GetData(ver:integer):pointer;
    function GetText():PWideChar;
    function GetUTF8():string;

    procedure SetData(abuf:pointer);
    procedure SetData(ver:integer; abuf:pointer);
    procedure SetText(atext:PWideChar);
    procedure SetUTF8(const atext:string);

  private
    function  GetStr(aid:dword):PWideChar;
    procedure ParseBlock(var anode:pointer; var aptr:PByte);
    procedure ParseFile(abuf:PByte);
    procedure CompileBlock(st:TStream; adata:pointer; var aidx:dword);
    function  CompileFile(aStream:TStream; dictidx:integer=-1):integer;

  public
    procedure Init(aOpts:TRGDATFileOpts=[dfoKeepData]);
    procedure Clear;
    procedure Free;

    // auto recognize type by version and BOM
    function LoadFromFile  (const afile:string):boolean;
    function LoadFromStream(aStream:TStream   ):boolean;
    function LoadFromMemory(abuf:PByte; asize:cardinal=0; useIt:boolean=false):boolean;

    // write text with BOM
    function SaveToFile  (const afile:string; aver:integer):integer;
    function SaveToStream(aStream:TStream   ; aver:integer):integer;
    function SaveToMemory(out abuf:PByte    ; aver:integer):integer;

    // ignore "ver" on write, get it from data directly
    property Data[ver:integer]:pointer read GetData write SetData;
    // return without BOM
    property Text:PWideChar read GetText write SetText;
    property UTF8:string    read GetUTF8 write SetUTF8;
  end;


implementation

uses
  SysUtils,

  rgglobal,
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

procedure TRGDATFile.ParseFile(abuf:PByte);
var
  pc:PWideChar;
  lptr:PByte;
  lid:dword;
  lcnt,i:integer;
begin
  lptr:=abuf;

  case lptr^ of
    1: begin FVer:=verTL1; inc(lptr,3); end;
    2: begin FVer:=verTL2; inc(lptr,3); end;
    6: begin FVer:=verHob; inc(lptr  ); end;
  end;

  lcnt:=memReadInteger(lptr);
  if lcnt<0 then
    RGLog.Add('Dictionary size < 0');

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

procedure TRGDATFile.CompileBlock(st:TStream; adata:pointer; var aidx:dword);
var
  lptr:pByte;
  i,cnt,sub,ltype:integer;
  lidx:dword;
begin
  // write name

  if FVer=verTL1 then
  begin
    lidx:=FLocals.Add(aidx,GetNodeName(adata));
    if lidx=aidx then inc(aidx);
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
        lidx:=FLocals.Add(aidx,GetNodeName(lptr));
        if lidx=aidx then inc(aidx);
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
          lidx:=FLocals.Add(aidx,AsString(lptr));
          if lidx=aidx then inc(aidx);
          st.WriteDWord(lidx);
        end;
        rgNote     : begin
          lidx:=FLocals.Add(aidx,AsNote(lptr));
          if lidx=aidx then inc(aidx);
          st.WriteDWord(lidx);
        end;
        rgTranslate: begin
          lidx:=FLocals.Add(aidx,AsTranslate(lptr));
          if lidx=aidx then inc(aidx);
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
        CompileBlock(st,lptr,aidx);
        dec(sub);
        if sub=0 then break;
      end;
    end;

end;

function TRGDATFile.CompileFile(aStream:TStream; dictidx:integer=-1):integer;
var
  lstream:TMemoryStream;
  p:PWideChar;
  a:UTF8String;
  i,j:integer;
  lidx:dword;
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
  lidx:=dword(dictidx);
  lstream:=TMemoryStream.Create();
  CompileBlock(lstream,FNode,lidx);

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

procedure TRGDATFile.Init(aOpts:TRGDATFileOpts=[dfoKeepData]);
begin
  FOpts:=aOpts;
  FData:=nil;
  FText:=nil;
  FNode:=nil;

  FLocals.Init;
end;

procedure TRGDATFile.Clear;
begin
  if FData<>nil then FreeMem   (FData); FData:=nil;
  if FText<>nil then FreeMem   (FText); FText:=nil;
  if FNode<>nil then DeleteNode(FNode); FNode:=nil;

  FLocals.Clear;
end;

procedure TRGDATFile.Free;
begin
  Clear;
end;


function TRGDATFile.LoadFromFile(const afile:string):boolean;
var
  f:file of byte;
  lsize:integer;
begin
  Clear;
  result:=false;

  AssignFile(f,afile);
  Reset(f);
  if IOResult=0 then
  begin
    lsize:=FileSize(f);

    GetMem(FData,lsize+SizeOf(WideChar));
    BlockRead(f,FData^,lsize);
    CloseFile(f);
    FData[lsize  ]:=0;
    FData[lsize+1]:=0;

    result:=LoadFromMemory(FData,lsize,true);
  end;
end;

function TRGDATFile.LoadFromStream(aStream:TStream):boolean;
var
  lsize:integer;
begin
  Clear;
  lsize:=aStream.Size;
  if lsize=0 then
    exit(false);

  GetMem(FData,lsize+SizeOf(WideChar));
  aStream.Read(FData^,lsize);
  FData[lsize  ]:=0;
  FData[lsize+1]:=0;

  result:=LoadFromMemory(FData,lsize,true);
end;

function TRGDATFile.LoadFromMemory(abuf:PByte; asize:cardinal=0; useIt:boolean=false):boolean;
var
  s :WideString;
  ls:AnsiString;
  lpc:PWideChar;
begin
  Clear;
  result:=false;

  if asize=0 then asize:=MemSize(abuf);

  // Binary
  if abuf^ in [1,2,6] then
  begin
    ParseFile(abuf);

    if dfoKeepData in FOpts then
    begin
      if useIt then
        FData:=abuf
      else
      begin
        GetMem(FData,asize);
        move(abuf^,FData^,asize);
      end;
    end
    else if useIt then
      FreeMem(abuf);
  end

  // UTF16 text
  else if (abuf[0]=$FF) and (abuf[1]=$FE) then
  begin
    FVer:=CP_UTF16;

    if (abuf[asize-2]<>0) or (abuf[asize-1]<>0) then
    begin
      FText:=CopyWide(PWideChar(abuf+2),asize div 2);
      lpc:=FText;
    end
    else if dfoKeepData in FOpts then
    begin
      FText:=CopyWide(PWideChar(abuf+2));
      lpc:=FText;
    end
    else
      lpc:=PWideChar(abuf+2);

    ParseDat(lpc);

    if (FText<>nil) and not (dfoKeepData in FOpts) then
    begin
      FreeMem(FText);
      FText:=nil;
    end;

    if useIt then FreeMem(abuf);
  end

  // UTF8 text
  else if (abuf[0]=$EF) and (abuf[1]=$BB) and (abuf[2]=$BF) then
  begin
    FVer:=CP_UTF16;

    if abuf[asize-1]<>0 then
    begin
      SetString(ls,PAnsiChar(abuf+3),asize-3);
      s:=UTF8Decode(ls);
    end
    else
      s:=UTF8ToString(PAnsiChar(abuf+3));

    ParseDat(PWideChar(s));

    if dfoKeepData in FOpts then
      FText:=CopyWide(PWideChar(s));

    if useIt then FreeMem(abuf);
  end

  else
  begin
    RGLog.Add('Unknown file version: '+IntToStr(abuf[0]));
    if useIt then FreeMem(abuf);
  end;

end;


function TRGDATFile.SaveToFile(const afile:string; aver:integer):integer;
var
  lstream:TMemoryStream;
//  f:file of byte;
begin
  lstream:=TMemoryStream.Create();
  try
    result:=SaveToStream(lstream,aver);
    lstream.SaveToFile(afile);
  finally
    lstream.Free;
  end;
{  
  if result>0 then
  begin
    AssignFile(f,afile);
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,FData^,result);
      CloseFile(f);
    end
    else
      result:=-1;
  end;
}
end;

function TRGDATFile.SaveToStream(aStream:TStream; aver:integer):integer;
var
  s:UTF8String;
begin
  result:=-1;

  FVer:=aver;
  if ABS(aver) in [verTL1, verTL2, verHob, verRG, verRGO] then
  begin
    result:=CompileFile(aStream); //!!idx??
  end

  else if aver=CP_UTF16 then
  begin
    if FText=nil then
      MakeDatTree(FNode,FText); //!! let think  - no BOM

    if FText<>nil then
    begin
      //!! plus BOM
      result:=Length(FText)*SizeOf(WideChar)+2;
      aStream.WriteWord($FEFF);
      aStream.Write(FText^,result-2);

      if not (dfoKeepData in FOpts) then
      begin
        FreeMem(FText); FText:=nil;
      end;
    end;
  end

  else if aver=CP_UTF8 then
  begin
    if FText=nil then
      MakeDatTree(FNode,FText); //!! let think  - no BOM
    
    if FText<>nil then
    begin
      s:=UTF8Encode(WideString(FText));
      //!! plus BOM
      result:=Length(s)+3;
      aStream.WriteByte($EF);
      aStream.WriteWord($BFFF);
      aStream.Write(PAnsiChar(s)^,result-3);
    end;

    if not (dfoKeepData in FOpts) then
    begin
      FreeMem(FText); FText:=nil;
    end;
  end;

end;

function TRGDATFile.SaveToMemory(out abuf:PByte; aver:integer):integer;
var
  lstream:TMemoryStream;
  s:UTF8String;
  lsize:integer;
begin
  result:=0;

  if ABS(aver) in [verTL1, verTL2, verHob, verRG, verRGO] then
  begin
    if FData<>nil then
    begin
      lsize:=MemSize(FData);
      GetMem(abuf,lsize);
      move(FData^,abuf^,lsize);
      result:=lsize;
    end
    else
    begin
      FVer:=ABS(aver);
      lstream:=TMemoryStream.Create;
      CompileFile(lstream);
      GetMem(abuf,lstream.Size);
      move(lstream.Memory^,abuf^,lstream.Size);
      result:=lstream.Size;
      lstream.Free;
      //!! make copy in FData too?
    end
  end

  else if aver=CP_UTF16 then
  begin
    if FText=nil then
      MakeDatTree(FNode,FText); //!! let think  - no BOM

    if FText<>nil then
    begin
      result:=Length(FText)*SizeOf(WideChar)+2;
      //!! plus BOM
      GetMem(abuf,result);
      abuf[0]:=$FF; abuf[1]:=$FE;
      move(FText^,(abuf+2)^,result-2);

      if not (dfoKeepData in FOpts) then
      begin
        FreeMem(FText); FText:=nil;
      end;
    end;
  end

  else if aver=CP_UTF8 then
  begin
    if FText=nil then
      MakeDatTree(FNode,FText); //!! let think  - no BOM
    
    if FText<>nil then
    begin
      s:=UTF8Encode(WideString(FText));
      //!! plus BOM
      result:=Length(s)+3;
      GetMem(abuf,result);
      abuf[0]:=$EF;
      abuf[1]:=$BB;
      abuf[2]:=$BF;
      move(PAnsiChar(s)^,(abuf+3)^,result-3);
    end;

    if not (dfoKeepData in FOpts) then
    begin
      FreeMem(FText); FText:=nil;
    end;

  end;
  
end;

//----- Property helpers -----

function TRGDATFile.GetData(ver:integer):pointer;
begin
  if FData=nil then
    SaveToMemory(FData, ver);

  result:=FData;
end;

function TRGDATFile.GetText():PWideChar;
begin
  if FText=nil then
    MakeDatTree(FNode,FText);

  result:=FText;
end;

function TRGDATFile.GetUTF8():string;
begin
  result:=UTF8Encode(UnicodeString(FText));
end;

// ignore ver, get it from abuf directly
procedure TRGDATFile.SetData(ver:integer; abuf:pointer);
begin
  SetData(abuf);
end;

procedure TRGDATFile.SetData(abuf:pointer);
var
  lsize:integer;
begin
  Clear;

  ParseFile(abuf);

  if dfoKeepData in FOpts then
  begin
    lsize:=MemSize(abuf);
    GetMem(FData,lsize);
    move(abuf^,FData^,lsize);
  end;
end;

procedure TRGDATFile.SetText(atext:PWideChar);
begin
  Clear;

  if ord(atext^)=$FEFF then
   inc(atext);

  if dfoKeepData in FOpts then
    FText:=CopyWide(atext);

  ParseDat(atext);
end;

procedure TRGDATFile.SetUTF8(const atext:string);
var
  s:WideString;
  pc:PAnsiChar;
begin
  Clear;

  pc:=PAnsiChar(atext);
  if (pc[0]=#$EF) and (pc[1]=#$BB) and (pc[2]=#$BF) then inc(pc,3);

  s:=UTF8ToString(pc);

  if dfoKeepData in FOpts then
    FText:=CopyWide(PWideChar(s));

  ParseDat(PWideChar(s));
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
