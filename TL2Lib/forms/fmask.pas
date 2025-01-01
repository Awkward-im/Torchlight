{TODO: use ext array in Create like ['.DAT','.LAYOUT' etc]}
{TODO: use double act codes like in ctrl}
unit fmAsk;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  rgglobal;

type

  { TAskForm }

  TAskForm = class(TForm)
    bbContinue: TBitBtn;
    bbStop: TBitBtn;
    bbCompare: TBitBtn;
    bbRename: TBitBtn;
    bbSaveAs: TBitBtn;
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
    procedure bbRenameClick(Sender: TObject);
    procedure bbSaveAsClick(Sender: TObject);
    procedure bbStopClick(Sender: TObject);
    procedure cbForAllChange(Sender: TObject);
  private

  public
    MyResult:TRGDoubleAction;

    constructor Create(const fname:string; aoldsize,anewsize:integer{; amode:integer}); overload;
  end;

var
  AskForm: TAskForm;

implementation

{$R *.lfm}

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
  lext:=ExtractExt(fname);
  bbCompare.Visible:=
      (lext='.DAT') or
      (lext='.TEMPLATE') or
      (lext='.HIE') or
      (lext='.LAYOUT') or
      (lext='.ANIMATION');
  lblFileName.Caption:=fname;
  lblOldSizeNum.Caption:=IntToStr(aoldsize);
  lblNewSizeNum.Caption:=IntToStr(anewsize);

  MyResult:=da_ask;
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
    if cbForAll.Checked then MyResult:=da_skipall
    else                     MyResult:=da_skip
  end
  else //if rbOverwrite.Checked then
  begin
    if      cbForAll    .Checked then MyResult:=da_overwriteall
    else if cbCurrentDir.Checked then MyResult:=da_overwritedir
    else                              MyResult:=da_overwrite
  end;
end;

procedure TAskForm.bbRenameClick(Sender: TObject);
begin
  MyResult:=da_renameold;
end;

procedure TAskForm.bbSaveAsClick(Sender: TObject);
begin
  MyResult:=da_saveas;
end;

procedure TAskForm.bbStopClick(Sender: TObject);
begin
  MyResult:=da_stop;
end;

procedure TAskForm.bbCompareClick(Sender: TObject);
begin
  MyResult:=da_compare;
end;

end.

