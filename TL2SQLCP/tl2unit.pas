{TODO: TL2GridClick. check for several places in one file}
{TODO: implement (fix) actImportClipBrd}
{TODO: mark unique lines}
unit TL2Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  ShellCtrls, ExtCtrls, StdCtrls, Buttons, ActnList,
  LCLType,StdActns, Grids, Types;

type

  { TMainTL2TransForm }

  TMainTL2TransForm = class(TForm)
    actCheckTranslation: TAction;
    actExportClipBrd: TAction;
    actFilter: TAction;
    actFindNext: TAction;
    actImportClipBrd: TAction;
    actShowAlts: TAction;
    actSettings: TAction;
    actReplace: TAction;
    actShowDoubles: TAction;
    actShowLog: TAction;
    actModInfo: TAction;
    actShowSimilar: TAction;
    actTranslate: TAction;
    HelpNotes: TAction;
    FileExit: TAction;
    FileSave: TAction;
    HelpAbout: TAction;

    FontEdit: TFontEdit;
    memEdit: TMemo;
    cbFolder: TComboBox;
    cbSkills: TComboBox;
    cbLanguage: TComboBox;
    cbDisplayMode: TComboBox;
    edProjectFilter: TEdit;

    miViewSimilar: TMenuItem;
    miViewDoubles: TMenuItem;
    miViewNotes: TMenuItem;
    miViewLog: TMenuItem;
    miView: TMenuItem;
    miEditTranslate: TMenuItem;
    miEditReplace: TMenuItem;
    miEditCheckTranslation: TMenuItem;
    miEditSettings: TMenuItem;
    miEdit: TMenuItem;

    pnlFolders: TPanel;
    pnlSkills: TPanel;
    pnlTop: TPanel;
    sbFindNext: TSpeedButton;
    sbProjectFilter: TSpeedButton;
    Separator1: TMenuItem;
    splFolder: TSplitter;
    splSkills: TSplitter;
    TL2ActionList: TActionList;
    TL2Grid: TStringGrid;
    TL2ProjectFilterPanel: TPanel;
    TL2Toolbar: TToolBar;
    tbFileSave: TToolButton;
    tbSeparator1: TToolButton;
    tbModInfo: TToolButton;
    tbHelpAbout: TToolButton;
    tbFontEdit: TToolButton;
    tbSeparator2: TToolButton;
    miHelpAbout: TMenuItem;
    miFile: TMenuItem;
    miHelp: TMenuItem;
    miFileExit: TMenuItem;
    miFileSave: TMenuItem;
    miFileSep2: TMenuItem;
    TL2MainMenu: TMainMenu;
    TL2StatusBar: TStatusBar;
    tbHelpNotes: TToolButton;
    tbShowLog: TToolButton;
    tbSeparator3: TToolButton;
    tbSettings: TToolButton;
    tbCheckTranslation: TToolButton;
    tbTranslate: TToolButton;
    tbReplace: TToolButton;
    tbSimilar: TToolButton;
    tbDouble: TToolButton;
    tbSeparator4: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    procedure actCheckTranslationExecute(Sender: TObject);
    procedure actExportClipBrdExecute(Sender: TObject);
    procedure actFindNextExecute(Sender: TObject);
    procedure actImportClipBrdExecute(Sender: TObject);
    procedure actModInfoExecute(Sender: TObject);
    procedure actReplaceExecute(Sender: TObject);
    procedure actSettingsExecute(Sender: TObject);
    procedure actShowAltsExecute(Sender: TObject);
    procedure actShowDoublesExecute(Sender: TObject);
    procedure actShowLogExecute(Sender: TObject);
    procedure actShowSimilarExecute(Sender: TObject);
    procedure actTranslateExecute(Sender: TObject);
    procedure cbFolderChange(Sender: TObject);
    procedure cbLanguageChange(Sender: TObject);
    procedure cbSkillsChange(Sender: TObject);
    procedure edProjectFilterChange(Sender: TObject);
    procedure HelpNotesExecute(Sender: TObject);
    procedure HelpAboutExecute(Sender: TObject);
    procedure FileExitExecute(Sender: TObject);
    procedure FileSaveExecute(Sender: TObject);
    procedure FontEditAccept(Sender: TObject);
    procedure FontEditBeforeExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure memEditExit(Sender: TObject);
    procedure memEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TL2GridClick(Sender: TObject);
    procedure TL2GridDblClick(Sender: TObject);
    procedure TL2GridHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure TL2GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TL2GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure TL2GridGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
    procedure TL2GridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure TL2GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure TL2GridSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure TL2GridSetCheckboxState(Sender: TObject; ACol, ARow: Integer; const Value: TCheckboxState);

  private
    FModName:String;

    procedure dlgOnReplace(Sender: TObject);
    procedure FillFoldersCombo(asetidx: boolean);
    procedure FillLangCombo();
    procedure FillProjectGrid(const afilter: AnsiString);
    function  FillProjectSGRow(aRow, idx: integer; const afilter: AnsiString): boolean;
    function  MoveToIndex(idx: integer):integer;
    procedure PasteFromClipBrd();
    procedure ReBoundEditor;
    procedure Search(const atext: AnsiString; aRow: integer);
    procedure SetCellText(arow: integer; const atext: AnsiString);
    procedure UpdateGrid(idx: integer);
    procedure UpdateStatusBar(Sender:TObject; const SBText:AnsiString='');
    function  UpdateCache(arow:integer; const astr:AnsiString):boolean;
    function  CheckTheSame(idx:integer):integer;
    function  NextNoticed(acheckonly:boolean; var idx:integer):integer;
  public

  end;

var
  MainTL2TransForm: TMainTL2TransForm;

implementation

{$R *.lfm}

uses
  LCLIntf,
  ClipBrd,
  iso639,
  rgglobal,
  fmmodinfo,
  unitLogForm,
  TL2DataModule,
  TL2SettingsForm,
  TL2EditText,
  TL2NotesForm,
  TL2DupeForm,
  TL2SimForm,
  TL2AltForm,
  TL2About,
  rgdb.text,
  TL2Text;

{ TMainTL2TransForm }

