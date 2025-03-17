unit tl2projectform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs,
  Grids, ExtCtrls, StdCtrls, Buttons, ComCtrls, ActnList, Menus,
  TL2DataUnit, Types;

type
  TSBUpdateEvent = Procedure(Sender:TObject; const SBText:AnsiString='') of Object;

type

  { TTL2Project }

  TTL2Project = class(TForm)
    alProject: TActionList;
    actHideReady    : TAction;
    actExportFile   : TAction;
    actExportClipBrd: TAction;
    actImportFile   : TAction;
    actImportClipBrd: TAction;
    actCheckTranslation: TAction;
    actStopScan     : TAction;
    actOpenSource   : TAction;
    actPartAsReady  : TAction;
    actTranslate    : TAction;
    actReplace      : TAction;
    actFindNext     : TAction;
    actShowSimilar  : TAction;
    actShowDoubles  : TAction;
    actFilter       : TAction;
    cbSkills: TComboBox;
    memEdit: TMemo;
    pnlSkills: TPanel;
    pnlTop     : TPanel;
    pnlFolders : TPanel;
    cbFolder   : TComboBox;
    splSkills: TSplitter;
    splFolder: TSplitter;
    TL2ProjectFilterPanel: TPanel;
    edProjectFilter: TEdit;
    sbHideReady    : TSpeedButton;
    sbProjectFilter: TSpeedButton;
    sbExportClipBrd: TSpeedButton;
    sbExportFile   : TSpeedButton;
    sbImportClipBrd: TSpeedButton;
    sbImportFile   : TSpeedButton;
    sbShowSimilar  : TSpeedButton;
    sbShowDoubles  : TSpeedButton;
    sbReplace      : TSpeedButton;
    sbTranslate    : TSpeedButton;
    sbFindNext     : TSpeedButton;
    cbPartAsReady  : TSpeedButton;
    sbCheck        : TSpeedButton;
    TL2Grid: TStringGrid;
    procedure actCheckTranslationExecute(Sender: TObject);
    procedure actHideReadyExecute(Sender: TObject);
    procedure actOpenSourceExecute(Sender: TObject);
    procedure actPartAsReadyExecute(Sender: TObject);
    procedure actStopScanExecute(Sender: TObject);
    procedure cbFolderChange(Sender: TObject);
    procedure cbSkillsChange(Sender: TObject);
    procedure edProjectFilterChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure memEditExit(Sender: TObject);
    procedure memEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ShowDoublesClick(Sender: TObject);
    procedure ShowSimilarClick(Sender: TObject);
    procedure ImportFileClick(Sender: TObject);
    procedure ImportClipBrdClick(Sender: TObject);
    procedure ExportClipBrdClick(Sender: TObject);
    procedure ExportFileClick(Sender: TObject);
    procedure TL2GridClick(Sender: TObject);
    procedure TL2GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure TranslateClick(Sender: TObject);
    procedure ReplaceClick(Sender: TObject);
    procedure dlgOnReplace(Sender: TObject);
    procedure FindNextClick(Sender: TObject);
    procedure TL2GridHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure TL2GridDblClick(Sender: TObject);
    procedure TL2GridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; astate: TGridDrawState);
    procedure TL2GridGetEditText(Sender: TObject; aCol, aRow: Integer; var Value: string);
    procedure TL2GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TL2GridSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure TL2GridSetCheckboxState(Sender: TObject; aCol,
      aRow: Integer; const Value: TCheckboxState);
  private
    doStopScan:boolean;
    FSBUpdate:TSBUpdateEvent;
    FFolderFilter: String;

    function DoImport(const srcname: AnsiString; var adata: TTL2Translation): integer;
    procedure FillFoldersCombo(asetidx: boolean);
    function  MakeNew(const adir:AnsiString; aFile:boolean; allText:boolean; withChild:boolean): boolean;
    function  ProjectFileScan(const fname:AnsiString; idx, atotal:integer):integer;
    procedure PasteFromClipBrd();
    procedure FillProjectGrid(const afilter: AnsiString);
    function  FillProjectSGRow(aRow, idx: integer; const afilter: AnsiString): boolean;
    procedure ShowStatistic();
    procedure ReBoundEditor;
    procedure Search(const atext: AnsiString; aRow: integer);
    procedure SetCellText(arow: integer; const atext: AnsiString);

  public
    FileName,
    ProjectName: AnsiString;
    Modified: Boolean;
    data:TTL2Translation;

    function NewFromFile(const adir: AnsiString): boolean;
    function NewFromDir (const adir:AnsiString; allText:boolean; withChild:boolean):boolean;
    function Load(const fname:AnsiString; silent:boolean=false):boolean;
    procedure Save();
    procedure Build();
    procedure MoveToIndex(idx: integer);
    procedure UpdateGrid(idx: integer);

    property OnSBUpdate:TSBUpdateEvent read FSBUpdate write FSBUpdate;
  end;


