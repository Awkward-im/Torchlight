unit fmGUIBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, ActnList,
  rgctrl;

type

  { TRGGUIBaseForm }

  TRGGUIBaseForm = class(TForm)
    ilMain24: TImageList;
    ilMain16: TImageList;

    MainMenu: TMainMenu;
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
    miEditVersion  : TMenuItem;
    miHelp: TMenuItem;
    miHelpShowLog  : TMenuItem;
    miHelpOpenDir  : TMenuItem;
    miHelpSep1     : TMenuItem;
    miHelpAbout    : TMenuItem;

    StatusBar: TStatusBar;
    tbOpenDir: TToolButton;

    ToolBar: TToolBar;
    tbNew    : TToolButton;
    tbOpen   : TToolButton;
    tbSave   : TToolButton;
    tbSep1   : TToolButton;
    tbSaveAs : TToolButton;
    tbPatch  : TToolButton;
    tbSep2   : TToolButton;
    tbShowLog: TToolButton;
    tbSep3   : TToolButton;
    tbInfo   : TToolButton;

    ActionList: TActionList;
    actFileNew      : TAction;
    actFileOpen     : TAction;
    actFileSave     : TAction;
    actFileSaveAs   : TAction;
    actFileSavePatch: TAction;
    actFileClose    : TAction;
    actFileExit     : TAction;
    actHelpAbout    : TAction;
    actShowInfo     : TAction;
    actShowLog      : TAction;
    actOpenDir      : TAction;
    actChangeVersion: TAction;

    procedure actShowLogExecute(Sender: TObject);
    procedure actOpenDirExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure actFileSaveAsExecute(Sender: TObject);
    procedure actChangeVersionExecute(Sender: TObject);

  private
    inProcess:Boolean;

  protected
    procedure ActiveCtrlEvent(actrl:PRGController);
    function  GUIOnChange(actrl:pointer; idx:integer; atype:integer):integer;

  public
    procedure UpdatePanels(arebuild:boolean);
    procedure UpdateFormTitle();

  end;


implementation

{$R *.lfm}

uses
  LCLIntf,

  RGGlobal,
  RGPrepare,

  fmLog,
  fmGameVersion,
  
  RGGUI.Core,
  RGGUI.Shared,
  fmPanel;


{%REGION Actions}
procedure TRGGUIBaseForm.actShowLogExecute(Sender: TObject);
begin
  if fmLogForm=nil then
  begin
    fmLogForm:=TfmLogForm.Create(Self);
    fmLogForm.memLog.Text:=RGLog.Text;
  end;
  fmLogForm.ShowOnTop;
end;

procedure TRGGUIBaseForm.actOpenDirExecute(Sender: TObject);
var
  ls,loutdir:string;
