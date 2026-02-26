unit fmCoreCfg;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn;

type

  { TCoreCfgForm }

  TCoreCfgForm = class(TForm)
    lblOutDir     : TLabel;
    deOutDir      : TDirectoryEdit;
    cbSaveDateTime: TCheckBox;
    cbUnpackTree  : TCheckBox;
    cbMODDAT      : TCheckBox;
    cbSaveSettings: TCheckBox;
    cbFastScan    : TCheckBox;
    cbTest        : TCheckBox;
    cbUseFName    : TCheckBox;

    gbDecoding: TGroupBox;
    rbGUTSStyle : TRadioButton;
    rbTextRename: TRadioButton;
    rbBinOnly   : TRadioButton;
    rbTextOnly  : TRadioButton;
    cbSaveUTF8  : TCheckBox;

    procedure CoreOptChanged(Sender: TObject);
    procedure CoreDirChanged(Sender: TObject; var Value: String);
  private

  public
    procedure FillSettings;

  end;

var
  CoreCfgForm: TCoreCfgForm;

implementation

{$R *.lfm}

uses
  rggui.core;

procedure TCoreCfgForm.CoreOptChanged(Sender: TObject);
begin
       if Sender=cbUnpackTree   then cfgUnpackTree  :=cbUnpackTree  .Checked
  else if Sender=cbSaveUTF8     then cfgSaveUTF8    :=cbSaveUTF8    .Checked
  else if Sender=cbMODDAT       then cfgMakeMODDAT  :=cbMODDAT      .Checked
  else if Sender=cbFastScan     then cfgFastScan    :=cbFastScan    .Checked
  else if Sender=cbUseFName     then cfgUsePakName  :=cbUseFName    .Checked
  else if Sender=cbSaveDateTime then cfgSaveDateTime:=cbSaveDateTime.Checked
  else if Sender=cbSaveSettings then cfgSaveSettings:=cbSaveSettings.Checked

  else if Sender=rbBinOnly      then cfgSaveMode    :=smBinary
  else if Sender=rbTextOnly     then cfgSaveMode    :=smText
  else if Sender=rbTextRename   then cfgSaveMode    :=smRename
  else if Sender=rbGUTSStyle    then cfgSaveMode    :=smGUTS

  else if Sender=deOutDir       then cfgUnpackDir   :=deOutDir.Text;
end;

procedure TCoreCfgForm.CoreDirChanged(Sender: TObject; var Value: String);
begin
  cfgUnpackDir:=deOutDir.Text;
end;

procedure TCoreCfgForm.FillSettings;
begin
  deOutDir      .Text   :=cfgUnpackDir;
  cbUnpackTree  .Checked:=cfgUnpackTree;
  cbUseFName    .Checked:=cfgUsePakName;
  cbMODDAT      .Checked:=cfgMakeMODDAT;
  cbFastScan    .Checked:=cfgFastScan;
  cbSaveSettings.Checked:=cfgSaveSettings;
  cbSaveDateTime.Checked:=cfgSaveDateTime;
  cbSaveUTF8    .Checked:=cfgSaveUTF8;
  case cfgSaveMode of
    smBinary: rbBinOnly  .Checked:=true;
    smText  : rbTextOnly .Checked:=true;
    smGUTS  : rbGUTSStyle.Checked:=true;
  else // smRename
    rbTextRename.Checked:=true;
  end;
end;

end.

