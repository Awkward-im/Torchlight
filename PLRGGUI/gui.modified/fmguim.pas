{TODO: 1-setting to save linked file on disk/mem; 2-ask every time/once}
{TODO: Add file search}
unit fmGUIM;

{$mode objfpc}{$H+}
{$WARN 4055 off : Conversion between ordinals and pointers is not portable}
{$WARN 5024 off : Parameter "$1" not used}
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  ActnList, ExtCtrls, StdCtrls, Buttons,
  fmGUIBase, RGGlobal, RGPak, RGCtrl, Types;

type

  { TRGGUIMForm }

   TRGGUIMForm = class(TRGGUIBaseForm)
    pnlGrid: TPanel;
    Settings: TTabSheet;

    PageControl: TPageControl;

    pnlTree: TPanel;

    Grid   : TTabSheet;
    pnlAdd : TPanel;

    Splitter1: TSplitter;
    Splitter2: TSplitter;

    actShowPreview: TAction;
    actEdImport   : TAction; // Load (import) content
    actEdImportDir: TAction;

    tbEdPreview  : TToolButton;
    tbEdImport   : TToolButton;

    procedure actFileOpenExecute     (Sender: TObject);
    procedure actFileCloseExecute    (Sender: TObject);
    procedure actFileExitExecute     (Sender: TObject);
    procedure actShowInfoExecute(Sender: TObject);
    procedure actEdImportDirExecute(Sender: TObject);
    procedure actEdImportExecute(Sender: TObject);
    procedure actPreviewExecute(Sender: TObject);

    procedure FormClose    (Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate   (Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  private
    fmPreview:TForm;
    fmi:TForm;
    FCtrl:PRGController;

    LastExt:string;
    LastFilter:integer;
{
    bShowCategory: Boolean;
    bShowTime    : Boolean;
    bShowSource  : Boolean;
}
    procedure ClearInfo();
    function  FileClose: boolean;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure SetupView;

    function  MPanelType(apanel:TForm; atype:integer; abefore:boolean):integer;
    procedure MChangeDir(aidx:integer; actrl:PRGController; aList:integer);
    function  OnImportDouble(actrl:PRGController; idx:integer;
              var newdata:PByte; var newsize:integer):TRGDoubleAction;
  public
  end;

var
  RGGUIMForm: TRGGUIMForm;


implementation

{$R *.lfm}

uses
  LCLIntf,
  LCLType,
  IniFiles,
  Clipbrd,

  fmModInfo,
  fmAskNew,
  fmComboDiff,

  RGGUI.Core,
  RGGUI.Shared,
  RGPreview,
  RGPlugins,

  fmPanel,
  fmCoreCfg,
//  fmGUISettings,

  RGFileType,
  RGFile;


{%REGION Constants}

const
  fpTree    = 0;
  fpList    = 1;
  fpPreview = 2;

const
  sShowPreview  = 'showpreview';
{%ENDREGION Constants}

{ TRGGUIMForm }

{%REGION Settings}
procedure TRGGUIMForm.SaveSettings;
var
  config:TIniFile;
begin
  config:=TMemIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  SaveCoreSettings(config);
  SaveGUISettings (config);
(*
  config.WriteString (sSectSettings,sExt         ,LastExt);
  config.WriteInteger(sSectSettings,sFilter      ,LastFilter);
*)
  config.WriteBool   (sSectSettings,sShowPreview ,actShowPreview.Checked);

  config.UpdateFile;
  config.Free;
end;

procedure TRGGUIMForm.LoadSettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  LoadGUISettings(config);
(*
  LastExt               :=config.ReadString (sSectSettings,sExt         ,RGDefaultExt);
  LastFilter            :=config.ReadInteger(sSectSettings,sFilter      ,RGDefaultFilter);
*)
  actShowPreview.Checked:=not config.ReadBool(sSectSettings,sShowPreview,false);
  actPreviewExecute(Self);

  config.Free;
end;
{%ENDREGION Settings}

{%REGION Form}
procedure TRGGUIMForm.SetupView;
begin
  actFileSave.Enabled:=(FCtrl^.DirCount>1) or (FCtrl^.FileCount>0);

  if FCtrl^.PAK.Name='' then
  begin
    Self.Caption:='RGGUI';
  end
  else
  begin
    Self.Caption:='RGGUI - ('+GetGameName(FCtrl^.PAK.Version)+') '+FCtrl^.PAK.Name;
  end;

  StatusBar.Panels[0].Text:=rsFiles+IntToStr(FCtrl^.FileCount)+
                            rsDirs +IntToStr(FCtrl^.DirCount);
  StatusBar.Panels[1].Text:=rsReady;
end;

procedure TRGGUIMForm.FormCreate(Sender: TObject);
begin
  Inherited;

  CoreCfgForm:=TCoreCfgForm.Create(Self);
  with CoreCfgForm do
  begin
    Parent     :=self.Settings;
    BorderStyle:=bsNone;
    Align      :=alClient;
    Visible    :=true;
  end;

  LoadSettings();

  if ParamCount>0 then
  begin
    StatusBar.Panels[1].Text:=rsReadPAK;
    Application.ProcessMessages;

    FCtrl:=LoadPak(ParamStr(1));
  end
  else
    FCtrl:=NewPak();

  PanelCount:=3;

  Panels[fpTree]:=TPanelForm.Create(Self);
  with TPanelForm(Panels[fpTree]) do
  begin
    ListIndex:=0;

    Parent     :=self.pnlTree;
    BorderStyle:=bsNone;
    Align      :=alClient;
    Visible    :=True;

    SetCtrl(FCtrl);
    SetPanelType(panelTree);

    pnlTop    .Visible:=true;
    cbContent .Visible:=false;
    sbTree    .Visible:=false;
    pnlTopTree.Align  :=alClient;
    pnlPath   .Visible:=false;

    OnPanelType:=@MPanelType;
  end;

  Panels[fpList]:=TPanelForm.Create(Self);
  with TPanelForm(Panels[fpList]) do
  begin
    ListIndex:=1;

    pnlTop.Visible:=false;

    Parent     :=self.pnlGrid;
    BorderStyle:=bsNone;
    Align      :=alClient;
    Visible    :=True;

    SetCtrl(FCtrl);
    SetPanelType(panelList);
    SetColumnState(colType,true);
    SetColumnState(colTime,true);
    SetColumnState(colSize,true);
    SetColumnState(colAttr,true);

    pnlTop    .Visible:=true;
    cbContent .Visible:=false;
    sbTree    .Visible:=false;
    pnlTopList.Align  :=alClient;
    pnlPath   .Visible:=true;

    FillList(GetActiveDir(Ctrl,ListIndex));
    OnPanelType:=@MPanelType;
  end;
  
  Panels[fpPreview]:=TPanelForm.Create(Self);
  with TPanelForm(Panels[fpPreview]) do
  begin
    ListIndex:=2;

    pnlTop.Visible:=false;

    Parent     :=self.pnlAdd;
    BorderStyle:=bsNone;
    Align      :=alClient;
    Visible    :=True;

//??    SetCtrl(FCtrl);
    SetPanelType(panelView);
    OnPanelType:=@MPanelType;
  end;

  ClearInfo();

  SetupView();

  FCtrl^.OnChange:=@GUIOnChange;
  AddDirEventHandler(@MChangeDir);

  PageControl.ActivePageIndex:=1;
//  inProcess:=false;

  FillEditMenu(miEdit);
end;

procedure TRGGUIMForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //  if actFileExit.Enabled then actFileExitExecute(Sender);
//  if actFileExit.Enabled then
  if not FileClose then
  begin
    CloseAction:=caNone;
    exit;
  end;

  ClosePreviews();

  SaveSettings();

  Inherited;
end;

procedure TRGGUIMForm.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  lp:TPoint;
  lnode:TTreeNode;
  ls,lname:string;
  pc:PWideChar;
  i:integer;
begin
  GetCursorPos(lp);
  lnode:=nil;
  // check Grid
{!!
  if sgMain.MouseToCell(sgMain.ScreenToClient(lp)).X>=0 then
  begin
    lnode:=tvTree.Selected;
  end
  // check Tree
  else
  begin
    lp:=tvTree.ScreenToClient(lp);
    lnode:=tvTree.GetNodeAt(lp.X, lp.Y);
  end;
}
  if lnode<>nil then
  begin
//!!    ls:=GetPathFromNode(lnode);
    for i:=0 to High(FileNames) do
    begin
      lname:=FileNames[i];
      if DirectoryExists(lname) then
      begin
        FCtrl^.ImportDir(ls,lname);
      end
      else if FileExists(lname) then
      begin
        pc:=StrToWide(lname);
        FCtrl^.AddFileData(pc, PUnicodeChar(UnicodeString(
            ls+
            FixFileExt(ExtractName(lname))
            )), true);
        FreeMem(pc);
      end;
    end;
//!!    FillTree();
    exit;
  end;
end;

function TRGGUIMForm.MPanelType(apanel:TForm; atype:integer; abefore:boolean):integer;
begin
  result:=TPanelForm(apanel).GetPanelType();
end;

procedure TRGGUIMForm.MChangeDir(aidx:integer; actrl:PRGController; aList:integer);
var
  olddir:integer;
begin
  // check old dir but can compare aList
  with TPanelForm(Panels[fpTree]) do
  begin
    olddir:=GetactiveDir(Ctrl,ListIndex);
    if aidx<>olddir then
    begin
      SetActiveDir(aidx,Ctrl,ListIndex);
      SelectTreePath(aidx);
//      FillTree();
    end;
  end;
  with TPanelForm(Panels[fpList]) do
  begin
    olddir:=GetactiveDir(Ctrl,ListIndex);
    if aidx<>olddir then FillList(aidx);
  end;
end;
{%ENDREGION Form}

{%REGION Preview}
procedure TRGGUIMForm.ClearInfo();
var
  bNoTree:boolean;
begin
  if fmPreview<>nil then
  begin
    fmPreview.Free;
    fmPreview:=nil;
  end;

//!!  bNoTree:=tvTree.Items.Count=0;

  actEdImport.Enabled:=not bNoTree;
end;

procedure TRGGUIMForm.actPreviewExecute(Sender: TObject);
begin
  actShowPreview.Checked:=not actShowPreview.Checked;
  if actShowPreview.Checked then
  begin
    pnlGrid.Align:=alLeft;
    Splitter2.Visible:=true;
    pnlAdd.Visible:=true;
  end
  else
  begin
    ClearInfo();
    pnlAdd.Visible:=false;
    Splitter2.Visible:=false;
    pnlGrid.Align:=alClient;
  end;
end;
{%ENDREGION Preview}

{%REGION Actions}
function TRGGUIMForm.FileClose:boolean;
begin
  if FCtrl^.UpdatesCount()>0 then
  begin
    if MessageDlg(rsWarning,rsUnsaved,mtWarning,
       [mbOK,mbCancel],0,mbCancel)<>mrOk then
    begin
      exit(false);
    end;
  end;

  ClearInfo();

  ClosePreviews(FCtrl);
  ClosePak(FCtrl);
  FCtrl:=nil;

  FreeAndNil(fmi);

  result:=true;
end;

procedure TRGGUIMForm.actFileExitExecute(Sender: TObject);
begin
//  if FileClose() then
  begin
//    actFileExit.Enabled:=false;
    Close;
  end;
end;

procedure TRGGUIMForm.actFileCloseExecute(Sender: TObject);
begin
  if FileClose() then
  begin
    NewPAK();
    SetupView();

    with TPanelForm(Panels[fpTree]) do
    begin
      SetCtrl(FCtrl);
      FillTree();
    end;
    with TPanelForm(Panels[fpList]) do
    begin
      SetCtrl(FCtrl);
      FillList(0);
    end;

    FCtrl^.OnChange:=@GUIOnChange;
  end;
end;

procedure TRGGUIMForm.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Options    :=[ofFileMustExist];
    OpenDialog.DefaultExt :=LastExt;
    OpenDialog.Filter     :=RGDefReadFilter;
    OpenDialog.FilterIndex:=LastFilter;

    if OpenDialog.Execute then
    begin
      LastExt   :=OpenDialog.DefaultExt;
      LastFilter:=OpenDialog.FilterIndex;

      FileClose();

      FCtrl:=LoadPak(OpenDialog.FileName);
      SetupView();

      with TPanelForm(Panels[fpTree]) do
      begin
        SetCtrl(FCtrl);
        FillTree();
      end;
      with TPanelForm(Panels[fpList]) do
      begin
        SetCtrl(FCtrl);
        FillList(0);
      end;

      FCtrl^.OnChange:=@GUIOnChange;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TRGGUIMForm.actShowInfoExecute(Sender: TObject);
begin
  if fmi=nil then
  begin
    fmi:=TMODInfoForm.Create(Self,@(FCtrl^.PAK.modinfo),false);
//    TMODInfoForm(fmi).LoadFromInfo(ctrl.PAK.modinfo);
  end;
  fmi.ShowOnTop;
end;

procedure TRGGUIMForm.actEdImportExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  pc:PWideChar;
  ldir:string;
  i:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Options    :=[ofFileMustExist,ofAllowMultiSelect,ofEnableSizing];
    OpenDialog.DefaultExt :='.*';
    OpenDialog.Filter     :='';
    OpenDialog.FilterIndex:=0;

    if OpenDialog.Execute then
    begin
//!!      ldir:=GetPathFromNode(tvTree.Selected);
      for i:=0 to OpenDialog.Files.Count-1 do
      begin
        pc:=StrToWide(OpenDialog.Files[i]);
        // add update as file content (as is)
        FCtrl^.AddFileData(pc, PUnicodeChar(UnicodeString(
            ldir+FixFileExt(ExtractName(OpenDialog.Files[i])))), true);
        FreeMem(pc);
      end;
//!!      FillGrid(IntPtr(tvTree.Selected.Data));
    end;
  finally
    OpenDialog.Free;
  end;
end;

function TRGGUIMForm.OnImportDouble(actrl:PRGController; idx:integer;
         var newdata:PByte; var newsize:integer):TRGDoubleAction;
var
  ls:AnsiString;
  f:file of byte;
  lold,lnew:PByte;
  loldsize,lnewsize:integer;
  istext:boolean;
begin
  lnew:=nil;
  lold:=nil;

//  istext:=(RGTypeOfExt(FCtrl^.Files[idx]^.Name) and $FF)=typeData;
  istext:=(actrl^.Files[idx]^.ftype and $FF)=typeData;

  // if size=0 then newdata is PUnicodeChar'ed filename
  lnewsize:=newsize;
  if newsize=0 then
  begin
    if istext then
    begin
      DecompileFile(PUnicodeChar(newdata),lnew,false);
      lnewsize:=Length(PUnicodeChar(lnew))*SizeOf(WideChar);
    end
    else
    begin
      {$I-}
      AssignFile(f,PUnicodeChar(newdata));
      Reset(f);
      if IOResult=0 then
      begin
        lnewsize:=Filesize(f);
        GetMem(lnew,lnewsize);
        BlockRead(f,lnew^,lnewsize);
        CloseFile(f);
      end;
    end;
  end;

  // Check for same file
  loldsize:=actrl^.GetSource(idx,lold);
  if loldsize=lnewsize then
  begin
    if CompareMem(lold,lnew,loldsize) then
    begin
      FreeMem(lold);
      FreeMem(lnew);
      exit(da_skip);
    end;
  end;

  if newsize=0 then
    ls:=FastWideToStr(PUnicodeChar(newdata))
  else
    ls:=FastWideToStr(actrl^.PathOfFile(idx))+FastWideToStr(actrl^.NameOfFile(idx));
  with tAskForm.Create(ls, loldsize, lnewsize) do
  begin
    result:=ModalToAction(ShowModal());
    Free;
  end;
  
  case result of
    da_renameold: begin
      newdata:=PByte(StrToWide(
          InputBox('Rename existing file', 'Enter new name', actrl^.NameOfFile(idx)) ));
    end;

    da_saveas: begin
      newdata:=PByte(StrToWide(
          InputBox('Rename new file', 'Enter new name', actrl^.NameOfFile(idx)) ));
    end;

    da_compare: begin
      if istext then
      begin
        with TCompareForm.Create(lold,lnew) do
        begin
          if ShowModal()=mrOk then
          begin
            newdata:=PByte(UnicodeText());
            newsize:=(Length(PUnicodeChar(newdata))+1)*SizeOf(WideChar);
          end
          else
            result:=da_skip;

          Free;
        end;
      end;
    end;

  else
  end;

  FreeMem(lold);
  FreeMem(lnew);
end;

procedure TRGGUIMForm.actEdImportDirExecute(Sender: TObject);
var
  ldir:string;
  lcnt:integer;
begin
  if SelectDirectory(rsSelectDir,'',ldir) then
  begin
//    if (Sender as TAction).ActionComponent=miTreeAdd then
    begin
//      AddNewDir(PopupNode,ExtractName(ldir));
    end;

    FCtrl^.OnDouble:=@OnImportDouble;
//!!    lcnt:=FCtrl^.ImportDir(GetPathFromNode(tvTree.Selected),ldir);
    FCtrl^.OnDouble:=nil;
//!!    FillTree();
    if lcnt>0 then
      ShowMessage(IntToStr(lcnt)+rsImported+#13#10+rsLinkingNote)
    else
      ShowMessage(rsNothingImported);
  end;
end;
{%ENDREGION Actions}


end.