resourcestring
  rsDefaultCaption = 'Torchlight 2 Translation';
  rsNotSaved       = 'Project modified. Do you want to save it?';

  rsReplaces       = 'Total replaces';
  rsDoDelete       = 'Are you sure to delete selected line(s)?'#13#10+
                     'This text will be just hidden until you save and reload project.';

  rsNoDoubles      = 'No doubles for this text';
  rsDupes          = 'Check doubles info.';
  rsUnique         = '*Unique* ';

  // punctuation check
  rsNoWarnings     = 'No any warnings';
  rsNotes          = 'Punctuation note';
  rsNext           = 'Next note';
  rsFixOne         = 'Fix this';
  rsFixAll         = 'Fix all';
  rsAffected       = ' line(s) affected';

  // folder combobox
  rsFolderAll      = '- All -';    // minus+space to be first
  rsRoot           = '-- Root --'; // minus+minus+space to be second

  // show mode combobox
  rsModeAll        = 'All';
  rsModeReady      = 'Ready';
  rsModeReadyPlus  = 'Translated';
  rsModePartial    = 'Partial';
  rsModeOriginal   = 'Original';
  rsModeNotReady   = 'Not translated';
  rsModeModified   = 'Modified';
  rsModeNational   = 'Non-latin';

const
  colOrigin  = 1;
  colPartial = 2;
  colTrans   = 3;
const
  ModeAll        = 0;
  ModeReady      = 1;
  ModeReadyPlus  = 2;
  ModePartial    = 3;
  ModeOriginal   = 4;
  ModeNotReady   = 5;
  ModeModified   = 6;
  ModeNational   = 7;

//----- Form -----

procedure TMainTL2TransForm.UpdateStatusBar(Sender:TObject; const SBText:AnsiString='');
var
  lrect:TRect;
begin
  if Sender=nil then
  begin
    TL2StatusBar.SimpleText:='';
    Self.Caption:=rsDefaultCaption;
  end
  else if SBText<>'' then
  begin
    TL2StatusBar.SimpleText:=SBText;
    lrect:=TL2StatusBar.ClientRect;
    InvalidateRect(TL2StatusBar.Handle,@lrect,false);
    UpdateWindow  (TL2StatusBar.Handle);
//    Application.ProcessMessages;
  end
  else
  begin
    Self.Caption:=FModName;
  end;
end;

procedure TMainTL2TransForm.FormCreate(Sender: TObject);
begin
  fmLogForm:=nil;

  TL2Settings.Parent     :=Self;
  TL2Settings.BorderStyle:=bsNone;
  TL2Settings.Align      :=alClient;

  Self.Font.Assign(TL2DM.TL2Font);

  cbDisplayMode.AddItem(rsModeAll      ,TObject(ModeAll      ));
  cbDisplayMode.AddItem(rsModeReady    ,TObject(ModeReady    ));
  cbDisplayMode.AddItem(rsModeReadyPlus,TObject(ModeReadyPlus));
  cbDisplayMode.AddItem(rsModePartial  ,TObject(ModePartial  ));
  cbDisplayMode.AddItem(rsModeOriginal ,TObject(ModeOriginal ));
  cbDisplayMode.AddItem(rsModeNotReady ,TObject(ModeNotReady ));
  cbDisplayMode.AddItem(rsModeModified ,TObject(ModeModified ));
  cbDisplayMode.AddItem(rsModeNational ,TObject(ModeNational ));
  cbDisplayMode.ItemIndex:=0;

  LoadModData();

  FillFoldersCombo(true);
  FillLangCombo();

  LoadTranslation();
  FileSave.Enabled:=false;

  FillProjectGrid('');
end;

procedure TMainTL2TransForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if FileSave.Enabled then
  begin
    case MessageDlg(rsNotSaved,mtWarning,mbYesNoCancel,0,mbCancel) of
      mrYes,
      mrOk: FileSaveExecute(self);
      mrCancel: begin
        CloseAction:=caNone;
        exit;
      end;
    else
    end;
  end;
  CloseAction:=caFree;
  MainTL2TransForm:=nil;
end;

{%REGION File Operations}
procedure TMainTL2TransForm.FileExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainTL2TransForm.FileSaveExecute(Sender: TObject);
begin
  FileSave.Enabled:=false;
  SaveTranslation();
end;
{%ENDREGION File Operations}

function TMainTL2TransForm.CheckTheSame(idx:integer):integer;
var
  ltrans:AnsiString;
  litem:PTLCacheElement;
  i,ltmpl:integer;
begin
  result:=0;

  ltrans:=TRCache[idx].dst;
  if ltrans='' then exit;

  ltmpl:=TRCache[idx].tmpl;
  for i:=0 to High(TRCache) do
  begin
    if i<>idx then // not necessary, dst<>'' anyway
    begin
      litem:=@TRCache[i];

      if (litem^.dst =''   ) and
         (litem^.tmpl=ltmpl) then
      begin
        inc(result);
        litem^.dst  :=ReplaceTranslation(PAnsiChar(ltrans),PAnsiChar(litem^.src));
        litem^.part :=true;
        litem^.flags:=litem^.flags or rfIsModified or rfIsAutofill;

        UpdateGrid(i);
      end;
    end;
  end;
end;

function TMainTL2TransForm.UpdateCache(arow:integer; const astr:AnsiString):boolean;
var
  lidx:integer;
begin
  lidx:=IntPtr(TL2Grid.Objects[0,arow]);
  result:=TRCache[lidx].dst<>astr;
  if result then
  begin
    TRCache[lidx].dst  :=astr;
    TRCache[lidx].part :=astr<>'';
    TRCache[lidx].flags:=TRCache[lidx].flags or rfIsModified;
    FileSave.Enabled:=true;

    TL2Grid.Cells[colTrans  ,arow]:=astr;
    TL2Grid.Cells[colPartial,arow]:=BoolNumber[astr<>''];

    if not TL2Grid.IsCellVisible(0,arow) then
      TL2Grid.TopRow:=arow;
    TL2Grid.Col:=colTrans;

    UpdateStatusBar(Self);
  end;
end;

procedure TMainTL2TransForm.actTranslateExecute(Sender: TObject);
var
  ls:AnsiString;
begin
  if memEdit.Visible and (memEdit.Text<>'') then
  begin
    if memEdit.SelLength>0 then
    begin
      memEdit.SelText:=Translate(memEdit.SelText);
      ls:=memEdit.Text;
    end
    else
      ls:=Translate(memEdit.Text);
  end
  else
  begin
    ls:=Translate(TL2Grid.Cells[colOrigin,TL2Grid.Row]);
  end;

  UpdateCache(TL2Grid.Row,ls);
