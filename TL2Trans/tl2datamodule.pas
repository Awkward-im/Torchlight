unit TL2DataModule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls,
  Graphics;

type

  { TTL2DataModule }

  TTL2DataModule = class(TDataModule)
    TL2ImageList: TImageList;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private

  public
    TL2Font: TFont;

  end;

var  TL2DM: TTL2DataModule;

implementation

{$R *.lfm}

{ TTL2DataModule }

procedure TTL2DataModule.DataModuleCreate(Sender: TObject);
begin
  TL2Font:=TFont.Create;
end;

procedure TTL2DataModule.DataModuleDestroy(Sender: TObject);
begin
  TL2Font.Free;
end;

end.