begin
  if cfgUnpackDir='' then
    loutdir:=ExtractFileDir(ParamStr(0))
  else
    loutdir:=cfgUnpackDir;
  if not (loutdir[Length(loutdir)] in ['\','/']) then loutdir:=loutdir+'\';
  if cfgUsePakName and (ActiveCtrl<>nil) then
    ls:=loutdir+ActiveCtrl^.PAK.Name+'\'
  else
    ls:=loutdir;
  if not OpenDocument(ls) then OpenDocument(loutdir);
end;


procedure TRGGUIBaseForm.actFileSaveExecute(Sender: TObject);
var
  lctrl:PRGController;
begin
  lctrl:=ActiveCtrl;
  if lctrl=nil then exit;

  if lctrl^.PAK.Directory='' then
  begin
    actFileSaveAsExecute(Sender);
{!! not new ctrl, just update form title (if version/name was changed)
    if lctrl^.PAK.Directory<>'' then
      SetActiveCtrl(lctrl);
}
    exit;
  end;

  if lctrl^.Save() then
  begin
    ShowMessage(rsSaved);
{
    FreeAndNil(fmi);
    // remove all possible marks, update "size" columns
    // if not implemented in "Save" then
    // close existing
    // reopen
}
  end
  else
    ShowMessage(rsCantSave);
end;

procedure TRGGUIBaseForm.actFileSaveAsExecute(Sender: TObject);
var
  dlg:TSaveDialog;
  lctrl:PRGController;
  ls:AnsiString;
  lver:integer;
  lfirst,lsaved,lAsPatch:boolean;
begin
  lctrl:=ActiveCtrl;
  if lctrl=nil then exit;

  lAsPatch:=Sender=actFileSavePatch;

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
    if lAsPatch then
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
      lfirst:=lctrl^.PAK.Directory='';
      case dlg.FilterIndex of
        1: lver:=verTL2Mod;
        2: lver:=verTL2;
        3: lver:=verHob;
        4: lver:=verRG;
        5: lver:=verRGO;
        6: lver:=verTL1;
      end;
      if lAsPatch then
      begin
        lsaved:=lctrl^.SavePatch(dlg.Filename,lver);
        ls:=rsSavedPatch;
      end
      else
      begin
        lsaved:=lctrl^.SaveAs(dlg.Filename,lver);
        ls:=rsSavedAs;
      end;
      if lsaved then
      begin
        ShowMessage(ls+' '+dlg.Filename);
        if lfirst and (lctrl^.PAK.Directory<>'') then
        begin
          UpdatePanels(false);
          UpdateFormTitle();
        end;
      end
      else
        ShowMessage(rsCantSave+' '+dlg.Filename);
    end;
  finally
    dlg.Free;
  end;
end;

procedure TRGGUIBaseForm.actChangeVersionExecute(Sender: TObject);
var
  lf:TFmGameVer;
  lctrl:PRGController;
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
  lctrl:=ActiveCtrl;
  if lctrl=nil then exit;

  lf:=TFmGameVer.Create(Self);
  lf.Version:=lctrl^.PAK.Version;
  if lf.ShowModal=mrOK then
  begin
    idx:=lf.Version;
    if lctrl^.PAK.Version<>idx then
    begin
      lctrl^.PAK.Version:=idx;
      UpdateFormTitle();
    end;
  end;
  lf.Free;
end;
{%ENDREGION Actions}

procedure TRGGUIBaseForm.UpdatePanels(arebuild:boolean);
var
  i:integer;
begin
  for i:=0 to PanelCount-1 do
    with TPanelForm(Panels[i]) do
      if pnlTop.Visible then FillCombo(0,arebuild);
end;

procedure TRGGUIBaseForm.UpdateFormTitle();
var
  lctrl:PRGController;
begin
  lctrl:=ActiveCtrl;
  if (lctrl=nil) or (lctrl^.PAK.Name='') then
  begin
    Self.Caption:=strProgramName;
  end
  else
  begin
    Self.Caption:=strProgramName+' - ('+GetGameName(lctrl^.PAK.Version)+') '+lctrl^.PAK.Name;
  end;
end;

{%REGION Events}
procedure TRGGUIBaseForm.ActiveCtrlEvent(actrl:PRGController);
begin
  UpdateFormTitle();

  actFileSave     .Enabled:=actrl<>nil;
  actFileSaveAs   .Enabled:=actrl<>nil;
  actFileSavePatch.Enabled:=actrl<>nil;
  actFileClose    .Enabled:=actrl<>nil;
  actChangeVersion.Enabled:=actrl<>nil;
  actShowInfo     .Enabled:=actrl<>nil;
  miEdit          .Enabled:=actrl<>nil;
end;

function TRGGUIBaseForm.GUIOnChange(actrl:pointer; idx:integer; atype:integer):integer;
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

      // 2 - check for feature tags
      if atype<>faInfo then
        if ((ldir=strRootDir) and (lname='FEATURETAGS.HIE')) or
            (ldir='MEDIA/FEATURETAGS/') then
        begin
          PrepareFeatureTags(PRGController(actrl));
        end;
    end;
  end;
end;
{%ENDREGION Events}
end.