end;

procedure TMainTL2TransForm.dlgOnReplace(Sender: TObject);
var
  ls,lsrc,lr:AnsiString;
  lcnt,i,p:integer;
begin
  lcnt:=0;
  lsrc:=(Sender as TReplaceDialog).FindText;
  lr  :=(Sender as TReplaceDialog).ReplaceText;
  for i:=TL2Grid.Row to TL2Grid.RowCount-1 do
  begin
    ls:=TL2Grid.Cells[colTrans,i];
    p:=Pos((Sender as TReplaceDialog).FindText,ls);
    if p>0 then
    begin
      inc(lcnt);
      ls:=StringReplace(ls,lsrc,lr,[rfReplaceAll]);

      UpdateCache(i,ls);
    end;
  end;
  ShowMessage(rsReplaces+' = '+IntToStr(lcnt));
end;

procedure TMainTL2TransForm.actReplaceExecute(Sender: TObject);
var
  dlg:TReplaceDialog;
begin
  dlg:=TReplaceDialog.Create(Self);
  dlg.Options:=[frHideMatchCase,frHideWholeWord,frHideUpDown,frHideEntireScope,frHidePromptOnReplace];
  dlg.OnReplace:=@dlgOnReplace;
  dlg.Execute;
//  dlg.Free;
end;

procedure TMainTL2TransForm.Search(const atext:AnsiString; aRow:integer);
var
  ltext:AnsiString;
  i:integer;
begin
  ltext:=atext; // already locase
  for i:=aRow to TL2Grid.RowCount-1 do
  begin
    if (Pos(ltext,AnsiLowerCase(TL2Grid.Cells[colOrigin,i]))>0) or
       (Pos(ltext,AnsiLowerCase(TL2Grid.Cells[colTrans ,i]))>0) then
    begin
      TL2Grid.Row   :=i;
      TL2Grid.TopRow:=i;
      ReBoundEditor;
      exit;
    end;
  end;
end;

procedure TMainTL2TransForm.actFindNextExecute(Sender: TObject);
begin
  Search(edProjectFilter.Text,TL2Grid.Row+1);
end;

function TMainTL2TransForm.NextNoticed(acheckonly:boolean; var idx:integer):integer;
begin
  result:=0;

  inc(idx);
  if idx>=High(TRCache) then idx:=0;

  while idx<High(TRCache) do
  begin
    result:=CheckPunctuation(TRCache[idx].src,TRCache[idx].dst,acheckonly);
    if (result<>0) and (acheckonly or ((result and cpfNeedToFix)<>0)) then
      exit;

    inc(idx);
  end;

  idx:=-1;
end;

procedure TMainTL2TransForm.actCheckTranslationExecute(Sender: TObject);
var
  idx,lcnt:integer;
  lres:dword;
  lask:boolean;
begin
  lask:=true;
  lcnt:=0;

  idx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
  lres:=NextNoticed(true,idx);
  if idx<0 then
  begin
    idx:=-1;
    lres:=NextNoticed(true,idx);
  end;

  while idx>=0 do
  begin

    if lask and (lres<>0) then
    begin
      MoveToIndex(idx);
      case QuestionDlg(rsNotes,CheckDescription(lres),mtConfirmation,
        [mrContinue,rsNext,'IsDefault',mrYes,rsFixOne,mrYesToAll,rsFixAll,mrCancel],'') of

        mrContinue: begin
          lres:=0;
        end;

        mrYes: begin
        end;

        mrYesToAll: begin
          lask:=false;
        end;

        mrCancel: break;
      end;
    end;

    if (lres and cpfNeedToFix)<>0 then
    begin
      dec(idx);
      NextNoticed(false,idx); // yes, yes, check it again but with fix at same time
      inc(lcnt);
      TRCache[idx].part :=true;
      TRCache[idx].flags:=TRCache[idx].flags or rfIsModified;
      FileSave.Enabled  :=true;

      //!!!! Like UpdateCache but with index, not row
      UpdateGrid(idx);
    end;

    lres:=NextNoticed(true,idx);

  end;

  if lcnt>0 then
  begin
    UpdateStatusBar(Self);
    ShowMessage(IntToStr(lcnt)+rsAffected);
  end
  else
    ShowMessage(rsNoWarnings);
end;

procedure TMainTL2TransForm.actShowDoublesExecute(Sender: TObject);
var
  lline:integer;
begin
  lline:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);

  if (TRCache[lline].flags and rfIsManyRefs)=0 then
    ShowMessage(rsNoDoubles)
  else
    with TDupeForm.Create(Self,lline) do
    begin
      ShowModal;
      Free;
    end;
end;

procedure TMainTL2TransForm.actShowSimilarExecute(Sender: TObject);
begin
  with TSimilarForm.Create(Self,IntPtr(TL2Grid.Objects[0,TL2Grid.Row])) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TMainTL2TransForm.actShowAltsExecute(Sender: TObject);
begin
  with TAltForm.Create(Self,IntPtr(TL2Grid.Objects[0,TL2Grid.Row])) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TMainTL2TransForm.actModInfoExecute(Sender: TObject);
begin
  with TMODInfoForm.Create(Self,nil,true) do
  begin
{
    Title :=prj.data.ModTitle;
    Author:=prj.data.ModAuthor;
    Descr :=prj.data.ModDescr;
    ID    :=CurMod;
}
    ShowModal;
    Free;
  end;
end;

procedure TMainTL2TransForm.actSettingsExecute(Sender: TObject);
begin
  TL2Settings.Visible:=actSettings.Checked;
end;

{%REGION GUI}
procedure TMainTL2TransForm.actShowLogExecute(Sender: TObject);
begin
  if fmLogForm=nil then
  begin
    fmLogForm:=TfmLogForm.Create(Self);
    fmLogForm.memLog.Text:=RGLog.Text;
  end;
  fmLogForm.ShowOnTop;
end;

procedure TMainTL2TransForm.FontEditAccept(Sender: TObject);
begin
  TL2DM.TL2Font.Assign((Sender as TFontEdit).Dialog.Font);
  Self.Font.Assign(TL2DM.TL2Font);
end;

