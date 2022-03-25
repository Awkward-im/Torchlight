{TODO: implement OnAdd event}
unit RGLogging;

interface

type
  TRGLog = object
  private
    FLog:pointer;
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
    procedure Add(const adata:pointer; asize:integer);
    procedure Add(adata:int64; asize:integer);
    procedure Add(astr:PWideChar);

    procedure SaveToFile(const afile:string='rglog.txt');

    property Text:string   read GetText;
    property Log :pointer  read FLog;
    property size:cardinal read FSize;
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
begin
  AddBin(FLog,FSize,@adata,asize);
  FReserved:=false;
end;

procedure TRGLog.Add(const adata:pointer; asize:integer);
begin
  AddBin(FLog,FSize,adata,asize);
  FReserved:=false;
end;

procedure TRGLog.Add(const astr:string);
begin
  AddText(FLog,FSize,astr);
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
begin
  if FReserved then FSize:=Fidx
  else Fidx:=FSize;
  Add(astr);
  FReserved:=true;
end;

procedure TRGLog.Reserve(astr:PWideChar);
begin
  if FReserved then FSize:=Fidx
  else Fidx:=FSize;
  Add(astr);
  FReserved:=true;
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
