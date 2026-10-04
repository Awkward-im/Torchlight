unit fmItemEdit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Buttons, ExtendedTabControls;

type

  { TFormItemEdit }

  TFormItemEdit = class(TForm)
    bbSave: TBitBtn;
    bbSaveAs: TBitBtn;
    cbAdvanced: TCheckBox;
    cbUTypeGroup: TComboBox;
    cbUnitType: TComboBox;
    edName: TEdit;
    edTitle: TEdit;
    edGUID: TEdit;
    lblName: TLabel;
    lblTitle: TLabel;
    lblGUID: TLabel;
    PageControl: TPageControl;
    pnlCommon : TTabSheet;
    pnlStats  : TTabSheet;
    pnlView   : TTabSheet;
    pnlSound  : TTabSheet;
    pnlAffixes: TTabSheet;
    sbGUID: TSpeedButton;
  private

  public

  end;

var
  FormItemEdit: TFormItemEdit;

implementation

{$R *.lfm}

end.