procedure TMainTL2TransForm.FontEditBeforeExecute(Sender: TObject);
begin
  (Sender as TFontEdit).Dialog.Font.Assign(TL2DM.TL2Font);
end;

procedure TMainTL2TransForm.HelpNotesExecute(Sender: TObject);
begin
  if TL2Notes=nil then
    TL2Notes:=TTL2Notes.Create(Self);
  TL2Notes.Show;
end;

procedure TMainTL2TransForm.HelpAboutExecute(Sender: TObject);
begin
  with TAboutForm.Create(Self) do
  begin
    ShowModal;
    Free;
  end;
end;
{%ENDREGION GUI}

{%REGION MemEdit}
procedure TMainTL2TransForm.ReBoundEditor;
var
  r:TRect;
begin
  r:=TL2Grid.CellRect(colTrans,TL2Grid.Row);
  InflateRect(r,-1,-1);
  memEdit.Tag:=0;
  memEdit.BoundsRect:=r;
end;

procedure TMainTL2TransForm.memEditExit(Sender: TObject);
var
  ls:AnsiString;
  lr,lidx:integer;
begin
  memEdit.Visible:=false;

  if memEdit.Tag=0 then
  begin
    ls:=memEdit.Text;
    lr:=TL2Grid.Row;
    lidx:=IntPtr(TL2Grid.Objects[0,lr]);
    if TRCache[lidx].dst<>ls then
    begin
      if ls=TRCache[lidx].src then ls:='';

      TRCache[lidx].dst  :=ls;
      TRCache[lidx].part :=(TRCache[lidx].part or TL2Settings.cbAsPartial.Checked) and (ls<>'');
      TRCache[lidx].flags:=TRCache[lidx].flags or rfIsModified;
      FileSave.Enabled:=true;

      TL2Grid.Cells[colTrans  ,lr]:=ls;
      TL2Grid.Cells[colPartial,lr]:=BoolNumber[TRCache[lidx].part];

      CheckTheSame(lidx);

      TL2Grid.Row:=lr;
      TL2Grid.Col:=colTrans;

      UpdateStatusBar(Self);
    end;
  end;

  if Visible then TL2Grid.SetFocus;
end;

procedure TMainTL2TransForm.memEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ls:AnsiString;
begin
  if (Key=VK_U) and (Shift=[ssAlt]) then
  begin
    memEdit.SelText:='|u';
    Key:=0;
  end;

  if (Key=VK_N) and (Shift=[ssAlt]) then
  begin
    memEdit.SelText:='\n';
    Key:=0;
  end;

  if (Key=VK_DELETE) and (Shift=[ssAlt]) then
  begin
    if RemoveColor(memEdit.Text,ls) then
    begin
      memEdit.Text:=ls;
      Key:=0;
    end;
  end;

  if (Key=VK_C) and (Shift=[ssAlt]) then
  begin
    ls:=TL2Grid.Cells[colOrigin,TL2Grid.Row];
    if FillColorPopup(memEdit,ls) then
    begin
      Key:=0;
    end;
  end;

  if (Key=VK_V) and (Shift=[ssAlt]) then
  begin
    ls:=TL2Grid.Cells[colOrigin,TL2Grid.Row];
    if FillParamPopup(memEdit,ls) then
    begin
      Key:=0;
    end;
  end;

  if Key=VK_RETURN then
  begin
    memEdit.Tag:=0;
    Key:=VK_TAB;
    TL2Grid.EditingDone;
  end
  else if Key=VK_ESCAPE then
  begin
    memEdit.Tag:=1;
    Key:=VK_TAB;
    memEdit.ExecuteCancelAction;
  end;

  inherited;
end;
{%ENDREGION MemEdit}

{%REGION Grid}
function GetTextLines(const atext:AnsiString; aCanvas:TCanvas; aRect:TRect):integer;
var
  lwidth:integer;
  // complex
  Sentence,CurWord:AnsiString;
  SpacePos,CurX:integer;
  EndOfSentence:Boolean;
begin
  // simple way
(*
  lwidth:=aCanvas.TextWidth(atext);
  result:=round(lwidth/((aRect.Right-aRect.Left{-2*constCellPadding})*0.8)+0.5);

  exit;
*)
  // complex but more accurate way

  result:=1;
  CurX:=aRect.Left+constCellPadding;

  { Here we get the contents of the cell }
  Sentence:=atext;

  { for each word in the cell }
  EndOfSentence:=FALSE;
  while (not EndOfSentence) do
  begin
    { to get the next word, we search for a space }
    SpacePos:=Pos(' ', Sentence);
    if SpacePos>0 then
    begin
      { get the current word plus the space }
      CurWord:=Copy(Sentence,0,SpacePos);

      { get the rest of the sentence }
      Sentence:=Copy(Sentence, SpacePos + 1, Length(Sentence) - SpacePos);
    end
    else
    begin
      { this is the last word in the sentence }
      EndOfSentence:=TRUE;
      CurWord:=Sentence;
    end;

    with aCanvas do
    begin
      { if the text goes outside the boundary of the cell }
      lwidth:=TextWidth(CurWord);
      if (lwidth+CurX)>(aRect.Right-constCellPadding) then
      begin
        { wrap to the next line }
        inc(result);
        CurX:=aRect.Left+constCellPadding;
      end;

      { increment the x position of the cursor }
      CurX:=CurX+lwidth;
    end;
  end;
end;

procedure TMainTL2TransForm.TL2GridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  ls:String;
  ts:TTextStyle;
  count1, count2: integer;
begin
  if not (gdFixed in astate) then
  begin
    with TL2Grid do
    begin
      if (aCol in [colOrigin,colTrans]) then
      begin
        // calculate cell/row height (maybe better to move it to onHeaderSized
        // and re-call after translation text /font changed

        ts:=Canvas.TextStyle;
        ts.SingleLine:=false;
        ts.WordBreak :=true;
        Canvas.TextStyle:=ts;

        count1:=GetTextLines(Cells[colOrigin,aRow],Canvas,CellRect(colOrigin,aRow));
        count2:=GetTextLines(Cells[colTrans ,aRow],Canvas,CellRect(colTrans ,aRow));
        if count2>count1 then count1:=count2;

        if count1>1 then
        begin
          RowHeights[aRow]:=(Canvas.TextHeight('Wg'))*count1+2*constCellPadding;
        end
        else
          RowHeights[aRow]:=DefaultRowHeight;

        if gdSelected in astate then
          Canvas.Brush.Color:=clHighlight
        else
          Canvas.Brush.Color:=clWindow;
        Canvas.Brush.Style:= bsSolid;
        Canvas.FillRect(aRect);

        ls:=Cells[aCol,aRow];
        if (ACol=colOrigin) and (ls<>'') and (ls[Length(ls)]=' ') then
          ls[Length(ls)]:='~';
        Canvas.TextRect(aRect,
          aRect.Left+constCellPadding,aRect.Top+constCellPadding,ls);

        if gdFocused in astate then
          Canvas.DrawFocusRect(aRect);
        exit;
      end;
    end;
  end;

