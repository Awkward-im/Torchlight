unit fmGUIAlt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, ActnList;

type

  { TRGGUI2Form }

  TRGGUI2Form = class(TForm)
    actChangeVersion: TAction;
    actLeftPanelMode: TAction;
    actRightPanelMode: TAction;
    ActionList: TActionList;
    actFileNew      : TAction;
    actFileOpen     : TAction;
    actFileSave     : TAction;
    actFileSaveAs   : TAction;
    actFileSavePatch: TAction;
    actFileClose    : TAction;
    actFileExit     : TAction;
    actShowLog  : TAction;
    actHelpAbout: TAction;
    ilMain24: TImageList;
    ilMain16: TImageList;
    MainMenu: TMainMenu;
    miEditVersion: TMenuItem;
    miFile: TMenuItem;
    miFileNew      : TMenuItem;
    miFileOpen     : TMenuItem;
    miFileSave     : TMenuItem;
    miFileSaveAs   : TMenuItem;
    miFileSavePatch: TMenuItem;
    miFileClose    : TMenuItem;
    miFileSep1     : TMenuItem;
    miFileExit     : TMenuItem;
    miEdit: TMenuItem;
    miHelp: TMenuItem;
    miHelpShowLog  : TMenuItem;
    miHelpAbout    : TMenuItem;
    pnlLeft : TPanel;
    pnlRight: TPanel;
    splPanels: TSplitter;
    StatusBar: TStatusBar;
    ToolBar: TToolBar;
    tbNew    : TToolButton;
    tbOpen   : TToolButton;
    tbSave   : TToolButton;
    tbSep1   : TToolButton;
    tbSaveAs : TToolButton;
    tbPatch  : TToolButton;
    tbSep2   : TToolButton;
    tbShowLog: TToolButton;
    ToolButton1: TToolButton;

    procedure actFileNewExecute   (Sender: TObject);
    procedure actFileOpenExecute  (Sender: TObject);
    procedure actFileSaveExecute  (Sender: TObject);
    procedure actFileSaveAsExecute(Sender: TObject);
    procedure actFileCloseExecute (Sender: TObject);
    procedure actFileExitExecute  (Sender: TObject);
    procedure actChangeVersionExecute(Sender: TObject);
    procedure actLeftPanelModeExecute(Sender: TObject);
    procedure actRightPanelModeExecute(Sender: TObject);
    procedure actShowLogExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose (Sender: TObject; var CloseAction: TCloseAction);
  private
    inProcess:Boolean;

    procedure LoadSettings;
    procedure UpdatePanels(actrl:pointer);
    function  GUIOnChange(actrl:pointer; idx:integer; atype:integer):integer;
  public

  end;

var
  RGGUI2Form: TRGGUI2Form;

implementation

{$R *.lfm}

uses
  LCLType,
  IniFiles,

  RGGlobal,
  RGCtrl,

  fmLog,
  fmGameVersion,

  RGGUI.Core,
  RGGUI.Shared,
  RGPreview,
  RGPlugins,

  fmCoreCfg,
  fmPanel;

const
  fpLeft  = 0;
  fpRight = 1;

{ TRGGUI2Form }

{%REGION Settings}
procedure TRGGUI2Form.LoadSettings;
var
  config:TIniFile;
  ls:AnsiString;
  lstyle:TFontStyles;
  lfont:TFont;
begin
  config:=TIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes]);
{
  LastExt               :=config.ReadString (sSectSettings,sExt         ,RGDefaultExt);
  LastFilter            :=config.ReadInteger(sSectSettings,sFilter      ,5);
}
{
  bShowDir     :=config.ReadBool(sSectSettings,sShowDir     ,true);
  bShowExt     :=config.ReadBool(sSectSettings,sShowExt     ,true);
  bShowPacked  :=config.ReadBool(sSectSettings,sShoPacked   ,false);
  bShowUnpacked:=config.ReadBool(sSectSettings,sShowUnpacked,false);
}
{
  bShowCategory:=config.ReadBool(sSectSettings,sShowCategory,false);
  bShowTime    :=config.ReadBool(sSectSettings,sShowTime    ,false);
  bShowSource  :=config.ReadBool(sSectSettings,sShowSource  ,false);
}
{
  if cbPreview.Checked then
    actShowPreview.Checked:=config.ReadBool(sSectSettings,sShowPreview,false)
  else
    actShowPreview.Checked:=False;
  cbPreview.Checked:=config.ReadBool(sSectSettings,sPreview,true);
  if not cbPreview.Checked then actPreviewExecute(Self); // call automatically if Checked
}
{
  cbSaveWidth.Checked:=config.ReadBool(sSectSettings,sSaveWidth,true);

  if cbSaveWidth.Checked then
  begin
    pnlTree.Width:=config.ReadInteger(sSectSettings,sTreeWidth,defTreeWidth);
    Splitter2.Left:=config.ReadInteger(sSectSettings,sGridWidth,defGridWidth);
  end
  else
  begin
    pnlTree.Width:=defTreeWidth;
    sgMain .Width:=defGridWidth;
  end;
}
//--- Font
  lfont:=GetPreviewFont();
  lfont.Name   :=config.ReadString (sSectSrcFont,sFontName   ,defFontName);
  lfont.Charset:=config.ReadInteger(sSectSrcFont,sFontCharset,defFontCharset);
  lfont.Size   :=config.ReadInteger(sSectSrcFont,sFontSize   ,defFontSize);
  lfont.Color  :=StringToColor(
      config.ReadString(sSectSrcFont,sFontColor,ColorToString(defFontColor)));

  ls:=config.ReadString(sSectSrcFont,sFontStyle,defFontStyle);
  lstyle:=[];
  if Pos('bold'     ,ls)<>0 then lstyle:=lstyle+[fsBold];
  if Pos('italic'   ,ls)<>0 then lstyle:=lstyle+[fsItalic];
  if Pos('underline',ls)<>0 then lstyle:=lstyle+[fsUnderline];
  if Pos('strikeout',ls)<>0 then lstyle:=lstyle+[fsStrikeOut];
  lfont.Style:=lstyle;
