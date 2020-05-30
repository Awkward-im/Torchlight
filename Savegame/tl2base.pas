unit TL2Base;

interface

uses
  Classes,
  tl2stream;

type
  TL2DataType = (dtChar, dtItem, dtEffect, dtMap, dtQuest, dtStat);
type
  TL2BaseClass = class
  private
    FData      :PByte;
    FDataOffset:PtrUInt;
    FDataSize  :integer;
    FDataType  :TL2DataType;

    FKnownSize :boolean;
    FChanged   :boolean;

    procedure SetDataSize(asize:integer);
    procedure InternalClear;

  public
    destructor Destroy; override;

    procedure Clear; virtual;

    procedure FixSize(AStream:TStream);

    procedure LoadFromFile(const fname:string);
    procedure SaveToFile  (const fname:string);

    procedure LoadBlock(AStream:TStream);
    procedure SaveBlock(AStream:TStream);

    procedure LoadFromStream(AStream:TTL2Stream); virtual; abstract;
    procedure SaveToStream  (AStream:TTL2Stream); virtual; abstract;
    
    property Data      :PByte       read FData      ; // write FData;
    property DataOffset:PtrUInt     read FDataOffset write FDataOffset;
    property DataSize  :integer     read FDataSize   write SetDataSize;
    property DataType  :TL2DataType read FDataType   write FDataType;

    property Changed:boolean read FChanged write FChanged;
  end;


implementation


destructor TL2BaseClass.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TL2BaseClass.Clear;
begin
  InternalClear;
end;

procedure TL2BaseClass.InternalClear;
begin
  if FData<>nil then
  begin
    FreeMem(FData);
    FData:=nil;
  end;
end;

procedure TL2BaseClass.SetDataSize(asize:integer);
begin
  FDataSize :=asize;
  FKnownSize:=true;
end;

procedure TL2BaseClass.FixSize(AStream:TStream);
begin
  AStream.Position:=FDataOffset-SizeOf(DWord);
  AStream.WriteDWord(FDataSize);
  AStream.Position:=AStream.Position+FDataSize;
end;

procedure TL2BaseClass.SaveBlock(AStream:TStream);
begin
  if FData<>nil then
  begin
    AStream.Write(FData^,FDataSize);
  end;
end;

procedure TL2BaseClass.LoadBlock(AStream:TStream);
begin
  FDataSize:=AStream.Position-FDataOffset;
  ReallocMem(FData ,FDataSize);
  AStream.Position:=FDataOffset;
  AStream.Read(FData^,FDataSize);
end;


procedure TL2BaseClass.LoadFromFile(const fname:string);
var
  f:file of byte;
begin
  AssignFile(f,fname);
{$PUSH}
{$I-}
  Reset(f);
  if IOResult=0 then
  begin
    FDataSize  :=FileSize(f);
    FDataOffset:=0;
    ReallocMem(  FData ,FDataSize);
    BlockRead (f,FData^,FDataSize);
    FKnownSize:=PDword(FData)^=FDataSize+SizeOf(DWord);
    if FKnownSize then
    begin
      FDataSize:=PDword(FData)^;
      move((FData+SizeOf(DWord))^,FData^,FDataSize);
    end;
    CloseFile (f);
  end;
{$POP}
end;

procedure TL2BaseClass.SaveToFile(const fname:string);
var
  f:file of byte;
begin
  if FData<>nil then
  begin
    AssignFile(f,fname);
    Rewrite   (f);
    if FKnownSize then
      BlockWrite(f,FDataSize,SizeOf(DWord));
    BlockWrite(f,FData^,FDataSize);
    CloseFile (f);
  end;
end;

end.