//  (Sender as TStringGrid).DefaultDrawCell(aCol,aRow,aRect,astate);
end;

procedure TMainTL2TransForm.TL2GridGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
begin
  memEdit.Text:=Value;
end;

procedure TMainTL2TransForm.TL2GridPrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
begin
  if (gdFixed in aState) and (aRow>0) then
  begin
    if IsLineUnique(TRCache[IntPtr(TL2Grid.Objects[0,aRow])].id) then
      TL2Grid.Canvas.Brush.Color:=TColor($FFC0CB);
  end;
end;

procedure TMainTL2TransForm.TL2GridHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
begin
  if IsColumn then
    ReBoundEditor;
end;

procedure TMainTL2TransForm.TL2GridClick(Sender: TObject);
var
  ls,ldir,lfile,ltag:AnsiString;
  idx,lline,lflags:integer;
begin
  idx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);

  if (TRCache[idx].flags and rfIsNoRef)<>0 then
    ls:=rsNoRef
  else if (TRCache[idx].flags and rfIsManyRefs)=0 then
  begin
    if GetRef(GetLineRef(TRCache[idx].id),ldir,lfile,ltag,lline,lflags)>0 then
      ls:=ltag+' | '+ldir+lfile
    else
      ls:='';
  end
  else
  begin
//    ls:=StringReplace(rsSeveralRefs,'%d',
//      IntToStr(GetLineRefCount(TRCache[idx].id)),[])+' '+rsDupes;
    lline:=GetLineRefCount(TRCache[idx].id);
    ls:=StringReplace(rsSeveralRefs,'%d',IntToStr(ABS(lline)),[]);
    if lline<0 then
    begin
      if GetRef(GetLineRef(TRCache[idx].id),ldir,lfile,ltag,lline,lflags)>0 then
        ls:=ldir+lfile+' - '+ls;
    end
    else
      ls:=ls+' '+rsDupes;
  end;

  if (CurMod<>modAll) and (CurMod<>modVanilla) then
    if IsLineUnique(TRCache[idx].id) then ls:=rsUnique+ls;

  UpdateStatusBar(Self,ls);
end;

procedure TMainTL2TransForm.TL2GridDblClick(Sender: TObject);
var
  i:integer;
begin
  with TEditTextForm.Create(Self) do
  begin
    i:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
    SelectLine(i);
    if ShowModal=mrOk then
    begin
      for i:=0 to High(TRCache) do
      begin
        if (TRCache[i].flags and rfIsModified)<>0 then
        begin
          FileSave.Enabled:=true;
          break;
        end;
      end;

      MoveToIndex(EditIndex);
      edProjectFilterChange(Self);
      UpdateStatusBar(Self);
    end;
    Free;
  end;
end;

procedure TMainTL2TransForm.TL2GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ls:AnsiString;
  i,idx:integer;
begin
  if (Key=VK_SPACE) then
  begin
    for i:=1 to TL2Grid.RowCount-1 do
    begin
      if TL2Grid.IsCellSelected[TL2Grid.Col,i] then
      begin
        idx:=IntPtr(TL2Grid.Objects[0,i]);

        TRCache[idx].part :=not TRCache[idx].part;
//        TRCache[idx].part:=TL2Grid.Cells[colPartial,i]='1';
        TRCache[idx].flags:=TRCache[idx].flags or rfIsModified;
        TL2Grid.Cells[colPartial,i]:=BoolNumber[TRCache[idx].part];
      end;
    end;
    FileSave.Enabled:=true;
    UpdateStatusBar(Self);
    Key:=0;
  end;

  if (Key=VK_DELETE) then
  begin
    if TL2Grid.Col=colTrans then
    begin
      // remove color tags
      if Shift=[ssAlt] then
      begin
        i:=TL2Grid.Row;
        idx:=IntPtr(TL2Grid.Objects[0,i]);

        ls:=TL2Grid.Cells[colTrans,i];
        if ls='' then ls:=TL2Grid.Cells[colOrigin,i];

        if RemoveColor(ls,ls) then
        begin
          TRCache[idx].dst  :=ls;
          TRCache[idx].part :=true;
          TRCache[idx].flags:=TRCache[idx].flags or rfIsModified;
          TL2Grid.Cells[colPartial,i]:='1';
          TL2Grid.Cells[colTrans  ,i]:=ls;

          FileSave.Enabled:=true;
          UpdateStatusBar(Self);
        end;
      end
      else
      // clear selected translations
      begin
        for i:=1 to TL2Grid.RowCount-1 do
        begin
          if TL2Grid.IsCellSelected[colTrans,i] then
          begin
            if TL2Grid.Cells[colTrans,i]<>'' then
            begin
              idx:=IntPtr(TL2Grid.Objects[0,i]);
              TRCache[idx].dst  :='';
              TRCache[idx].part :=false;
              TRCache[idx].flags:=TRCache[idx].flags or rfIsModified;
              TL2Grid.Cells[colPartial,i]:='0';
              TL2Grid.Cells[colTrans  ,i]:='';

              FileSave.Enabled:=true;
            end;
          end;
        end;
        UpdateStatusBar(Self);
      end;
    end
    else
    begin
      // mark lines as deleted
      if MessageDlg(rsDoDelete,mtConfirmation,mbOkCancel,0)=mrOk then
      begin
        for i:=TL2Grid.RowCount-1 downto 1 do
        begin
          if TL2Grid.IsCellSelected[TL2Grid.Col,i] then
          begin
            TL2Grid.Objects[1,i]:=TObject(1);
          end;
        end;
        for i:=TL2Grid.RowCount-1 downto 1 do
        begin
          if TL2Grid.Objects[1,i]<>nil then
          begin
            idx:=IntPtr(TL2Grid.Objects[0,i]);
            TRCache[idx].flags:=TRCache[idx].flags or rfIsDeleted{ or rfIsModified};

            TL2Grid.DeleteRow(i);
          end;
        end;

        FileSave.Enabled:=true;
        UpdateStatusBar(Self);
      end;
    end;
    Key:=0;
  end;

  if (Key=VK_RETURN) and (Shift=[ssCtrl]) then
  begin
