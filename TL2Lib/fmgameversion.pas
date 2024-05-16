unit fmGameVersion;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons;

type

  { TfmGameVer }

  TfmGameVer = class(TForm)
    bbOK: TBitBtn;
    ilGames: TImageList;
    imgGameTL1: TImage;
    imgGameTL2: TImage;
    imgGameHob: TImage;
    imgGameRG: TImage;
    imgGameRGO: TImage;
    lblGame: TLabel;
    rbGameTL1: TRadioButton;
    rbGameTL2: TRadioButton;
    rbGameHob: TRadioButton;
    rbGameRG: TRadioButton;
    rbGameRGO: TRadioButton;
    procedure FormCreate(Sender: TObject);
  private
    function  GetGameVer: integer;
    procedure SetGameVer(aver: integer);

  public
    property Version:integer read GetGameVer write SetGameVer;
  end;

var
  fmGameVer: TfmGameVer;

implementation

{$R *.lfm}

uses
  rgglobal;

{ TfmGameVer }

procedure TfmGameVer.FormCreate(Sender: TObject);
begin
  rbGameTL1.Caption:=GetGameName(verTL1);
  rbGameTL2.Caption:=GetGameName(verTL2);
  rbGameHob.Caption:=GetGameName(verHob);
  rbGameRG .Caption:=GetGameName(verRG);
  rbGameRGO.Caption:=GetGameName(verRGO);
end;

function TfmGameVer.GetGameVer:integer;
begin
  if rbGameTL1.Checked then exit(verTL1);
  if rbGameTL2.Checked then exit(verTL2);
  if rbGameHob.Checked then exit(verHob);
  if rbGameRG .Checked then exit(verRG);
  if rbGameRGO.Checked then exit(verRGO);
  result:=verUnk;
end;

procedure TfmGameVer.SetGameVer(aver:integer);
begin
  case aver of
    verTL1: rbGameTL1.Checked:=true;
    verHob: rbGameHob.Checked:=true;
    verRG : rbGameRG .Checked:=true;
    verRGO: rbGameRGO.Checked:=true;
  else
    rbGameTL2.Checked:=true;
  end;
end;

end.

