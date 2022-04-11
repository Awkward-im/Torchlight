unit fmAsk;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

type

  { TAskForm }

  TAskForm = class(TForm)
    bbContinue: TBitBtn;
    cbForAll: TCheckBox;
    cbCurrentDir: TCheckBox;
    lblWhatToDo: TLabel;
    lblExist: TLabel;
    lblFileName: TLabel;
    rbSkip: TRadioButton;
    rbOverwrite: TRadioButton;
    procedure bbContinueClick(Sender: TObject);
    procedure cbForAllChange(Sender: TObject);
  private

  public
     constructor Create(const fname:string); overload;
  end;

var
  AskForm: TAskForm;

implementation

{$R *.lfm}

uses
  unitComboCommon;

{ TAskForm }

procedure TAskForm.cbForAllChange(Sender: TObject);
begin
  cbCurrentDir.Enabled:=not cbForAll.Checked;
  if cbForAll.Checked then cbCurrentDir.Checked:=false;
end;

constructor TAskForm.Create(const fname: string);
begin
  Create(nil);

  lblFileName.Caption:=fname;
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

end.

