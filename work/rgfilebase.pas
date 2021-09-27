{%TODO return Node without deleting (cut off on read property?)}
{%TODO fix SaveToStream/SaveToMemory for binary data when FData=nil}
unit RGFileBase;

interface

uses
  Classes;

type
  TRGFileBase = object
  public
    type
      TRGFileBaseOpts = set of (dfoKeepData);
  private
    function GetNode():pointer;
    function GetData(ver:integer):pointer;
    function GetText():PWideChar;
    function GetUTF8():string;

    procedure SetData(abuf:pointer);
    procedure SetData(ver:integer; abuf:pointer);
    procedure SetText(atext:PWideChar);
    procedure SetUTF8(const atext:string);

  protected
    FData:PByte;
    FText:PWideChar;
    FNode:pointer;
    FOpts:TRGFileBaseOpts;
    FVer :integer;
    FBuffer:WideString;

    Parse          : function():integer of object;
    Compile        : function():integer of object;
    CompileToStream: function(aStream:TStream):integer of object;

  public
    procedure Init(aOpts:TRGFileBaseOpts=[dfoKeepData]);
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

    property Node:pointer   read GetNode;
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


{%REGION TRGFileBase publics}

procedure TRGFileBase.Init(aOpts:TRGFileBaseOpts=[dfoKeepData]);
begin
  FOpts:=aOpts;
  FData:=nil;
  FText:=nil;
  FNode:=nil;

  Parse          :=nil;
  Compile        :=nil;
  CompileToStream:=nil;
end;

procedure TRGFileBase.Clear;
begin
  if FData<>nil then FreeMem   (FData); FData:=nil;
  if FText<>nil then FreeMem   (FText); FText:=nil;
  if FNode<>nil then DeleteNode(FNode); FNode:=nil;

end;

procedure TRGFileBase.Free;
begin
  Clear;
end;


function TRGFileBase.LoadFromFile(const afile:string):boolean;
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

function TRGFileBase.LoadFromStream(aStream:TStream):boolean;
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

function TRGFileBase.LoadFromMemory(abuf:PByte; asize:cardinal=0; useIt:boolean=false):boolean;
var
  s :WideString;
  ls:AnsiString;
  lpc:PWideChar;
  pc :PAnsiChar;
begin
  Clear;
  result:=false;

  if asize=0 then asize:=MemSize(abuf);

  // UTF16 text
  if (PWord    (abuf)^=$FEFF) or
     (PWideChar(abuf)^='['  ) then
  begin
    FVer:=CP_UTF16;

    lpc:=abuf;
    if ORD(lpc)^=$FEFF then inc(lpc,2);

    if (abuf[asize-2]<>0) or (abuf[asize-1]<>0) then
    begin
      FText:=CopyWide(lpc,asize div 2);
      lpc:=FText;
    end
    else if dfoKeepData in FOpts then
    begin
      FText:=CopyWide(lpc);
      lpc:=FText;
    end;

    ParseDat(lpc);

    if (FText<>nil) and not (dfoKeepData in FOpts) then
    begin
      FreeMem(FText);
      FText:=nil;
    end;

    if useIt then FreeMem(abuf);
  end

  // UTF8 text
  else if PDWord(abuf)^=$5BBFBBEF then // UTF8 sign and '['
  begin
    FVer:=CP_UTF16;

    pc:=abuf;
    if pc^<>'[' then
    begin
      inc(pc,3);
      dec(asize,3);
    end;

    if pc[asize-1]<>#0 then
    begin
      SetString(ls,pc,asize);
      s:=UTF8Decode(ls);
    end
    else
      s:=UTF8ToString(pc);

    ParseDat(PWideChar(s));

    if dfoKeepData in FOpts then
      FText:=CopyWide(PWideChar(s));

    if useIt then FreeMem(abuf);
  end

  // Binary
  else
  begin
    FData:=abuf;

    if (Parse<>nil) and (Parse()<0) then
    begin
      RGLog.Add('Unknown data signature: 0x'+IntToHex(PDword(abuf)^));
    end;

    if dfoKeepData in FOpts then
    begin
      if not useIt then
      begin
        GetMem(FData,asize);
        move(abuf^,FData^,asize);
      end;
    end
    else if useIt then
    begin
      FData:=nil;
      FreeMem(abuf);
    end;
  end;

end;


function TRGFileBase.SaveToFile(const afile:string; aver:integer):integer;
var
  lstream:TMemoryStream;
