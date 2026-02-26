unit fmGUISettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  fmCoreCfg;

type

  { TGUICfgForm }

  TGUICfgForm = class(TCoreCfgForm)
    bbFontEdit: TBitBtn;
    cbPreview: TCheckBox;
    cbSaveWidth: TCheckBox;

    procedure cbPreviewChange(Sender: TObject);
  private

  public

  end;

var
  GUICfgForm: TGUICfgForm;

implementation

{$R *.lfm}

{ TGUICfgForm }

procedure TGUICfgForm.cbPreviewChange(Sender: TObject);
begin
  if cbPreview.Checked then
  begin
    ClosePreviews();
  end;
//  actShowPreview.Checked:=true; // will be inverted
//  actPreviewExecute(Sender);
end;

end.