implementation

{$R *.lfm}

uses
  Graphics,
  rgglobal,
  TL2DataModule,
  TL2SettingsForm,
  TL2EditText,
  TL2SimForm,
  TL2DupeForm,
  TL2Text,
  LCLType,
  LazUtf8,
  lclintf,
  ClipBrd;

resourcestring
  sFolderAll      = '- All -';    // minus+space to be first
  sRoot           = '-- Root --'; // minus+minus+space to be second
  sWarning        = 'Warning';
//  sBuildRead      = 'Build translation. Read';
//  sBuildWrite     = 'Build translation in file.';
  sReplaces       = 'Total replaces';
  sTransFileError = 'Error %d in translation file %s, line %d:'#13#10'%s';

  rsProjectStat   = 'Project statistic';
  rsSBText        = 'Project files: %d; tags: %d; lines: %d | ' +
                    'Translated: %d; partially: %d | Doubles: %d';
  rsStatText      = 'Project files: %d'#13#10' tags: %d'#13#10' lines: %d'#13#10 +
                    'Translated: %d'#13#10' partially: %d'#13#10'Doubles: %d';
  rsStatTextNoRef = 'Lines: %d'#13#10'Translated: %d'#13#10'Partially: %d';

  sImporting      = 'Importing';
  sCheckLine      = 'Check importing translations';
  sDoDelete       = 'Are you sure to delete selected line(s)?'#13#10+
                    'This text will be just hidden until you save and reload project.';
  sStopScan       = 'Do you want to break scan? It clear full scan process.';
  sEscCancel      = 'ESC to cancel';
  sAffected       = ' line(s) affected';
  sNoDoubles      = 'No doubles for this text';
  sDupes          = 'Check doubles info.';

  rsNoWarnings    = 'No any warnings';
  rsNotes         = 'Punctuation note';
  rsNext          = 'Next note';
  rsFixOne        = 'Fix this';
  rsFixAll        = 'Fix all';

const
  colOrigin  = 1;
  colPartial = 2;
  colTrans   = 3;

//----- Other -----

function TTL2Project.ProjectFileScan(const fname:AnsiString; idx, atotal:integer):integer;
begin
  if doStopScan then
    result:=2
  else
    result:=0;
  if atotal=0 then
    OnSBUpdate(Self,'('+sEscCancel+') ['+IntToStr(idx)+'] '+fname)
  else
    OnSBUpdate(Self,'('+sEscCancel+') ['+IntToStr(idx)+' / '+IntToStr(atotal)+'] '+fname);
end;

procedure TTL2Project.actStopScanExecute(Sender: TObject);
begin
  if actStopScan.Enabled then
    doStopScan:=MessageDlg(sStopScan,mtWarning,mbYesNo,0,mbNo)=mrYes;
end;

procedure TTL2Project.ShowStatistic();
var
  ltyp:tTextStatus;
  i,lpart,lready:integer;
begin
  lpart :=0;
  lready:=0;
  for i:=0 to data.LineCount-1 do
  begin
    ltyp:=data.State[i];
    if      (ltyp=stPartial) then inc(lpart)
    else if (ltyp=stReady  ) then inc(lready);
  end;

  if data.Refs.RefCount=0 then
    MessageDlg(rsProjectStat,Format(rsStatTextNoRef,
      [data.LineCount,lready,lpart]),mtInformation,[mbOk],'')
  else
    MessageDlg(rsProjectStat,Format(rsStatText,
      [data.refs.FileCount,data.refs.TagCount,
       data.LineCount,lready,lpart,
       data.Refs.RefCount-data.LineCount]),mtInformation,[mbOk],'');
end;

procedure TTL2Project.Search(const atext:AnsiString; aRow:integer);
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

procedure TTL2Project.actCheckTranslationExecute(Sender: TObject);
var
  idx,lcnt:integer;
  lres:dword;
  lask:boolean;
begin
  lask:=true;
  lcnt:=0;

  idx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
  lres:=data.NextNoticed(true,idx);
  if idx<0 then
  begin
    idx:=-1;
    lres:=data.NextNoticed(true,idx);
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
      data.NextNoticed(false,idx); // yes, yes, check it again but with fix at same time
      inc(lcnt);
      if TL2Settings.cbAutoAsPartial.Checked then
        data.State[idx]:=stPartial;
      UpdateGrid(idx);
    end;

    lres:=data.NextNoticed(true,idx);
  end;

  if lcnt>0 then
  begin
    Modified:=true;
    OnSBUpdate(Self);
    ShowMessage(IntToStr(lcnt)+sAffected);
  end
  else
    ShowMessage(rsNoWarnings);
end;

procedure TTL2Project.actHideReadyExecute(Sender: TObject);
begin
  edProjectFilterChange(Sender);
