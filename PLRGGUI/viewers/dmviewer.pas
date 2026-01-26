{
  This is common unit for previews
}
unit DMViewer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  Controls, Menus,
  Graphics, Forms, ExtCtrls,
  SynPopupMenu,
  SynHighlighterXML,
  SynHighlighterT,
  SynHighlighterOgre,
  RGCtrl;

type

  { TViewer }

  TViewer = class(TDataModule)
    ilBookmarks: TImageList;
    ilViewer   : TImageList;
    miCalcHash: TMenuItem;
    SynPopupMenu: TSynPopupMenu;
    SynXMLSyn: TSynXMLSyn;

    procedure DataModuleCreate (Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure miCalcHashClick  (Sender: TObject);
  private

  public
    Font: TFont;
    SynOgreSyn:TSynOgreSyn;
    SynTSyn   :TSynTSyn

  end;

var
  Viewer: TViewer;

const
  iiPlay    = 0;
  iiStop    = 1;
  iiSave    = 2;
  iiFind    = 3;
  iiReload  = 4;
  iiStretch = 5;
  iiDarkBg  = 6;
  iiHash    = 7;
  iiFix     = 8;

type
  { TBaseViewer }

  TBaseViewer = class(TForm)
    pnlInfo: TPanel;

    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure DoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private

  public
    ctrl:PRGController;
    idx :integer;

    constructor Create({AOwner:TComponent; }var actrl:TRGController; aidx:integer); overload;
  end;


implementation

{$R *.lfm}

uses
  LCLType,
  StdCtrls,
  SynEdit,
  RGGlobal
  ;


{ TViewer }

procedure TViewer.DataModuleCreate(Sender: TObject);
begin
  Font:=TFont.Create;
end;

procedure TViewer.DataModuleDestroy(Sender: TObject);
begin
  Font.Free;
end;

procedure TViewer.miCalcHashClick(Sender: TObject);
var
  lc:TComponent;
  lsynedit:TSynEdit;
  pt,pp:TPoint;
  lform:TForm;
  lmemo:TMemo;
  ltext:string;
  lhash:dword;
begin
  if Sender is TSynEdit then
  begin
    lsynedit:=Sender as TSynEdit;
    lc:=nil;
  end
  else
  begin
    lc:=((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent;
    if not (lc is TSynEdit) then exit;

    lsynedit:=lc as TSynEdit;
  end;

  ltext:=lSynEdit.SelText;
  if ltext='' then
  begin
    if lc<>nil then
    begin
      pp:=((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupPoint;
      pt:=lSynEdit.PixelsToLogicalPos(
          lSynEdit.ScreenToClient(pp));
    end
    else
    begin
      pt:=lSynEdit.LogicalCaretXY;
      pp:=lSynEdit.ClientToScreen(lSynEdit.LogicalToPhysicalPos(pt));
    end;
    ltext:=lSynEdit.GetWordAtRowCol(pt);
  end;

  if ltext<>'' then
  begin
    lhash:=RGHashB(PAnsiChar(UpCase(ltext)));
    lform:=TForm.Create(Self);
    lform.Left  :=pp.X;
    lform.Top   :=pp.Y;
    lform.Width :=200;
    lform.Height:=120;
    lform.Caption:='Hash';

    lmemo:=TMemo.Create(lform);
    lmemo.Parent  :=lform;
    lmemo.Align   :=alClient;
    lmemo.ReadOnly:=true;
    lmemo.Text    :=ltext+
      #13#10'  Unsigned'#13#10 +IntToStr(lhash)+
      #13#10'  Signed'#13#10 +IntToStr(integer(lhash))+
      #13#10'  Hex'#13#10'$'+IntToHex(lhash);
    lform.ShowModal;
    lform.Free;
{
    ShowMessage(ltext+
      #13#10'U.Hash = ' +IntToStr(lhash)+
      #13#10'S.Hash = ' +IntToStr(integer(lhash))+
      #13#10'H.Hash = $'+IntToHex(lhash));
}
  end;
end;


procedure TBaseViewer.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

constructor TBaseViewer.Create({AOwner:TComponent; }var actrl: TRGController; aidx: integer);
begin
  inherited CreateNew(Viewer{AOwner});

  Height   :=377;
  Width    :=579;
  Position :=poScreenCenter;
  OnClose  :=@FormClose;
  OnKeyDown:=@DoKeyDown;

  pnlInfo:=TPanel.Create(Self);
//    Left = 0
//    Top = 0
//    Width = 579
  pnlInfo.Height:=40;
  pnlInfo.Align :=alTop;
  pnlInfo.Parent:=Self;

  ctrl:=@actrl;
  idx :=aidx;
end;

procedure TBaseViewer.DoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key=VK_ESCAPE) and (Shift=[]) then
  begin
    Key:=0;
    Close;
  end;
end;


finalization
  Viewer.Free;
end.
