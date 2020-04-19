unit TL2Base;

interface

uses
  Classes;

type
  TL2BaseClass = class
  protected
    FData      :PByte;
    FDataOffset:PtrUInt;
    FDataSize  :integer;

    FChanged   :boolean;

  public
    destructor Destroy; override;

    function  ToStream   (AStream:TStream):boolean;
    procedure FromStream (AStream:TStream);
    procedure CloneStream(AStream:TStream);
    function  ToFile    (const fname:string):boolean;
    procedure FromFile  (const fname:string);
    
    property Data      :PByte   read FData      ; // write FData;
    property DataOffset:PtrUInt read FDataOffset; // write FDataOffset;
    property DataSize  :integer read FDataSize  ; // write FDataSize;

    property Changed:boolean read FChanged ; //write FChanged;
  end;


implementation


destructor TL2BaseClass.Destroy;
begin
  if FData<>nil then FreeMem(FData);

  inherited;
end;

function TL2BaseClass.ToStream(AStream:TStream):boolean;
begin
  if FData<>nil then
  begin
    AStream.WriteDWord(FDataSize);
    AStream.Write(FData^,FDataSize);
  end;
  result:=FData<>nil;
end;

function TL2BaseClass.ToFile(const fname:string):boolean;
var
  f:file of byte;
begin
  if FData<>nil then
  begin
    Assignfile(f,fname);
    Rewrite   (f);
    BlockWrite(f,FData^,FDataSize);
    CloseFile (f);
  end;
  result:=FData<>nil;
end;

procedure TL2BaseClass.FromStream(AStream:TStream);
begin
  FDataSize  :=AStream.ReadDWord();
  FDataOffset:=AStream.Position;
  ReallocMem  (FData ,FDataSize);
  AStream.Read(FData^,FDataSize);
  AStream.Position:=FDataOffset;
end;

procedure TL2BaseClass.CloneStream(AStream:TStream);
begin
  if FDataOffset<>0 then
  begin
    FDataSize:=AStream.Position-FDataOffset;
    AStream.Position:=FDataOffset;
    ReallocMem  (FData ,FDataSize);
    AStream.Read(FData^,FDataSize);
  end;
end;

procedure TL2BaseClass.FromFile(const fname:string);
var
  f:file of byte;
begin
  Assignfile(f,fname);
{$PUSH}
{$I-}
  Reset(f);
  if IOResult=0 then
  begin
    FDataSize  :=FileSize(f);
    FDataOffset:=0;
    ReallocMem(  FData ,FDataSize);
    BlockRead (f,FData^,FDataSize);
    CloseFile(f);
  end;
{$POP}
end;

end.