end;

//----- Visual -----

procedure TTL2Project.TL2GridClick(Sender: TObject);
var
  ls:AnsiString;
  lcnt,idx:integer;
begin
  idx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
  lcnt:=data.RefCount[idx];
  if lcnt=1 then
  begin
    idx:=data.Ref[idx,0];
    ls:=data.Refs.GetTag(idx)+' | '+data.Refs.GetFile(idx);
  end
  else if lcnt=0 then
    ls:=rsNoRef
  else
    ls:=StringReplace(rsSeveralRefs,'%d',IntToStr(lcnt),[])+' '+sDupes;
  OnSBUpdate(Self,ls);
end;

procedure TTL2Project.TL2GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if (aRow>0) then TL2GridClick(self);
end;

procedure TTL2Project.TL2GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
        if data.State[idx]=stPartial then
        begin
          if data.Trans[idx]='' then
            data.State[idx]:=stOriginal
          else
            data.State[idx]:=stReady;
          TL2Grid.Cells[colPartial,i]:='0';
        end
        else
        begin
          data.State[idx]:=stPartial;
          TL2Grid.Cells[colPartial,i]:='1';
        end;
      end;
    end;
    Modified:=true;
    OnSBUpdate(Self);
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
        if data.Trans[idx]<>'' then
          ls:=data.Trans[idx]
        else
          ls:=data.Line[idx];
        if RemoveColor(ls,ls) then
        begin
          data.Trans[idx]:=ls;
          data.State[idx]:=stPartial;
          TL2Grid.Cells[colPartial,i]:='1';
          TL2Grid.Cells[colTrans  ,i]:=ls;
          Modified:=true;
          OnSBUpdate(Self);
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
              data.Trans[idx]:='';
              data.State[idx]:=stOriginal;
              TL2Grid.Cells[colPartial,i]:='0';
              TL2Grid.Cells[colTrans  ,i]:='';
              Modified:=true;
            end;
          end;
        end;
        OnSBUpdate(Self);
      end;
    end
    else
    begin
      // mark lines as deleted
      if MessageDlg(sDoDelete,mtConfirmation,mbOkCancel,0)=mrOk then
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
            data.State[idx]:=stDeleted;
            TL2Grid.DeleteRow(i);
          end;
        end;

        Modified:=true;
        OnSBUpdate(Self);
      end;
    end;
    Key:=0;
  end;

  if (Key=VK_RETURN) and (Shift=[ssCtrl]) then
  begin
    actOpenSourceExecute(Sender);
    Key:=0;
  end;

  if (Key=VK_RETURN) and
     (TL2Grid.Col=colTrans) then
    TL2Grid.EditorMode:=true;

  if (Shift=[ssCtrl,ssShift]) and (Key=VK_C) then
  begin
    ExportClipBrdClick(self);
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
        ExportClipBrdClick(self);
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

procedure TTL2Project.memEditExit(Sender: TObject);
var
  lr,lidx:integer;
begin
  memEdit.Visible:=false;
  lr:=TL2Grid.Row;
  lidx:=IntPtr(TL2Grid.Objects[0,lr]);
  if (memEdit.Tag=0) and (data.Trans[lIdx]<>memEdit.Text) then
  begin
    data.Trans[lidx]:=memEdit.Text;
    TL2Grid.Cells[colTrans{TL2Grid.Col},lr]:=memEdit.Text;
    if memEdit.Text='' then
    begin
      data.State[lidx]:=stOriginal;
      TL2Grid.Cells[colPartial,lr]:='0';
    end
    else
    begin
      if TL2Grid.Cells[colPartial,lr]='1' then
        data.State[lidx]:=stPartial
      else
        data.State[lidx]:=stReady;

      data.CheckTheSame(lidx,TL2Settings.cbAutoAsPartial.Checked);

      TL2Grid.Row:=lr;
      TL2Grid.Col:=colTrans;
    end;
    Modified:=true;
    OnSBUpdate(Self);
  end;
  // when we close/change tab with active editor
  if Parent.Visible then
    TL2Grid.SetFocus;
end;

procedure TTL2Project.memEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
    ls:=data.Line[IntPtr(TL2Grid.Objects[0,TL2Grid.Row])];
    if FillColorPopup(memEdit,ls) then
    begin
      Key:=0;
    end;
  end;

  if (Key=VK_V) and (Shift=[ssAlt]) then
  begin
    ls:=data.Line[IntPtr(TL2Grid.Objects[0,TL2Grid.Row])];
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

procedure TTL2Project.ReBoundEditor;
var
  r:TRect;
begin
  // aCol must be 5
  r:=TL2Grid.CellRect(colTrans,TL2Grid.Row);
  InflateRect(r,-1,-1);
  memEdit.Tag:=0;
  memEdit.BoundsRect:=r;
