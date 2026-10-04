unit fmGUIAlt;

{$mode ObjFPC}{$H+}

interface

{$DEFINE Interface}

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, ActnList,
  RGGlobal, fmGUIBase, RGCtrl;

type

  { TRGGUI2Form }

  TRGGUI2Form = class(TRGGUIBaseForm)
    actCopy          : TAction;
    actCompare       : TAction;
    actLeftPanelMode : TAction;
    actRightPanelMode: TAction;

    pnlLeft  : TPanel;
    pnlRight : TPanel;
    splPanels: TSplitter;

    tbCompare: TToolButton;

    procedure actFileNewExecute   (Sender: TObject);
    procedure actFileOpenExecute  (Sender: TObject);
    procedure actFileCloseExecute (Sender: TObject);
    procedure actFileExitExecute  (Sender: TObject);
    procedure actShowInfoExecute(Sender: TObject);
    procedure actLeftPanelModeExecute (Sender: TObject);
    procedure actRightPanelModeExecute(Sender: TObject);
    procedure actCopyExecute(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormClose (Sender: TObject; var CloseAction: TCloseAction);
  private
{$include copy.inc}
    procedure LoadSettings;
    procedure SaveSettings;
    procedure UpdatePanels(actrl:pointer);
    function  AltPanelType(apanel:TForm; atype:integer; abefore:boolean):integer;
    function  AltExecute(actrl:PRGController; aidx:integer):integer;
    function GetOppositePanel(apanel: TForm): TForm;
  public

  end;

var
  RGGUI2Form: TRGGUI2Form;

implementation

{$R *.lfm}

uses
  LCLType,
  IniFiles,
  FileUtil,

  RGFS,
  RGFileType,

  fmModInfo,
//  fmComboDiff,
  fmAskNew,

  RGGUI.Core,
  RGGUI.Shared,
  RGPreview,
  RGPlugins,

  fmCoreCfg,
  fmPanel;

{$UNDEF Interface}

const
  fpLeft  = 0;
  fpRight = 1;

{ TRGGUI2Form }

{$include copy.inc}

{%REGION Settings}
procedure TRGGUI2Form.LoadSettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes]);
{
  bShowCategory:=config.ReadBool(sSectSettings,sShowCategory,false);
  bShowSource  :=config.ReadBool(sSectSettings,sShowSource  ,false);
  bShowPacked  :=config.ReadBool(sSectSettings,sShoPacked   ,false);
  bShowTime    :=config.ReadBool(sSectSettings,sShowTime    ,false);
}
//  fmFilterForm.LoadSettings(config);

  LoadGUISettings(config);

  config.Free;
end;

procedure TRGGUI2Form.SaveSettings;
var
  config:TIniFile;
begin
  config:=TMemIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  SaveCoreSettings(config);
  SaveGUISettings (config);

  config.UpdateFile;
  config.Free;
end;
{%ENDREGION Settings}

{%REGION Form}
procedure TRGGUI2Form.FormCreate(Sender: TObject);
begin
  Inherited;

  LoadSettings();

  FillEditMenu(miEdit);

  PanelCount:=2;
  Panels[fpLeft]:=TPanelForm.Create(Self);
  with TPanelForm(Panels[fpLeft]) do
  begin
    Parent     :=pnlLeft;
    BorderStyle:=bsNone;
    Align      :=alClient;
    Visible    :=True;

    SetPanelType(panelList);
    SetColumnState(colType,true);
    SetColumnState(colSize,true);
    SetColumnState(colPack,false);
    SetColumnState(colTime,true);
    SetColumnState(colAttr,true);
    ListIndex:=0;
    OnPanelType:=@AltPanelType;
    OnExecute  :=@AltExecute;
  end;

  Panels[fpRight]:=TPanelForm.Create(Self);
  with TPanelForm(Panels[fpRight]) do
  begin
    Parent     :=pnlRight;
    BorderStyle:=bsNone;
    Align      :=alClient;
    Visible    :=True;

    SetPanelType(panelList);
    SetColumnState(colType,true);
    SetColumnState(colSize,true);
    SetColumnState(colPack,false);
    SetColumnState(colTime,true);
    SetColumnState(colAttr,true);
    ListIndex:=1;
    OnPanelType:=@AltPanelType;
    OnExecute  :=@AltExecute;
  end;

  ActivePanel  :=fpLeft;
  ActiveControl:=Panels[ActivePanel];

  if ParamCount>0 then
  begin
    StatusBar.SimpleText:=rsReadPAK;
    LoadPak(ParamStr(1));
  end
  else
    NewPak();
  UpdatePanels(nil);

  ActiveCtrl^.OnChange:=@GUIOnChange;
end;

procedure TRGGUI2Form.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ClosePreviews();

  SaveSettings();

  Inherited;
end;
{%ENDREGION Form}

{%REGION Events}
procedure TRGGUI2Form.UpdatePanels(actrl:pointer);
begin
  // really needs? can be in FillCombo.
  if actrl<>nil then
  begin
    TPanelForm(Panels[ActivePanel]).SetCtrl(actrl);
  end;
  TPanelForm(Panels[fpLeft ]).FillCombo();
  TPanelForm(Panels[fpRight]).FillCombo();
end;

