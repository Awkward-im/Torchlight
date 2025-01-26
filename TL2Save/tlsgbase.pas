unit TLSGBase;

interface

uses
  Classes;

type
  TL2DataType = (dtChar, dtItem, dtEffect, dtMap, dtQuest, dtStat);
type
  TLSGBaseClass = class
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

    {
      Set data size before DataOffset
    }
    procedure FixSize(AStream:TStream);

    {
      Load data from file. Check for data size saved at start
    }
    procedure LoadFromFile(const fname:string);
    {
      Save data to file. Save data size if marked as known
    }
    procedure SaveToFile  (const fname:string);

    procedure LoadBlock(AStream:TStream);
    procedure SaveBlock(AStream:TStream);

    procedure LoadFromStream(AStream:TStream; aVersion:integer); virtual; abstract;
    procedure SaveToStream  (AStream:TStream; aVersion:integer); virtual; abstract;
    
    property Data      :PByte       read FData      ; // write FData;
    property DataOffset:PtrUInt     read FDataOffset write FDataOffset;
    property DataSize  :integer     read FDataSize   write SetDataSize;
    property DataType  :TL2DataType read FDataType   write FDataType;

    property Changed:boolean read FChanged write FChanged;
  end;


implementation


destructor TLSGBaseClass.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TLSGBaseClass.Clear;
begin
  InternalClear;
end;

procedure TLSGBaseClass.InternalClear;
begin
  if FData<>nil then
  begin
    FreeMem(FData);
    FData:=nil;
  end;
end;

procedure TLSGBaseClass.SetDataSize(asize:integer);
begin
  FDataSize :=asize;
  FKnownSize:=true;
end;

procedure TLSGBaseClass.FixSize(AStream:TStream);
begin
  AStream.Position:=FDataOffset-SizeOf(DWord);
  AStream.WriteDWord(FDataSize);
  AStream.Position:=AStream.Position+FDataSize;
end;

procedure TLSGBaseClass.SaveBlock(AStream:TStream);
begin
  if FData<>nil then
  begin
    AStream.Write(FData^,FDataSize);
  end;
end;

procedure TLSGBaseClass.LoadBlock(AStream:TStream);
begin
  FDataSize:=AStream.Position-FDataOffset;

  if (FData=nil) or (MemSize(FData)<FDataSize) then
  begin
    if FData<>nil then FreeMem(FData);
    GetMem(FData,Align(FDataSize,1024));
  end;

  AStream.Position:=FDataOffset;
  AStream.Read(FData^,FDataSize);
end;


procedure TLSGBaseClass.LoadFromFile(const fname:string);
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

    if (FData=nil) or (MemSize(FData)<FDataSize) then
    begin
      if FData<>nil then FreeMem(FData);
      GetMem(FData,Align(FDataSize,1024));
    end;

    BlockRead(f,FData^,FDataSize);
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

procedure TLSGBaseClass.SaveToFile(const fname:string);
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
