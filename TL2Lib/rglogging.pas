{TODO: use separate 'string' for Reserve}
unit RGLogging;

interface

type
  TRGLogOnAdd = function (var adata:string):integer of object;
  TRGLogOnAddBinary = function (var abuf:PByte; var asize:integer):integer of object;

type
  TRGLog = object
  private
    FLog:pointer;
    FOnAdd:TRGLogOnAdd;
    FOnAddBin:TRGLogOnAddBinary;
    Fidx :cardinal;
    FSize:cardinal;
    FReserved:boolean;
    
    function GetText():string;
    
  public
    procedure Init;
    procedure Free;
    procedure Clear;

    procedure Reserve(const astr:string);
    procedure Reserve(astr:PWideChar);
    procedure Add(const afile:string; aline:integer; const astr:string);
    procedure Add(const astr:string);
    procedure Add(astr:PWideChar);
    procedure Add(adata:pointer; asize:integer);
    procedure Add(adata:int64  ; asize:integer);

    procedure SaveToFile(const afile:string='rglog.txt');

    property Text:string   read GetText;
    property Log :pointer  read FLog;
    property size:cardinal read FSize;

    property OnAdd:TRGLogOnAdd read FOnAdd write FOnAdd;

    property OnAddBinary:TRGLogOnAddBinary read FOnAddBin write FOnAddBin;
  end;

var
  RGLog:TRGLog;


implementation


procedure AddBin(var buf:PByte; var idx:cardinal; adata:pointer; asize:integer);
const
  TMSGrow = 4096;
Var
  GC,NewIdx:PtrInt;
begin
  If asize=0 then
    exit;

  if buf=nil then
    GC:=0
  else
    GC:=MemSize(buf);

  NewIdx:=idx+asize;
  If NewIdx>=GC then
  begin
    GC:=GC+(GC div 4);
    GC:=(GC+(TMSGrow-1)) and not (TMSGrow-1);
    if GC=0 then GC:=TMSGrow;
    ReallocMem(buf,GC);
  end;
  System.Move(PByte(adata)^,buf[idx],asize);
  idx:=NewIdx;
end;

procedure AddText(var buf:PByte; var idx:cardinal; const atext:string);
const
  TMSGrow = 4096;
Var
  GC,NewIdx:PtrInt;
  lcnt:integer;
begin
  lcnt:=Length(atext);
  If lcnt=0 then
    exit;

  if buf=nil then
    GC:=0
  else
    GC:=MemSize(buf);

  NewIdx:=idx+lcnt;
  If (NewIdx+3)>=GC then
  begin
    GC:=GC+(GC div 4);
    GC:=(GC+(TMSGrow-1)) and not (TMSGrow-1);
    if GC=0 then GC:=TMSGrow;
    ReallocMem(buf,GC);
  end;
  System.Move(PChar(atext)^,buf[idx],lcnt);
  buf[NewIdx+0]:=13;
  buf[NewIdx+1]:=10;
  buf[NewIdx+2]:=0;
  idx:=NewIdx+2;
end;


procedure TRGLog.Init;
begin
  FLog :=nil;
  FIdx :=0;
  FSize:=0;
  FReserved:=false;
  FOnAdd:=nil;
end;

procedure TRGLog.Clear;
begin
  FreeMem(FLog);
  Init;
end;

procedure TRGLog.Free;
begin
  Clear;
end;


procedure TRGLog.Add(adata:int64; asize:integer);
var
  p:pointer;
begin
  p:=@adata;
  if Assigned(FOnAddBin) then
    if FOnAddBin(p,asize)<=0 then
      exit;

  AddBin(FLog,FSize,p,asize);
  FReserved:=false;
end;

procedure TRGLog.Add(adata:pointer; asize:integer);
begin
  if Assigned(FOnAddBin) then
    if FOnAddBin(adata,asize)<=0 then
      exit;

  AddBin(FLog,FSize,adata,asize);
  FReserved:=false;
end;

procedure TRGLog.Add(const astr:string);
var
  ls:string;
  i:integer;
begin
  ls:=astr;
  if Assigned(FOnAdd) then
  begin
    if FReserved then
    begin
      FReserved:=false;
      i:=FSize-Fidx-2;
      SetLength(ls,i);
      System.move((PAnsiChar(FLog)+Fidx)^,ls[1],i);
      if FOnAdd(ls)<=0 then ;//exit;
    end;
    ls:=astr;
    if FOnAdd(ls)<=0 then
      exit;
  end;

  AddText(FLog,FSize,ls);

  FReserved:=false;
end;

procedure TRGLog.Add(const afile:string; aline:integer; const astr:string);
var
  ls:string;
begin
  Str(aline,ls);
  Add(afile+' ('+ls+'): '+astr);
end;

procedure TRGLog.Add(astr:PWideChar);
begin
  Add(UTF8Encode(WideString(astr)));
end;


procedure TRGLog.Reserve(const astr:string);
var
  ls:string;
begin
  ls:=astr;
//  if Assigned(FOnAdd) and (FOnAdd(ls)<=0) then exit;

  if FReserved then FSize:=Fidx else Fidx:=FSize;

  AddText(FLog,FSize,ls);
  FReserved:=true;
end;

procedure TRGLog.Reserve(astr:PWideChar);
begin
  Reserve(UTF8Encode(WideString(astr)));
end;


procedure TRGLog.SaveToFile(const afile:string='rglog.txt');
var
  f:file of byte;
begin
  if (FLog<>nil) and not
     (FReserved and (Fidx=0)) then
  begin
    Assign(f,afile);
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,PByte(FLog)^,FSize{Length(PChar(FLog))});
      Close(f);
    end;
  end;
end;

function TRGLog.GetText:string;
begin
  result:=PChar(FLog);
end;


initialization

  RGLog.Init;

finalization

  RGLog.Free;

end.