//    actOpenSourceExecute(Sender);
    Key:=0;
    inherited;

    TL2GridDblClick(Sender);
    exit;
  end;

  if (Key=VK_RETURN) and
     (TL2Grid.Col=colTrans) then
    TL2Grid.EditorMode:=true;

  if (Shift=[ssCtrl,ssShift]) and (Key=VK_C) then
  begin
    actExportClipBrdExecute(self);
    Key:=0;
  end;

  if (Shift=[ssCtrl]) then
  begin
    case Key of
      VK_A: begin
        TL2Grid.Selection:=
            TGridRect(Rect(colOrigin,1,colOrigin,TL2Grid.RowCount));
        Key:=0;
      end;

      VK_C: begin
        actExportClipBrdExecute(self);
        Key:=0;
      end;

      VK_V: begin
        if TL2Grid.Col=colTrans then
          PasteFromClipBrd();
        Key:=0;
      end;
    end;
  end;

  inherited;

end;

procedure TMainTL2TransForm.TL2GridSelectCell(Sender: TObject; aCol,
  aRow: Integer; var CanSelect: Boolean);
begin
  if (aRow>0) then TL2GridClick(self);
end;

procedure TMainTL2TransForm.TL2GridSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  ReBoundEditor;
  Editor:=memEdit;
end;

procedure TMainTL2TransForm.TL2GridSetCheckboxState(Sender: TObject; ACol,
  ARow: Integer; const Value: TCheckboxState);
var
  idx:integer;
begin
  idx:=IntPtr(TL2Grid.Objects[0,aRow]);
  TRCache[idx].part :=Value=cbChecked;
  TRCache[idx].flags:=TRCache[idx].flags or rfIsModified;
  TL2Grid.Cells[colPartial,aRow]:=BoolNumber[Value=cbChecked];
  FileSave.Enabled:=true;
  
  UpdateStatusBar(Self);
end;

function TMainTL2TransForm.MoveToIndex(idx:integer):integer;
var
  lrow:integer;
begin
  lrow:=TL2Grid.Row;
  if (lrow<(TL2Grid.RowCount-1)) and (idx=IntPtr(TL2Grid.Objects[0,lrow+1])) then TL2Grid.Row:=lrow+1
  else if (lrow>1)               and (idx=IntPtr(TL2Grid.Objects[0,lrow-1])) then TL2Grid.Row:=lrow-1
  else if (idx<>IntPtr(TL2Grid.Objects[0,lrow])) then
    for lrow:=1 to TL2Grid.RowCount-1 do
    begin
      if idx=IntPtr(TL2Grid.Objects[0,lrow]) then
      begin
        TL2Grid.Row:=lrow;
        if not TL2Grid.IsCellVisible(0,lrow) then
          TL2Grid.TopRow:=lrow;
        break;
      end;
    end;

  result:=TL2Grid.Row;
end;

procedure TMainTL2TransForm.UpdateGrid(idx:integer);
var
  lrow:integer;
begin
  lrow:=MoveToIndex(idx);

  TL2Grid.Cells[colTrans  ,lrow]:=TRCache[idx].dst;
  TL2Grid.Cells[colPartial,lrow]:=BoolNumber[TRCache[idx].part];
end;

function TMainTL2TransForm.FillProjectSGRow(aRow, idx:integer;
          const afilter:AnsiString):boolean;
var
  i:integer;
  b:boolean;
begin
  result:=false;

  if (TRCache[idx].flags and rfIsDeleted)<>0 then exit;
  if (TRCache[idx].flags and rfIsFiltered)=0 then exit;

  // Display Mode
  case UIntPtr(cbDisplayMode.Items.Objects[cbDisplayMode.ItemIndex]) of
    ModeAll      : ;
    ModeReady    : if (TRCache[idx].dst ='') or (TRCache[idx].part) then exit;
    ModeReadyPlus: if (TRCache[idx].dst ='') then exit;
    ModePartial  : if not TRCache[idx].part  then exit;
    ModeOriginal : if (TRCache[idx].dst<>'') then exit;
    ModeNotReady : if (TRCache[idx].dst<>'') and (not TRCache[idx].part) then exit;
    ModeModified : if (TRCache[idx].flags and rfIsModified)=0 then exit;
    ModeNational : begin
      b:=false;
      with TRCache[idx] do
        for i:=1 to Length(src)-1 do
        begin
          if ORD(src[i])>127 then
          begin
            b:=true;
            break;
          end;
        end;
      if not b then exit;
    end;
  end;

  // Filter
  if (afilter<>'') then
  begin
    if (pos(afilter,AnsiLowerCase(TRCache[idx].src))=0) and
      ((TRCache[idx].dst='') or
       (pos(afilter,AnsiLowerCase(TRCache[idx].dst))=0)) then exit;
  end;

  result:=true;

  TL2Grid.Cells[colOrigin ,aRow]:=TRCache[idx].src;
  TL2Grid.Cells[colPartial,aRow]:=BoolNumber[TRCache[idx].part];
  TL2Grid.Cells[colTrans  ,aRow]:=TRCache[idx].dst;

  TL2Grid.Objects[0,aRow]:=TObject(IntPtr(idx));
end;

procedure TMainTL2TransForm.FillProjectGrid(const afilter:AnsiString);
var
  i,lline:integer;
  lSavedRow,lSavedIdx:integer;
begin
  lSavedRow:=0;
  if TL2Grid.Row<1 then
    lSavedIdx:=0
  else
    lSavedIdx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);

  TL2Grid.Clear;
  TL2Grid.BeginUpdate;
  lline := 1;

  TL2Grid.RowCount:=Length(TRCache)+1;
  for i:=0 to High(TRCache) do
  begin
    if FillProjectSGRow(lline,i,afilter) then
    begin
      if (lSavedRow=0) and (lSavedIdx>=i) then lSavedRow:=lline;
      inc(lline);
    end;
  end;

  TL2Grid.RowCount:=lline;
  TL2Grid.Cells[0,0]:=IntToStr(lline-1);

  TL2Grid.EndUpdate;

  if (lSavedRow=0) and (lline>1) then lSavedRow:=1;
  TL2Grid.Row:=lSavedRow;

  if (afilter='') and Self.Active then
  begin
    TL2Grid.SetFocus;
  end;
  TL2Grid.TopRow:=TL2Grid.Row;

