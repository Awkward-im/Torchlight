{TODO: implement 'compare' and 'stop' variants}
unit fmAsk;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

type

  { TAskForm }

  TAskForm = class(TForm)
    bbContinue: TBitBtn;
    bbStop: TBitBtn;
    bbCompare: TBitBtn;
    cbForAll: TCheckBox;
    cbCurrentDir: TCheckBox;
    lblOldSizeNum: TLabel;
    lblNewSizeNum: TLabel;
    lblOldSize: TLabel;
    lblNewSize: TLabel;
    lblWhatToDo: TLabel;
    lblFileName: TLabel;
    rbSkip: TRadioButton;
    rbOverwrite: TRadioButton;
    procedure bbCompareClick(Sender: TObject);
    procedure bbContinueClick(Sender: TObject);
    procedure bbStopClick(Sender: TObject);
    procedure cbForAllChange(Sender: TObject);
  private

  public
     constructor Create(const fname:string; aoldsize,anewsize:integer{; amode:integer}); overload;
  end;

var
  AskForm: TAskForm;

implementation

{$R *.lfm}

uses
  unitComboCommon;

{ TAskForm }

constructor TAskForm.Create(const fname: string; aoldsize, anewsize:integer{; amode:integer});
var
  lext:string;
begin
  Create(nil);
{ no reason to implement coz 'amode' is 'ask' always right now
//  tact(amode) = stop;
  rbOverwrite .Checked:=tact(amode) in [overwrite,overwritedir,overwriteall];
  rbSkip      .Checked:=tact(amode) in [ask,skip,skipall];
  cbForAll    .Checked:=tact(amode) in [skipall, overwriteall];
  cbCurrentDir.Checked:=tact(amode) = overwritedir;
}
  lext:=UpCase(ExtractFileExt(fname));
  bbCompare.Visible:=(lext='.DAT') or (lext='.TEMPLATE') or (lext='.LAYOUT');
  lblFileName.Caption:=fname;
  lblOldSizeNum.Caption:=IntToStr(aoldsize);
  lblNewSizeNum.Caption:=IntToStr(anewsize);
end;

procedure TAskForm.cbForAllChange(Sender: TObject);
begin
  cbCurrentDir.Enabled:=not cbForAll.Checked;
  if cbForAll.Checked then cbCurrentDir.Checked:=false;
end;

procedure TAskForm.bbContinueClick(Sender: TObject);
begin
  if rbSkip.Checked then
  begin
    if cbForAll.Checked then
      ModalResult:=ord(tact.skipall)
    else
      ModalResult:=ord(tact.skip)
  end
  else //if rbOverwrite.Checked then
  begin
    if cbForAll.Checked then
      ModalResult:=ord(tact.overwriteall)
    else if cbCurrentDir.Checked then
      ModalResult:=ord(tact.overwritedir)
    else
      ModalResult:=ord(tact.overwrite)
  end;
end;

procedure TAskForm.bbStopClick(Sender: TObject);
begin
  ModalResult:=ord(tact.stop);
end;

procedure TAskForm.bbCompareClick(Sender: TObject);
begin
  ModalResult:=ord(tact.ask);
end;

end.