end;

procedure TTL2Project.TL2GridHeaderSized(Sender: TObject;
  IsColumn: Boolean; Index: Integer);
begin
  if IsColumn then
    ReBoundEditor;
end;

procedure TTL2Project.TL2GridSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  ReBoundEditor;
  Editor:=memEdit;
end;

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

procedure TTL2Project.TL2GridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; astate: TGridDrawState);
var
  ls:String;
  ts:TTextStyle;
  count1, count2: integer;
  lidx:integer;
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

        lidx:=IntPtr(Objects[0,aRow]);

        count1:=GetTextLines(data.Line [lidx],Canvas,CellRect(colOrigin,aRow));
        count2:=GetTextLines(data.Trans[lidx],Canvas,CellRect(colTrans ,aRow));
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
        if (ACol=colOrigin) and (ls[Length(ls)]=' ') then
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

procedure TTL2Project.TL2GridGetEditText(Sender: TObject; aCol,aRow: Integer; var Value: string);
begin
  memEdit.Text:=Value;
end;

procedure TTL2Project.MoveToIndex(idx:integer);
var
  lrow,i:integer;
begin
  lrow:=TL2Grid.Row;
  if (lrow<(TL2Grid.RowCount-1)) and (idx=IntPtr(TL2Grid.Objects[0,lrow+1])) then TL2Grid.Row:=lrow+1
  else if (lrow>1)               and (idx=IntPtr(TL2Grid.Objects[0,lrow-1])) then TL2Grid.Row:=lrow-1
  else if (idx<>IntPtr(TL2Grid.Objects[0,lrow])) then
    for i:=1 to TL2Grid.RowCount-1 do
    begin
      if idx=IntPtr(TL2Grid.Objects[0,i]) then
      begin
        TL2Grid.Row   :=i;
        TL2Grid.TopRow:=i;
        exit;
      end;
    end;
end;

procedure TTL2Project.UpdateGrid(idx:integer);
var
  lrow,i:integer;
begin
  lrow:=TL2Grid.Row;
  if (lrow<(TL2Grid.RowCount-1)) and (idx=IntPtr(TL2Grid.Objects[0,lrow+1])) then inc(lrow)
  else if (lrow>1)               and (idx=IntPtr(TL2Grid.Objects[0,lrow-1])) then dec(lrow)
  else if (idx<>IntPtr(TL2Grid.Objects[0,lrow])) then
  begin
    lrow:=0;
    for i:=1 to TL2Grid.RowCount-1 do
    begin
      if idx=IntPtr(TL2Grid.Objects[0,i]) then
      begin
        lrow:=i;
        break;
      end;
    end;
  end;

  if lrow<>0 then
  begin
    TL2Grid.Cells[colTrans,lrow]:=data.Trans[idx];
    if data.State[idx]=stPartial then
      TL2Grid.Cells[colPartial,lrow]:='1'
    else
      TL2Grid.Cells[colPartial,lrow]:='0';

    TL2Grid.Row   :=lrow;
    TL2Grid.TopRow:=lrow;
  end;
end;

//----- Load -----

function TTL2Project.MakeNew(const adir:AnsiString; aFile:boolean;
    allText:boolean; withChild:boolean):boolean;
var
  ls:string;
begin
  data.Filter:=flFiltered;
  actStopScan.Enabled:=true;
  doStopScan:=false;
  if aFile then
    result:=data.Scan(adir)
  else
    result:=data.Scan(adir,allText,withChild);

  actStopScan.Enabled:=false;
  if result then
  begin
    if (BaseTranslation.LineCount=0)
//  right now we don't save default file name
//    or (BaseTranslation.Refs.Root<>TL2Settings.edDefaultFile.Text)
    then
      with TL2Settings do
      begin
        ls:=edDefaultFile.Text;
        edDefaultFileAcceptFileName(Self, ls);
      end;

    DoImport(TL2Settings.edDefaultFile.Text,BaseTranslation);

    Modified:=true;
//    OnSBUpdate(Self);
    pnlFolders.Visible:=true;
    FillFoldersCombo(true); // calls   FillProjectGrid('') through changes
//    FillProjectGrid('');
    ShowStatistic();
  end;
end;

function TTL2Project.NewFromDir(const adir:AnsiString; allText:boolean; withChild:boolean):boolean;
begin
  result:=MakeNew(adir,false,allText,withChild);
end;

function TTL2Project.NewFromFile(const adir:AnsiString):boolean;
begin
  result:=MakeNew(adir,true,false,false);
end;

