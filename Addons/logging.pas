{TODO: Add Error(code,text) and Error(code,number)}
{TODO: Add saves as UTF16LE and UTF8 (conversion if needs) with signature}
unit Logging;

interface

type
  TLogOnAdd       = function (var adata:string                 ):integer of object;
  TLogOnAddWide   = function (var adata:UnicodeString          ):integer of object;
  TLogOnAddBinary = function (var abuf:PByte; var asize:integer):integer of object;

type
  TBaseLog = object
  private
    FLog:PByte;
    FOnAddBin:TLogOnAddBinary;

    // savefile signature
    FSign:longword;
    FSignSize:integer;

    FSize:cardinal;    // Log content size
    FBufSize:cardinal; // FLog memory size. Can be replaced by MemSize()

    procedure CheckBuffer(asize:integer);
  public
    procedure Init;
    procedure Free;
    procedure Clear;

    procedure AddData (adata:pointer; asize:integer);
    procedure AddValue(adata:int64  ; asize:integer);

    procedure SaveToFile(const afile:string='rglog.txt');

    property Log :PByte  read FLog;
    property size:cardinal read FSize;

    property OnAddBinary:TLogOnAddBinary read FOnAddBin write FOnAddBin;
  end;

  TLog = object(TBaseLog)
  private
    FOnAdd:TLogOnAdd;
    FReserve:AnsiString;
    
    function  GetText():string;
    procedure AddText(const atext:PAnsiChar);
    
  public
    procedure Init;
    procedure Clear;

    procedure Reserve    (astr:string);
    procedure Reserve    (astr:PAnsiChar);
    procedure ReserveWide(astr:PWideChar);
    procedure Add(const afile:string; aline:integer; const astr:string);
    procedure Add(const astr:string);
    procedure AddWide(astr:PWideChar);
    procedure Continue(const astr:string);

    property Text:string read GetText;
    property OnAdd:TLogOnAdd read FOnAdd write FOnAdd;
  end;

  TLogWide = object(TBaseLog)
  private
    FOnAdd:TLogOnAddWide;
    FReserve:UnicodeString;
    
    function  GetText():UnicodeString;
    procedure AddText(const atext:PWideChar);
    
  public
    procedure Init;
    procedure Clear;

    procedure Reserve(astr:PWideChar);
    procedure Add(const afile:UnicodeString; aline:integer; const astr:UnicodeString);
    procedure Add(const astr:UnicodeString);
    procedure Continue(const astr:UnicodeString);

    property Text:UnicodeString read GetText;
    property OnAdd:TLogOnAddWide read FOnAdd write FOnAdd;
  end;


implementation

const
  SIGN_UNICODE = $FEFF;
  SIGN_UTF8    = $BFBBEF;

const
  TMSGrow = 4096;

{%REGION Base (Binary) Log}

procedure TBaseLog.Init;
begin
  FLog:=nil;
  FSize:=0;
  FBufSize:=0;
  FSignSize:=0;

  FOnAddBin:=nil;
end;

procedure TBaseLog.Clear;
begin
  FreeMem(FLog);
  FLog :=nil;
  FSize:=0;
  FBufSize:=0;
end;

procedure TBaseLog.Free;
begin
  Clear;
end;

procedure TBaseLog.CheckBuffer(asize:integer);
var
  NewIdx:SizeInt;
begin
  If asize=0 then
    exit;

  NewIdx:=FSize+asize;
  If NewIdx>=FBufSize then
  begin
    FBufSize:=FBufSize+(FBufSize div 4);
    if FBufSize<NewIdx then
      FBufSize:=NewIdx;

    FBufSize:=Align(FBufSize,TMSGrow);
    ReallocMem(FLog,FBufSize);
  end;
end;

procedure TBaseLog.AddData(adata:pointer; asize:integer);
begin
  if Assigned(FOnAddBin) then
    if FOnAddBin(adata,asize)<=0 then
      exit;

  CheckBuffer(asize);

  System.Move(PByte(adata)^,FLog[FSize],asize);
  inc(FSize,asize);
end;

procedure TBaseLog.AddValue(adata:int64; asize:integer);
begin
  AddData(@adata,asize);
end;

procedure TBaseLog.SaveToFile(const afile:string='rglog.txt');
var
  f:file of byte;