//  f:file of byte;
begin
  result:=-1;

  lstream:=TMemoryStream.Create();
  try
    result:=SaveToStream(lstream,aver);
    if result>0 then
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

function TRGFileBase.SaveToStream(aStream:TStream; aver:integer):integer;
var
  s:UTF8String;
  lsize:integer;
begin
  result:=-1;

  if aver=CP_UTF16 then
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
    end
    else
      result:=0;
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
      aStream.WriteWord($BFBB);
      aStream.Write(PAnsiChar(s)^,result-3);
    end
    else
      result:=0;

    if not (dfoKeepData in FOpts) then
    begin
      FreeMem(FText); FText:=nil;
    end;
  end

  else
  begin
    if FData<>nil then
    begin
      lsize:=MemSize(FData);
      aStream.Write(FData^,lsize);
      result:=lsize;
    end
    else
    begin
      FVer:=ABS(aver);
      if CompileToStream<>nil then
        result:=CompileToStream(aStream)
      else if Compile<>nil then
      begin
        result:=Compile();
        lsize:=MemSize(FData);
        aStream.Write(FData^,lsize);
        result:=lsize;
      end;
    end;
  end

end;

function TRGFileBase.SaveToMemory(out abuf:PByte; aver:integer):integer;
var
  lstream:TMemoryStream;
  s:UTF8String;
  lsize:integer;
begin
  result:=-1;

  if aver=CP_UTF16 then
  begin
    if FText=nil then
      MakeDatTree(FNode,FText); //!! let think  - no BOM

    if FText<>nil then
    begin
      result:=Length(FText)*SizeOf(WideChar)+2;
      //!! plus BOM
      GetMem(abuf,result);
      abuf[0]:=$FF;
      abuf[1]:=$FE;
      move(FText^,(abuf+2)^,result-2);

      if not (dfoKeepData in FOpts) then
      begin
        FreeMem(FText); FText:=nil;
      end;
    end
    else
      result:=0;
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
    end
    else
      result:=0;

    if not (dfoKeepData in FOpts) then
    begin
      FreeMem(FText); FText:=nil;
    end;
  end

  else
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

      if Compile<>nil then
        result:=Compile()
      else if CompileToStream<>nil then
      begin
        lstream:=TMemoryStream.Create;
        result:=CompileToStream(lstream);
        GetMem(abuf,result);
        move(lstream.Memory^,abuf^,result);
        lstream.Free;
      end;
      //!! make copy in FData too?
    end
  end;
  
end;

{%ENDREGION}

{%REGION Property helpers}

function GetNode():pointer;
begin
  result:=FNode;
  FNode :=nil;  //!!!!
end;

function TRGFileBase.GetData(ver:integer):pointer;
begin
  if FData=nil then
    SaveToMemory(FData, ver);

  result:=FData;
end;

function TRGFileBase.GetText():PWideChar;
begin
  if FText=nil then
    MakeDatTree(FNode,FText);

  result:=FText;
end;

function TRGFileBase.GetUTF8():string;
begin
  result:=UTF8Encode(UnicodeString(GetText()));
end;


// ignore ver, get it from abuf directly
procedure TRGFileBase.SetData(ver:integer; abuf:pointer);
begin
  SetData(abuf);
end;

procedure TRGFileBase.SetData(abuf:pointer);
var
  lsize:integer;
begin
  Clear;

  FData:=abuf;
  Parse();

  if dfoKeepData in FOpts then
  begin
    lsize:=MemSize(abuf);
    GetMem(FData,lsize);
    move(abuf^,FData^,lsize);
  end
  else
    FData:=nil;
end;

procedure TRGFileBase.SetText(atext:PWideChar);
begin
  Clear;

  if ord(atext^)=$FEFF then
    inc(atext);

  ParseDat(atext);

  if dfoKeepData in FOpts then
    FText:=CopyWide(atext);

end;

procedure TRGFileBase.SetUTF8(const atext:string);
var
  s:WideString;
  pc:PAnsiChar;
begin
  pc:=PAnsiChar(atext);
  if (pc[0]=#$EF) and (pc[1]=#$BB) and (pc[2]=#$BF) then inc(pc,3);

  s:=UTF8ToString(pc);

  SetText(PWideChar(s));
end;

{%ENDREGION}

{%REGION Initialization}

initialization


finalization

{%ENDREGION}
end.