end;
{%ENDREGION Grid}

{%REGION Filter}
procedure TMainTL2TransForm.FillLangCombo();
var
  lstat:TModStatistic;
  i,lcnt:integer;
begin
  lstat.modid:=CurMod;
  lcnt:=GetModStatistic(lstat);

  cbLanguage.Clear;
  if lcnt>0 then
  begin
    cbLanguage.Sorted:=true;
    cbLanguage.Items.BeginUpdate;

    for i:=0 to lcnt-1 do
      with lstat.langs[i] do
        cbLanguage.Items.Add(lang+' '+GetLangName(lang));

    cbLanguage.Items.EndUpdate;
    cbLanguage.Text:=CurLang+' '+GetLangName(CurLang);
  end
  else
    cbLanguage.ItemIndex:=-1;
end;

procedure TMainTL2TransForm.cbLanguageChange(Sender: TObject);
var
  i:integer;
begin
  // ask for saving
  if FileSave.Enabled then
  begin
    case MessageDlg(rsNotSaved,mtWarning,mbYesNoCancel,0,mbCancel) of
      mrOk    : FileSaveExecute(self);
      mrCancel: exit;
    else
      FileSave.Enabled:=false;
      for i:=0 to High(TRCache) do
        TRCache[i].flags:=TRCache[i].flags and not rfIsModified;
    end;
  end;

  i:=TL2Grid.Row;
  CurLang:=cbLanguage.Text;
  SetLength(CurLang,Pos(' ',CurLang)-1);
  LoadTranslation();
  edProjectFilterChange(Self);
  TL2Grid.Row:=i;
end;

procedure TMainTL2TransForm.FillFoldersCombo(asetidx:boolean);
var
  ls:string;
  i,j,lcnt:integer;
  lskill,lroot,litems,lmonsters,lplayers,lprops:boolean;
  lfolders:TStringDynArray;
begin
  lroot    :=false;
  litems   :=false;
  lmonsters:=false;
  lplayers :=false;
  lprops   :=false;
  lskill   :=false;

  cbSkills.Clear;
  cbSkills.Sorted:=true;
  cbSkills.Items.BeginUpdate;
  cbSkills.Items.Add(rsFolderAll);

  cbFolder.Clear;
  cbFolder.Sorted:=true;
  cbFolder.Items.BeginUpdate;
  cbFolder.Items.Add(rsFolderAll);

  lfolders:=nil;
  lcnt:=GetModDirList(CurMod,lfolders);

  for i:=0 to lcnt-1 do
  begin
    ls:=lfolders[i];
    for j:=1 to Length(ls) do
      if ls[j]='\' then ls[j]:='/'
      else ls[j]:=UpCase(ls[j]);

    if (not lroot) and (ls='MEDIA/') then
    begin
      lroot:=true;
      cbFolder.Items.Add(rsRoot);
    end
    else if Pos('SKILLS',ls)=7 then
    begin
      if not lskill then
      begin
        lskill:=true;
        cbFolder.Items.AddObject('SKILLS',TObject(rfIsSkill));
      end;
      if Length(ls)=13 then           // if we has MEDIA/SKILLS/ files
        cbSkills.Items.Add(rsRoot)
      else                            // Add subdirs (if not added yet)
      begin
        // Use just 1-st level subdirs
        for j:=14 to Length(ls) do
        begin
          if ls[j]='/' then
          begin
            ls:=Copy(ls,14,j-14);
            break;
          end;
        end;
        j:=1;
        while j<cbSkills.Items.Count do
        begin
          if ls=cbSkills.Items[j] then break;
          inc(j);
        end;
        if j=cbSkills.Items.Count then
          cbSkills.Items.Add(ls);
      end;

    end
    else if (Pos('UNITS',ls)=7) and (Length(ls)>12) then
    begin
      // second letter of folder
      case ls[14] of
        'T': if (not litems) then
        begin
          litems:=true;
          cbFolder.Items.AddObject('ITEMS',TObject(rfIsItem));
        end;

        'O': if (not lmonsters) then
        begin
          lmonsters:=true;
          cbFolder.Items.AddObject('MONSTERS',TObject(rfIsMob));
        end;

        'L': if (not lplayers) then
        begin
          lplayers:=true;
          cbFolder.Items.AddObject('PLAYERS',TObject(rfIsPlayer));
        end;

        'R': if (not lprops) then
        begin
          lprops:=true;
          cbFolder.Items.AddObject('PROPS',TObject(rfIsProp));
        end;
      end;
    end
    else
    begin
      j:=7;
      while j<=Length(ls) do
      begin
        if ls[j]='/' then
        begin
          ls:=Copy(ls,7,j-7);
          cbFolder.Items.Add(ls);
          break;
        end;
        inc(j);
      end;
    end;
  end;
  SetLength(lfolders,0);

  cbSkills.Items.EndUpdate;
  cbSkills.ItemIndex:=0;

  cbFolder.Items.EndUpdate;
  if asetidx then
  begin
    cbFolder.ItemIndex:=0;
    cbFolderChange(Self);
  end;
end;

procedure TMainTL2TransForm.cbFolderChange(Sender: TObject);
var
  lfolder:string;
  i,lflag:integer;