{%REGION Folders combo}
procedure TTL2Project.FillFoldersCombo(asetidx:boolean);
var
  ls:string;
  i,j:integer;
  lskill,lroot,litems,lmonsters,lplayers,lprops:boolean;
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
  cbSkills.Items.Add(sFolderAll);

  cbFolder.Clear;
  cbFolder.Sorted:=true;
  cbFolder.Items.BeginUpdate;
  cbFolder.Items.Add(sFolderAll);
  for i:=0 to data.Refs.DirCount-1 do
  begin
    ls:=data.Refs.Dirs[i];
    for j:=1 to Length(ls) do
      if ls[j]='\' then ls[j]:='/'
      else ls[j]:=UpCase(ls[j]);

    if (not lroot) and (ls='MEDIA/') then
    begin
      lroot:=true;
      cbFolder.Items.Add(sRoot);
    end
    else if Pos('SKILLS',ls)=7 then
    begin
      if not lskill then
      begin
        lskill:=true;
        cbFolder.Items.Add('SKILLS');
      end;
      if Length(ls)=13 then           // if we has MEDIA/SKILLS/ files
        cbSkills.Items.Add(sRoot)
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
    else if (Pos('UNITS',ls)=7) then
    begin
      // second letter of folder
      case ls[14] of
        'T': if (not litems) then
        begin
          litems:=true;
          cbFolder.Items.Add('ITEMS');
        end;

        'O': if (not lmonsters) then
        begin
          lmonsters:=true;
          cbFolder.Items.Add('MONSTERS');
        end;

        'L': if (not lplayers) then
        begin
          lplayers:=true;
          cbFolder.Items.Add('PLAYERS');
        end;

        'R': if (not lprops) then
        begin
          lprops:=true;
          cbFolder.Items.Add('PROPS');
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

          j:=1;
          while j<cbFolder.Items.Count do
          begin
            if ls=cbFolder.Items[j] then break;
            inc(j);
          end;
          if j=cbFolder.Items.Count then
            cbFolder.Items.Add(ls);
          break;
        end;
        inc(j);
      end;
    end;
  end;

  cbSkills.Items.EndUpdate;
  cbSkills.ItemIndex:=0;

  cbFolder.Items.EndUpdate;
  if asetidx then
  begin
    cbFolder.ItemIndex:=0;
    cbFolderChange(Self);
  end;
end;

procedure TTL2Project.cbFolderChange(Sender: TObject);
begin
  if cbFolder.ItemIndex<0 then
     cbFolder.ItemIndex:=0;

  if cbFolder.ItemIndex=0 then
    FFolderFilter:=''
  else if (cbFolder.ItemIndex=1) and (cbFolder.Items[1][1]='-') then
    FFolderFilter:='\'
  else
    FFolderFilter:=cbFolder.Items[cbFolder.ItemIndex];

  if FFolderFilter='SKILLS' then
  begin
    pnlSkills.Visible:=true;
    splSkills.Visible:=true;

    cbSkillsChange(Sender);
  end
  else
  begin
    pnlSkills.Visible:=false;
    splSkills.Visible:=false;
  end;
  edProjectFilterChange(Sender);
end;

procedure TTL2Project.cbSkillsChange(Sender: TObject);
begin
  if cbSkills.ItemIndex<0 then
     cbSkills.ItemIndex:=0;

  if cbSkills.ItemIndex=0 then
    FFolderFilter:='SKILLS'
  else if (cbSkills.ItemIndex=1) and (cbSkills.Items[1][1]='-') then
    FFolderFilter:='SKILLS\'
  else
    FFolderFilter:='SKILLS\'+cbSkills.Items[cbSkills.ItemIndex]+'\';

  edProjectFilterChange(Sender);
end;
{%ENDREGION Folders combo}

function TTL2Project.Load(const fname:AnsiString; silent:boolean=false):boolean;
var
  ls:AnsiString;
begin
  result:=false;
  data.Filter:=flFiltered;
  data.Mode  :=tmOriginal;
  if data.LoadFromFile(fname)<0 then
  begin
    if not silent then
      MessageDlg(sWarning,
        Format(sTransFileError,
               [data.ErrorCode,data.ErrorFile,data.ErrorLine,data.ErrorText]),
               mtError,[mbOk],0);
    exit;
  end;
  result:=true;
  FileName:=fname;