//  SetPreviewFont(lfont);

//  fmFilterForm.LoadSettings(config);
  config.Free;
end;
{%ENDREGION Settings}

{%REGION Form}
procedure TRGGUI2Form.FormCreate(Sender: TObject);
begin
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

    SetColumnState(colType,true);
    SetColumnState(colTime,true);
    SetColumnState(colSize,true);
    SetColumnState(colAttr,true);
    ListIndex:=0;
  end;

  Panels[fpRight]:=TPanelForm.Create(Self);
  with TPanelForm(Panels[fpRight]) do
  begin
    Parent     :=pnlRight;
    BorderStyle:=bsNone;
    Align      :=alClient;
    Visible    :=True;

    SetColumnState(colType,true);
    SetColumnState(colTime,true);
    SetColumnState(colSize,true);
    SetColumnState(colAttr,true);
    ListIndex:=1;
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

  CtrlList[0].Ctrl^.OnChange:=@GUIOnChange;
end;

procedure TRGGUI2Form.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ClosePreviews();
end;

{%ENDREGION Form}

procedure TRGGUI2Form.UpdatePanels(actrl:pointer);
begin
  // really needs? can be in FillCombo.
  if actrl<>nil then
  begin
    //  Panels[ActivePanel].Ctrl^.OnChange:=@GUIOnChange;
    TPanelForm(Panels[ActivePanel]).SetCtrl(actrl);
  end;
  TPanelForm(Panels[fpLeft ]).FillCombo();
  TPanelForm(Panels[fpRight]).FillCombo();
end;

{%REGION Actions}
  {%REGION File}
procedure TRGGUI2Form.actFileNewExecute(Sender: TObject);
var
  lctrl:pointer;
begin
  lctrl:=NewPak();
  CtrlList[CtrlCount-1].Ctrl^.OnChange:=@GUIOnChange;
  UpdatePanels(lctrl);
end;

procedure TRGGUI2Form.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  lctrl:pointer;
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
      CtrlList[CtrlCount-1].Ctrl^.OnChange:=@GUIOnChange;
      UpdatePanels(lctrl);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TRGGUI2Form.actFileSaveExecute(Sender: TObject);
begin
  if TPanelForm(Panels[ActivePanel]).Ctrl^.Save() then
  begin
    ShowMessage(rsSaved);
{
    FreeAndNil(fmi);
    // remove all possible marks, update "size" columns
//FillTree;
    tvTreeSelectionChanged(self);
    // if not implemented in "Save" then
    // close existing
    // reopen
}
  end
  else
    ShowMessage(rsCantSave);
end;

procedure TRGGUI2Form.actFileSaveAsExecute(Sender: TObject);
var
  dlg:TSaveDialog;
  ls:AnsiString;
  lctrl:PRGController;
  lver:integer;
  lresult,lAsPatch:boolean;
begin
  lAsPatch:=Sender=actFileSavePatch;
  lctrl:=TPanelForm(Panels[ActivePanel]).Ctrl;