begin
  if cbFolder.ItemIndex<0 then
     cbFolder.ItemIndex:=0;

  if cbFolder.ItemIndex=0 then
  begin
    for i:=0 to High(TRCache) do
      TRCache[i].flags:=TRCache[i].flags or rfIsFiltered;
  end
  else
  begin
    if (cbFolder.ItemIndex=1) and (cbFolder.Items[1][1]='-') then
      lfolder:=''
    else
    begin
      lfolder:=cbFolder.Items[cbFolder.ItemIndex];

      if lfolder='SKILLS' then
      begin
        pnlSkills.Visible:=true;
        splSkills.Visible:=true;

        cbSkillsChange(Sender);
        exit;
      end;
    end;

    lflag:=IntPtr(cbFolder.Items.Objects[cbFolder.ItemIndex]);
    if (lflag<>0) then
    begin
      for i:=0 to High(TRCache) do
        if ((TRCache[i].flags and rfIsReferred) =0) or
           ((TRCache[i].flags and lflag       )<>0) then
          TRCache[i].flags:=TRCache[i].flags or rfIsFiltered
        else
          TRCache[i].flags:=TRCache[i].flags and not rfIsFiltered;
    end
    else
      CheckForDirectory('MEDIA/'+lfolder);

  end;

  pnlSkills.Visible:=false;
  splSkills.Visible:=false;

  edProjectFilterChange(Sender);
end;

procedure TMainTL2TransForm.cbSkillsChange(Sender: TObject);
var
  i:integer;
begin
  if cbSkills.ItemIndex<0 then
     cbSkills.ItemIndex:=0;

  if cbSkills.ItemIndex=0 then
  begin
    for i:=0 to High(TRCache) do
      if ((TRCache[i].flags and rfIsReferred) =0) or
         ((TRCache[i].flags and rfIsSkill   )<>0) then
        TRCache[i].flags:=TRCache[i].flags or rfIsFiltered
      else
        TRCache[i].flags:=TRCache[i].flags and not rfIsFiltered;
  end
  else if (cbSkills.ItemIndex=1) and (cbSkills.Items[1][1]='-') then
    CheckForDirectory('MEDIA/SKILLS/')
  else// if cbSkills.ItemIndex<>0 then
    CheckForDirectory('MEDIA/SKILLS/'+cbSkills.Items[cbSkills.ItemIndex]+'/');

  edProjectFilterChange(Sender);
end;

procedure TMainTL2TransForm.edProjectFilterChange(Sender: TObject);
var
  ls:AnsiString;
begin
  if Length(edProjectFilter.Text)<4 then
    ls:=''
  else
    ls:=AnsiLowerCase(edProjectFilter.Text);

  // crazy logic
  if actFilter.Checked then
  begin
    if ls='' then
    begin
      if TL2Grid.RowCount<>(Length(TRCache)+1) then
        FillProjectGrid('')
      else if (Sender=cbDisplayMode) then
        FillProjectGrid('')
      else
        exit;
    end
    else
    begin
      FillProjectGrid(ls)
    end
  end
  else
  begin
    if Sender<>edProjectFilter then
      FillProjectGrid('');
    if ls<>'' then
      Search(ls,TL2Grid.Row);
  end;
end;
{%ENDREGION Filter}

procedure TMainTL2TransForm.actExportClipBrdExecute(Sender: TObject);
var
  sl:TStringList;
  ls:string;
  i:integer;
  lshift:boolean;
begin
  lshift:=GetKeyState(VK_SHIFT)<0;
  sl:=TStringList.Create;
  try
    for i:=1 to TL2Grid.RowCount-1 do
    begin
      if TL2Grid.IsCellSelected[TL2Grid.Col,i] then
      begin
        ls:=TL2Grid.Cells[TL2Grid.Col,i];
        if lshift then
          sl.Add(RemoveTags(ls))
        else
          sl.Add(ls);
      end;
    end;

    Clipboard.asText:=sl.Text;

  finally
    sl.Free;
  end;
end;
// any place, format is "source#9translation"
procedure TMainTL2TransForm.actImportClipBrdExecute(Sender: TObject);
var
  s,lsrc,ltrans:AnsiString;
  sl:TStringList;
  p,lline:integer;
  lcnt:integer;
begin
  sl:=TStringList.Create;
  try
    sl.Text:=Clipboard.asText;

    lcnt:=0;

    for lline:=0 to sl.Count-1 do
    begin
      s:=sl[lline];
      // Split to parts
      p:=Pos(#9,s);
      if p>0 then
      begin
        lsrc:=Copy(s,1,p-1);
        ltrans:=Copy(s,p+1);
//        if data.CheckLine(lsrc,ltrans)>0 then
          inc(lcnt);
      end
    end;

    ShowMessage(rsReplaces+' = '+IntToStr(lcnt));
    if lcnt>0 then
    begin
      UpdateStatusBar(Self);
      FillProjectGrid('');
    end;
  finally
    sl.Free;
  end;
end;

procedure TMainTL2TransForm.SetCellText(arow:integer; const atext:AnsiString);
var
  lidx:integer;
begin
  if atext='' then exit;

  lidx:=IntPtr(TL2Grid.Objects[0,arow]);
  if atext=TRCache[lidx].src then exit; // or treat as ''

  TRCache[lidx].dst  :=atext;
  TRCache[lidx].part :=TL2Settings.cbAsPartial.Checked{ and (atext<>'')};
  TRCache[lidx].flags:=TRCache[lidx].flags or rfIsModified;
  FileSave.Enabled:=true;
  TL2Grid.Cells[colTrans  ,arow]:=atext;
  TL2Grid.Cells[colPartial,arow]:=BoolNumber[TL2Settings.cbAsPartial.Checked];
end;

//at current place or fill selected, pure translation
procedure TMainTL2TransForm.PasteFromClipBrd();
var
  sl:TStringList;
  ls:AnsiString;
  i,j,lcnt:integer;
begin
  ls:=Clipboard.asText;
  if ls='' then exit;

  i:=Length(ls);
  while (i>0) and (ls[i] in [#10,#13]) do dec(i);
  if i=0 then exit;
  if i<Length(ls) then SetLength(ls,i);

  sl:=TStringList.Create;
  try
    sl.Text:=ls;
    lcnt:=sl.Count;
    // duplicate single translation on all selected cells
    if lcnt=1 then
    begin
      for i:=1 to TL2Grid.RowCount-1 do
      begin
        if TL2Grid.IsCellSelected[colTrans,i] then
        begin
          SetCellText(i,ls);
        end;
      end;
    end
    // fill one by one from current
    else if lcnt>1 then
    begin
      i:=TL2Grid.Row;
      for j:=0 to lcnt-1 do
      begin
        SetCellText(i,sl[j]);
        inc(i);
        if i=TL2Grid.RowCount then break;
      end;
    end;
  finally
    sl.Free;
  end;
  if lcnt>0 then
  begin
    UpdateStatusBar(Self);
  end;
end;

end.