function TRGGUI2Form.GetOppositePanel(apanel:TForm):TForm;
begin
  result:=nil;
  if PanelCount=2 then
  begin
         if Panels[0]=apanel then result:=TPanelForm(Panels[1])
    else if Panels[1]=apanel then result:=TPanelForm(Panels[0]);
  end;
end;

function TRGGUI2Form.AltPanelType(apanel:TForm; atype:integer; abefore:boolean):integer;
var
  lpanel:TPanelForm;
begin
  result:=atype;
  if abefore then
  begin
    if atype in [panelLog, panelView, panelSettings] then
    begin
      lpanel:=TPanelForm(GetOppositePanel(apanel));
      lpanel.FillCombo(atype,false);
//      if lpanel.GetPanelType()=atype then
//        result:=TPanelForm(apanel).GetPanelType();
    end;
  end
  else
  begin
    if atype=panelView then
    begin
      lpanel:=TPanelForm(GetOppositePanel(apanel));
      if lpanel.GetPanelType()=panelList then
      begin
        TPanelForm(apanel).ShowPreview(lpanel.Ctrl,lpanel.GetSelectedFile());
      end;
    end;
  end;
end;

function TRGGUI2Form.AltExecute(actrl:PRGController; aidx:integer):integer;
var
  lctrl:PRGController;
  ls,lsext:AnsiString;
  lform:TForm;
  i:integer;
begin
  result:=0;
  with actrl^.Files[aidx]^ do
  begin
    if ftype=typeUnknown then
    begin
      ls   :=FastWideToStr(Name);
      lsext:=ExtractExt(ls);
      for i:=0 to High(RGPAKExts) do
        if RGPAKExts[i]=lsext then
        begin

          lctrl:=LoadPak(actrl^.PAK.Directory+ls);
          if lctrl<>nil then
          begin
            lctrl^.OnChange:=@GUIOnChange;
            UpdatePanels(lctrl);
          end;

          exit;
        end;
    end;
    if ftype<>typeDirectory then
    begin
      lform:=MakePreview(actrl^,aidx,false);
      if lform<>nil then lform.Show;
    end;
  end;
end;
{%ENDREGION Events}

{%REGION Actions}
  {%REGION File}
procedure TRGGUI2Form.actFileNewExecute(Sender: TObject);
var
  lctrl:PRGController;
begin
  lctrl:=NewPak();
  if lctrl<>nil then
  begin
    lctrl^.OnChange:=@GUIOnChange;
    UpdatePanels(lctrl);
  end;
end;

procedure TRGGUI2Form.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  lctrl:PRGController;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Options    :=[ofFileMustExist];
    OpenDialog.Filter     :=RGDefReadFilter;
//    OpenDialog.FilterIndex:=LastFilter;
//    OpenDialog.DefaultExt :=LastExt;
    OpenDialog.FilterIndex:=RGDefaultFilter;

    if OpenDialog.Execute then
    begin
//      LastExt   :=OpenDialog.DefaultExt;
//      LastFilter:=OpenDialog.FilterIndex;
      lctrl:=LoadPak(OpenDialog.FileName);
      if lctrl<>nil then
      begin
        lctrl^.OnChange:=@GUIOnChange;
        UpdatePanels(lctrl);
      end;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TRGGUI2Form.actFileCloseExecute(Sender: TObject);
var
  lctrl:PRGController;
  lidx:integer;
begin
  lctrl:=ActiveCtrl;
  if lctrl=nil then exit;

  if lctrl^.UpdatesCount()>0 then
  begin
    if MessageDlg(rsWarning,rsUnsaved,mtWarning,
       [mbOK,mbCancel],0,mbCancel)<>mrOk then
    begin
      exit;
    end;
  end;
{
  if CtrlCount=1 then
  begin
    Close;
    exit;
  end;
}
  if TPanelForm(Panels[ActivePanel]).GetPanelType in [panelList,panelTree] then
  begin
    // GetOppositePanel()
    if ActivePanel=0 then lidx:=1 else lidx:=0;
    if TPanelForm(Panels[lidx]).GetPanelType=panelView then
       TPanelForm(Panels[lidx]).ShowPreview(nil,0);

    ClosePreviews(lctrl);
    ClosePak(lctrl,true);

  end;
    UpdatePanels(nil);
end;

procedure TRGGUI2Form.actFileExitExecute(Sender: TObject);
begin
  Close;
end;
  {%ENDREGION File}

procedure TRGGUI2Form.actShowInfoExecute(Sender: TObject);
var
  lctrl:PRGController;
begin
  lctrl:=ActiveCtrl;
  if lctrl=nil then exit;

  with TMODInfoForm.Create(Self,@(lctrl^.PAK.modinfo),false) do
    ShowModal;
end;

procedure TRGGUI2Form.actLeftPanelModeExecute(Sender: TObject);
begin
  with TPanelForm(Panels[fpLeft]).cbContent do
  begin
    DroppedDown:=true;
    SetFocus;
  end;
end;

procedure TRGGUI2Form.actRightPanelModeExecute(Sender: TObject);
begin
  with TPanelForm(Panels[fpRight]).cbContent do
  begin
    DroppedDown:=true;
    SetFocus;
  end;
end;

procedure TRGGUI2Form.actCopyExecute(Sender: TObject);
begin
  Self.Copy();
end;

{%ENDREGION Actions}

end.

