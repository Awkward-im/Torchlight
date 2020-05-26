unit formCommon;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  tl2save;

type

  { TfmCommon }

  TfmCommon = class(TForm)
    cbHardcore: TCheckBox;
    edArea: TEdit;
    edClass: TEdit;
    edDifficulty: TEdit;
    edMap: TEdit;
    edNG: TEdit;
    gbCharacter: TGroupBox;
    lblArea: TLabel;
    lblClass: TLabel;
    lblDifficulty: TLabel;
    lblGameTime: TLabel;
    lblMap: TLabel;
    lblNG: TLabel;
  private

  public
    procedure FillInfo(aSGame:TTL2SaveFile);

  end;


implementation

{$R *.lfm}

uses
  tl2common;

procedure TfmCommon.FillInfo(aSGame:TTl2SaveFile);
begin
  edClass     .Text:=aSGame.ClassString;
  edNG        .Text:=IntToStr(aSGame.NewGameCycle);
  edMap       .Text:=aSGame.Map;
  edArea      .Text:=aSGame.Area;
  edDifficulty.Text:=GetDifficulty(ORD(aSGame.Difficulty));
  cbHardcore.checked:=aSGame.Hardcore;
  lblGameTime.Caption:=IntToStr(trunc(aSGame.GameTime))+':'+
    IntToStr(Trunc(Frac(aSGame.GameTime)*60));
end;

end.