// must not happen
//  if lctrl=nil then exit;
  dlg:=TSaveDialog.Create(nil);
  try
    case lctrl^.PAK.Version of
      verTL2: dlg.FilterIndex:=1;
      verHob: dlg.FilterIndex:=3;
      verRG : dlg.FilterIndex:=4;
      verRGO: dlg.FilterIndex:=5;
      verTL1: dlg.FilterIndex:=6;
    else
      dlg.FilterIndex:=1;
    end;

    if lasPatch then
      dlg.Title:=rsSavePatch
    else
      dlg.Title:=rsSave;

    dlg.InitialDir:=lctrl^.PAK.Directory;
    dlg.FileName  :=lctrl^.PAK.Name;
    dlg.DefaultExt:=RGDefaultExt;
    dlg.Filter    :=RGDefWriteFilter;
    dlg.Title     :='';
    dlg.Options   :=dlg.Options+[ofOverwritePrompt];

    if (dlg.Execute) then
    begin
      case dlg.FilterIndex of
        1: lver:=verTL2Mod;
        2: lver:=verTL2;
        3: lver:=verHob;
        4: lver:=verRG;
        5: lver:=verRGO;
        6: lver:=verTL1;
      end;

      if lasPatch then
      begin
        lresult:=lctrl^.SavePatch(dlg.Filename,lver);
        ls:=rsSavedPatch;
      end
      else
      begin
        lresult:=lctrl^.SaveAs(dlg.Filename,lver);
        ls:=rsSavedAs;
{
        if result then
        begin
          tvTreeSelectionChanged(self);
          SetupView();
        end;
}
      end;

      if lresult then
        ShowMessage(ls+' '+dlg.Filename)
      else
        ShowMessage(rsCantSave+' '+dlg.Filename);

    end;
  finally
    dlg.Free;
  end;
end;

procedure TRGGUI2Form.actFileCloseExecute(Sender: TObject);
var
  lctrl:PRGController;
  lidx:integer;
begin
  lctrl:=CtrlList[ActiveCtrl].Ctrl;
  if lctrl^.UpdatesCount()>0 then
  begin
    if MessageDlg(rsWarning,rsUnsaved,mtWarning,
       [mbOK,mbCancel],0,mbCancel)<>mrOk then
    begin
      exit;
    end;
  end;

  if CtrlCount=1 then
    Close;

  if TPanelForm(Panels[ActivePanel]).GetPanelType in [panelList,panelTree] then
  begin
    // GetOppositePanel()
    if ActivePanel=0 then lidx:=1 else lidx:=0;
    if TPanelForm(Panels[lidx]).GetPanelType=panelView then
       TPanelForm(Panels[lidx]).ShowPreview(nil,0);

//    lidx:=GetCtrlIndex(nil);
    ClosePreviews(lctrl{CtrlList[lidx].Ctrl});
    ClosePak(lctrl{nil},true);

    UpdatePanels(nil);
  end;
end;

procedure TRGGUI2Form.actFileExitExecute(Sender: TObject);
begin
  Close;
end;
  {%ENDREGION File}

procedure TRGGUI2Form.actShowLogExecute(Sender: TObject);
begin
  if fmLogForm=nil then
  begin
    fmLogForm:=TfmLogForm.Create(Self);
    fmLogForm.memLog.Text:=RGLog.Text;
  end;
  fmLogForm.ShowOnTop;
end;

procedure TRGGUI2Form.actChangeVersionExecute(Sender: TObject);
var
  lpnl:TPanelForm;
  lf:TFmGameVer;
  idx: integer;
begin
{
  idx:=InputCombo(rsChooseVer, rsGameVer,
      ['Torchligh I', 'Torchlight II', 'Hob', 'Rebel Galaxy', 'Rebel Galaxy Outlaw']);
  case idx of
    0: idx:=verTL1;
    1: idx:=verTL2;
    2: idx:=verHob;
    3: idx:=verRG;
    4: idx:=verRGO;
  end;
}
  lpnl:=TPanelForm(Panels[ActivePanel]);
  if lpnl.GetPanelType=panelView then exit;

  lf:=TFmGameVer.Create(Self);
  lf.Version:=lpnl.Ctrl^.PAK.Version;
  if lf.ShowModal=mrOK then
  begin
    idx:=lf.Version;
    if lpnl.Ctrl^.PAK.Version<>idx then
    begin
      lpnl.Ctrl^.PAK.Version:=idx;
      // setup / show version
    end;
  end;
  lf.Free;
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

{%ENDREGION Actions}

function TRGGUI2Form.GUIOnChange(actrl:pointer; idx:integer; atype:integer):integer;
var
  ldir,lname:AnsiString;
  i:integer;
begin
  result:=1;
  case atype of
    faStart : inProcess:=true;
    faFinish: inProcess:=false;
  else
    if not inProcess then
    begin
      ldir :=WideToStr(PRGController(actrl)^.PathOfFile(idx));
      lname:=WideToStr(PRGController(actrl)^.Files[idx]^.Name);
      if rgDebugLevel=dlDetailed then
        RGLog.Add('File affected ('+GetChangesName(atype)+'): '+PRGController(actrl)^.PAK.Name+' | '+ldir+lname);

      for i:=0 to PanelCount-1 do
        TPanelForm(Panels[i]).OnChange(actrl,idx,atype);
    end;
  end;
end;

end.