//  OnSBUpdate(Self);

  if data.refs.RefCount=0 then
  begin
    pnlFolders.Visible:=false;
    FillProjectGrid('');
  end
  else
  begin
    pnlFolders.Visible:=true;
    FillFoldersCombo(true); // calls   FillProjectGrid('') through changes

    if data.Refs.RootCount=0 then
    begin
      ls:=TL2Settings.edRootDir.Text;
      if ls='' then
        ls:=ExtractFileDir(ParamStr(0));
      if not (ls[Length(ls)] in ['\','/']) then
        ls:=ls+'\';
      ls:=ls+ProjectName+'/';
      data.Refs.AddRoot(ls);
    end;
  end;

  if not silent then
    ShowStatistic();
end;

procedure TTL2Project.Save();
begin
  data.Mode:=tmOriginal;
  data.SaveToFile(FileName,stPartial);
  Modified:=false;
  OnSBUpdate(Self); // for Modified only
end;

//----- Edit -----

procedure TTL2Project.TL2GridSetCheckboxState(Sender: TObject;
  aCol, aRow: Integer; const Value: TCheckboxState);
var
  lidx:integer;
begin
  lidx:=IntPtr(TL2Grid.Objects[0,aRow]);
  if Value=cbChecked then
  begin
    TL2Grid.Cells[colPartial,aRow]:='1';
    data.State[lidx]:=stPartial;
  end
  else
  begin
    TL2Grid.Cells[colPartial,aRow]:='0';
    if data.Trans[lidx]<>'' then
      data.State[lidx]:=stReady
    else
      data.State[lidx]:=stOriginal;
  end;
  Modified:=true;
  OnSBUpdate(Self);
end;

procedure TTL2Project.TL2GridDblClick(Sender: TObject);
//var  lrow:integer;
var
  i:integer;
begin
  with TEditTextForm.Create(Self) do
  begin
    i:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
    SelectLine(i);
    if ShowModal=mrOk then
    begin
      data.CheckTheSame(i,TL2Settings.cbAutoAsPartial.Checked);

      Modified:=true;
      OnSBUpdate(Self);
{
      lrow:=TL2Grid.Row;
      FillProjectGrid('');
      TL2Grid.Row:=lrow;
}
    end;
    Free;
  end;
end;

procedure TTL2Project.actOpenSourceExecute(Sender: TObject);
begin
  CreateFileTab(data,data.Ref[IntPtr(TL2Grid.Objects[0,TL2Grid.Row])],nil);
end;

//----- Buttons ans Editfield -----

procedure TTL2Project.edProjectFilterChange(Sender: TObject);
var
  ls:AnsiString;
  llines:integer;
begin
  llines:=data.LineCount;

  if Length(edProjectFilter.Text)<4 then
    ls:=''
  else
    ls:=AnsiLowerCase(edProjectFilter.Text);

  // crazy logic
  if actFilter.Checked then
  begin
    if ls='' then
    begin
      if TL2Grid.RowCount<>(llines+1) then
        FillProjectGrid('')
      else if (Sender=actHideReady) then
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

procedure TTL2Project.FindNextClick(Sender: TObject);
begin
  Search(edProjectFilter.Text,TL2Grid.Row+1);
end;

procedure TTL2Project.actPartAsReadyExecute(Sender: TObject);
var
  i,idx:integer;
begin
  for i:=1 to TL2Grid.RowCount-1 do
  begin
    idx:=IntPtr(TL2Grid.Objects[0,i]);
    if data.State[idx]=stPartial then
    begin
      data.State[idx]:=stReady;
      TL2Grid.Cells[colPartial,i]:='0';
    end;
  end;
end;

procedure TTL2Project.TranslateClick(Sender: TObject);
var
  ls:AnsiString;
  idx:integer;
begin
  idx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);

  if memEdit.Visible and (memEdit.Text<>'') then
  begin
    if memEdit.SelLength>0 then
    begin
      memEdit.SelText:=Translate(memEdit.SelText);
      ls:=memEdit.Text;
{
      ls:=memEdit.Text;
      UTF8Delete(ls,memEdit.SelStart+1,memEdit.SelLength);
      UTF8Insert(Translate(memEdit.SelText),ls,memEdit.SelStart+1);
      memEdit.Text:=ls;
}
    end
    else
      ls:=Translate(memEdit.Text);
  end
  else
  begin
    ls:=Translate(data.Line[idx]);
  end;

  data.Trans[idx]:=ls;//Translate(data.Line[idx]);
  data.State[idx]:=stPartial;
  UpdateGrid(idx);

  Modified:=true;
  OnSBUpdate(Self);
end;

procedure TTL2Project.dlgOnReplace(Sender: TObject);
var
  ls,lsrc,lr:AnsiString;
  idx,lcnt,i,p:integer;
begin
  lcnt:=0;
  lsrc:=(Sender as TReplaceDialog).FindText;
  lr  :=(Sender as TReplaceDialog).ReplaceText;
  for i:=TL2Grid.Row to TL2Grid.RowCount-1 do
  begin
    idx:=IntPtr(TL2Grid.Objects[0,i]);
    ls:=data.Trans[idx];//TL2Grid.Cells[colTrans,i];
    p:=Pos((Sender as TReplaceDialog).FindText,ls);
    if p>0 then
    begin
      inc(lcnt);
      ls:=StringReplace(ls,lsrc,lr,[rfReplaceAll]);
      data.Trans[idx]:=ls;
      TL2Grid.Cells[colTrans,i]:=ls;
    end;
  end;
  ShowMessage(sReplaces+' = '+IntToStr(lcnt));
end;

procedure TTL2Project.ReplaceClick(Sender: TObject);
var
  dlg:TReplaceDialog;
begin
  dlg:=TReplaceDialog.Create(Self);
  dlg.Options:=[frHideMatchCase,frHideWholeWord,frHideUpDown,frHideEntireScope,frHidePromptOnReplace];
  dlg.OnReplace:=@dlgOnReplace;
  dlg.Execute;
//  dlg.Free;
end;

procedure TTL2Project.ShowSimilarClick(Sender: TObject);
var
  lline:integer;
begin
  lline:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
  with TSimilarForm.Create(Self,data,lline) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TTL2Project.ShowDoublesClick(Sender: TObject);
var
  lline:integer;
begin
  lline:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
  if data.RefCount[lline]=1 then
    ShowMessage(sNoDoubles)
  else
    with TDupeForm.Create(Self,data,lline) do
    begin
      ShowModal;
      Free;
    end;
end;

//----- Export - import -----

procedure TTL2Project.ExportFileClick(Sender: TObject);
var
  sl:TStringList;
  SaveDialog: TSaveDialog;
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

    SaveDialog:=TSaveDialog.Create(nil);
    try
      SaveDialog.InitialDir:=TL2Settings.edWorkDir.Text;
      SaveDialog.FileName  :=Self.Name+'.txt';
      SaveDialog.DefaultExt:='.txt';
      SaveDialog.Filter    :='';
      SaveDialog.Title     :='';
      SaveDialog.Options   :=SaveDialog.Options+[ofOverwritePrompt,ofNoChangeDir];

      if (SaveDialog.Execute) then
        sl.SaveToFile(SaveDialog.Filename);
    finally
      SaveDialog.Free;
    end;

  finally
    sl.Free;
  end;
end;

function TTL2Project.DoImport(const srcname:AnsiString; var adata:TTL2Translation):integer;
var
  ls,lls:AnsiString;
  i:integer;
begin
  result:=0;

  if adata.LineCount>100 then
  begin
    ls:=' / '+IntToStr(adata.LineCount);
    lls:=sImporting+' '+srcname+' - '+sCheckLine+' ';
  end;

  for i:=0 to adata.LineCount-1 do
  begin
    if (i>0) and ((i mod 100)=0) then
      OnSBUpdate(Self,lls+IntToStr(i)+ls);

    if data.CheckLine(
       adata.Line[i],
       adata.Trans[i],
       adata.template[i],
       adata.State[i])>0 then
    begin
      inc(result);
    end;
  end;
end;

procedure TTL2Project.ImportFileClick(Sender: TObject);
var
  ldata:TTL2Translation;
  OpenDialog: TOpenDialog;
  lcnt,fcnt:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.InitialDir:=TL2Settings.edWorkDir.Text;
    OpenDialog.DefaultExt:=DefaultExt;
    OpenDialog.Filter    :=DefaultFilter;
    OpenDialog.Options   :=[ofAllowMultiSelect];
    if OpenDialog.Execute then
    begin
      ldata.Init;
      ldata.Filter:=flNoSearch;
      ldata.Mode  :=tmOriginal;
      lcnt:=0;
      for fcnt:=0 to OpenDialog.Files.Count-1 do
      begin
        if ldata.LoadFromFile(OpenDialog.Files[fcnt])>0 then
        begin
          OnSBUpdate(Self,sImporting+' '+OpenDialog.Files[fcnt]+' - '+sCheckLine);
          inc(lcnt,DoImport(OpenDialog.Files[fcnt],ldata));
        end;
      end;

      if lcnt>0 then
      begin
        Modified:=true;
        FillProjectGrid('');
      end;
      OnSBUpdate(Self);
      ldata.Free;
      ShowMessage(sReplaces+' = '+IntToStr(lcnt));
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TTL2Project.ExportClipBrdClick(Sender: TObject);
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

procedure TTL2Project.ImportClipBrdClick(Sender: TObject);
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
        if data.CheckLine(lsrc,ltrans)>0 then
          inc(lcnt);
      end
    end;

    ShowMessage(sReplaces+' = '+IntToStr(lcnt));
    if lcnt>0 then
    begin
      Modified:=true;
      OnSBUpdate(Self);
      FillProjectGrid('');
    end;
  finally
    sl.Free;
  end;
end;

procedure TTL2Project.SetCellText(arow:integer; const atext:AnsiString);
var
  idx:integer;
begin
  if atext='' then exit;
  idx:=IntPtr(TL2Grid.Objects[0,arow]);
  if atext=data.Line[idx] then exit;

  data.Trans[idx]:=atext;
  TL2Grid.Cells[colTrans,arow]:=atext;
  if TL2Settings.cbImportParts.Checked then
  begin
    data.State[idx]:=stPartial;
    TL2Grid.Cells[colPartial,arow]:='1';
  end
  else
  begin
    data.State[idx]:=stReady;
    TL2Grid.Cells[colPartial,arow]:='0';
  end;
end;

procedure TTL2Project.PasteFromClipBrd();
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
    Modified:=true;
    OnSBUpdate(Self);
  end;
end;

//----- Fill -----

function TTL2Project.FillProjectSGRow(aRow, idx:integer;
          const afilter:AnsiString):boolean;
var
  lpath,lsrc,ltrans:AnsiString;
  lstatus:tTextStatus;
  i,j:integer;
begin
  result:=false;

  lstatus:=data.State[idx];
  if lstatus=stDeleted then exit;

  ltrans:=data.Trans[idx];

  // Skip ready translation
  if actHideReady.Checked and
    (ltrans<>'') and
    ((lstatus=stReady) or
     (TL2Settings.cbHidePartial.Checked)) then exit;

  lsrc:=data.Line [idx];

  // if filter used
  if (afilter = '') or
   (pos(afilter,AnsiLowerCase(lsrc  ))>0) or
   ((ltrans<>'') and (pos(afilter,AnsiLowerCase(ltrans))>0)) then
  begin

    // filter by path
    if (FFolderFilter<>'') and (data.Refs.RefCount>0) then
    begin
      // for all refs check upcased path w/o 'MEDIA\'
      for i:=0 to data.RefCount[idx]-1 do
      begin
        j:=data.Ref[idx,i];
        lpath:=Copy(data.Refs.GetDir(j),7);
        for j:=1 to Length(lpath) do
          if lpath[j]='/' then lpath[j]:='\'
          else lpath[j]:=UpCase(lpath[j]);

        if (lpath='') xor (FFolderFilter='\') then exit;
        if lpath<>'' then
        begin
          if (FFolderFilter='SKILLS\') and (lpath<>'SKILLS\') then exit;

          if (Pos(         FFolderFilter,lpath)<>1) and
             (Pos('UNITS\'+FFolderFilter,lpath)<>1) then exit;
        end;
      end;
    end;

    TL2Grid.Cells[colOrigin,aRow]:=lsrc;                 // Value
    if (lstatus<>stPartial) then                         // Part
      TL2Grid.Cells[colPartial,aRow]:='0'
    else
      TL2Grid.Cells[colPartial,aRow]:='1';
    if (lstatus in [stPartial,stReady]) then             // Translation
      TL2Grid.Cells[colTrans,aRow]:=ltrans;

    TL2Grid.Objects[0,aRow]:=TObject(IntPtr(idx));
    result:=true;
  end;
end;

procedure TTL2Project.FillProjectGrid(const afilter:AnsiString);
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

  TL2Grid.RowCount:=data.LineCount+1;

  for i:=0 to data.LineCount-1 do
  begin

    if (lSavedRow=0) and (lSavedIdx<=i) then
      lSavedRow:=lline;

    if FillProjectSGRow(lline,i,afilter) then
      inc(lline);
  end;

  TL2Grid.RowCount:=lline;
  TL2Grid.EndUpdate;

  TL2Grid.Row:=lSavedRow;

  if (afilter='') and Self.Active then
  begin
    TL2Grid.SetFocus;
  end;
  TL2Grid.TopRow:=TL2Grid.Row;

  TL2Grid.Cells[0,0]:=IntToStr(TL2Grid.RowCount-1);
end;

//----- Form -----

procedure TTL2Project.FormCreate(Sender: TObject);
begin
  data.Init;
  data.OnFileScan:=@ProjectFileScan;
  data.OnLineChanged:=@UpdateGrid;

  //  TL2Grid.ValidateOnSetSelection:=true;
end;

procedure TTL2Project.FormDestroy(Sender: TObject);
begin
  memEdit.ExecuteCancelAction;
  data.Free;
end;

//==== BUILD ====

procedure TTL2Project.Build;
var
  ldlg:TSelectDirectoryDialog;
  i:integer;
begin
  data.Init;
  
  ldlg:=TSelectDirectoryDialog.Create(nil);
  try
    ldlg.InitialDir:=TL2Settings.edWorkDir.Text;
    ldlg.FileName  :='';
    ldlg.Options   :=[ofAllowMultiSelect,ofEnableSizing,ofPathMustExist];
    if ldlg.Execute then
    begin
      for i:=0 to ldlg.Files.Count-1 do
        data.Build(ldlg.Files[i]);
    end;

  finally
    ldlg.Free;
  end;

  //!! Here export all
  data.Mode:=tmDefault;

  Modified:=true;
//  OnSBUpdate(Self);
  pnlFolders.Visible:=true;
  FillFoldersCombo(true); // calls   FillProjectGrid('') through changes
//  FillProjectGrid('');
  ShowStatistic();
end;

end.