begin
  if (FLog<>nil) then
  begin
    Assign(f,afile);
    Rewrite(f);
    if IOResult=0 then
    begin
      if FSignSize>0 then BlockWrite(f,FSign,FSignSize);
      BlockWrite(f,PByte(FLog)^,FSize);
      Close(f);
    end;
  end;
end;

{%ENDREGION Base (Binary) Log}

{%REGION Ansi Text Log}

procedure TLog.Init;
begin
  inherited Init;

  FSign:=SIGN_UTF8;
  FSignSize:=3;

  Initialize(FReserve);
  FOnAdd:=nil;
end;

procedure TLog.Clear;
begin
  FReserve:='';

  inherited Clear;
end;

procedure TLog.AddText(const atext:PAnsiChar);
Var
  lsize:integer;
begin
  lsize:=Length(atext);
  CheckBuffer(lsize+3);

  if lsize>0 then
  begin
    System.Move(atext^,FLog[FSize],lsize);
    inc(FSize,lsize);
  end;

  FLog[FSize+0]:=13;
  FLog[FSize+1]:=10;
  FLog[FSize+2]:=0;
  Inc(FSize,2);
end;

procedure TLog.Continue(const astr:string);
begin
  if FSize>0 then dec(FSize,2);
  AddText(pointer(astr));
end;

procedure TLog.Add(const astr:string);
var
  ls:AnsiString;
begin
  if FReserve<>'' then
  begin
    ls:=FReserve;
    FReserve:='';
    Add(ls);
  end;
  
  ls:=astr;
  if Assigned(FOnAdd) then
  begin
    if FOnAdd(ls)<=0 then
      exit;
  end;

  AddText(Pointer(ls));
end;

procedure TLog.Add(const afile:string; aline:integer; const astr:string);
var
  ls:string;
begin
  Str(aline,ls);
  Add(afile+' ('+ls+'): '+astr);
end;

procedure TLog.AddWide(astr:PWideChar);
begin
  Add(UTF8Encode(UnicodeString(astr)));
end;


procedure TLog.Reserve(astr:string);
begin
  FReserve:=astr;
end;

procedure TLog.Reserve(astr:PAnsiChar);
begin
  FReserve:=astr;
end;

procedure TLog.ReserveWide(astr:PWideChar);
begin
  Reserve(pointer(UTF8Encode(UnicodeString(astr))));
end;

function TLog.GetText:string;
begin
  result:=PAnsiChar(FLog);
end;

{%ENDREGION Ansi Text Log}

{%REGION Wide Text Log}

procedure TLogWide.Init;
begin
  inherited Init;

  FSign:=SIGN_UNICODE;
  FSignSize:=2;
  Initialize(FReserve);

  FOnAdd:=nil;
end;

procedure TLogWide.Clear;
begin
  FReserve:='';

  inherited Clear;
end;

procedure TLogWide.AddText(const atext:PWideChar);
Var
  lsize:integer;
begin
  lsize:=Length(atext)*SizeOf(WideChar);
  CheckBuffer(lsize+3*SizeOf(WideChar));

  System.Move(PByte(atext)^,FLog[FSize],lsize);
  inc(FSize,lsize);

  FLog[FSize+0]:=13;
  FLog[FSize+1]:=0;
  FLog[FSize+2]:=10;
  FLog[FSize+3]:=0;
  FLog[FSize+4]:=0;
  FLog[FSize+5]:=0;
  Inc(FSize,4);
end;

procedure TLogWide.Continue(const astr:UnicodeString);
begin
  if FSize>0 then dec(FSize,4);
  AddText(pointer(astr));
end;

procedure TLogWide.Add(const astr:UnicodeString);
var
  ls:UnicodeString;
begin
  if FReserve<>'' then
  begin
    ls:=FReserve;
    FReserve:='';
    Add(ls);
  end;
  
  ls:=astr;
  if Assigned(FOnAdd) then
  begin
    if FOnAdd(ls)<=0 then
      exit;
  end;

  AddText(Pointer(ls));
end;

procedure TLogWide.Add(const afile:UnicodeString; aline:integer; const astr:UnicodeString);
var
  ls:UnicodeString;
begin
  Str(aline,ls);
  Add(afile+' ('+ls+'): '+astr);
end;


procedure TLogWide.Reserve(astr:PWideChar);
begin
  FReserve:=astr;
end;

function TLogWide.GetText:UnicodeString;
begin
  result:=PWideChar(FLog);
end;

{%ENDREGION Wide Text Log}

end.
