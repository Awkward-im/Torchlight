unit TL2Base;

interface

uses
  Classes;

type
  TL2BaseClass = class
  private//  protected
    FData      :PByte;
    FDataOffset:PtrUInt;
    FDataSize  :integer;

    FHaveSize  :boolean; // can be set to "false" at constructor
    FChanged   :boolean;

  public
    destructor Destroy; override;

    procedure Clear;

    procedure SetSize    (AStream:TStream);
    function  ToStream   (AStream:TStream):boolean;
    procedure FromStream (AStream:TStream; aFrom:integer=-1);
    function  ToFile    (const fname:string):boolean;
    procedure FromFile  (const fname:string);
    
    property Data      :PByte   read FData      ; // write FData;
    property DataOffset:PtrUInt read FDataOffset; // write FDataOffset;
    property DataSize  :integer read FDataSize  ; // write FDataSize;

    property Changed:boolean read FChanged write FChanged;
  end;


implementation


destructor TL2BaseClass.Destroy;
begin
  Clear;

  inherited;
end;

procedure TL2BaseClass.Clear;
begin
  if FData<>nil then
  begin
    FreeMem(FData);
    FData:=nil;
  end;
end;

function TL2BaseClass.ToStream(AStream:TStream):boolean;
begin
  if FData<>nil then
  begin
    if FHaveSize then
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
    AssignFile(f,fname);
    Rewrite   (f);
    BlockWrite(f,FData^,FDataSize);
    CloseFile (f);
  end;
  result:=FData<>nil;
end;

procedure TL2BaseClass.FromStream(AStream:TStream; aFrom:integer=-1);
begin
  if aFrom<0 then
  begin
    FDataSize  :=AStream.ReadDWord();
    FHaveSize  :=true;
    FDataOffset:=AStream.Position;
    ReallocMem  (FData ,FDataSize);
    AStream.Read(FData^,FDataSize);
    AStream.Position:=FDataOffset;
  end
  else
  begin
    FDataOffset:=aFrom;
    FDataSize  :=AStream.Position-FDataOffset;
    AStream.Position:=FDataOffset;
    ReallocMem  (FData ,FDataSize);
    AStream.Read(FData^,FDataSize);
  end;
//  FChanged:=false;
  FChanged:=true;
end;

procedure TL2BaseClass.SetSize(AStream:TStream);
begin
  FDataSize:=AStream.Position-FDataOffset; // to work before and after FromStream
  AStream.Position:=FDataOffset-SizeOf(DWord);
  AStream.WriteDWord(FDataSize);
  AStream.Position:=AStream.Position+FDataSize;
end;

procedure TL2BaseClass.FromFile(const fname:string);
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
    CloseFile(f);
  end;
{$POP}
end;

end.
