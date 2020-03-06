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
    actFileName: TAction;
    actHideReady: TAction;
    actExportFile: TAction;
    actExportClipBrd: TAction;
    actImportFile: TAction;
    actImportClipBrd: TAction;
    actOpenSource: TAction;
    actShowTemplate: TAction;
    actPartAsReady: TAction;
    actYandex: TAction;
    actReplace: TAction;
    actFindNext: TAction;
    actShowSimilar: TAction;
    actShowDoubles: TAction;
    actFilter: TAction;
    alProject: TActionList;
    edProjectFilter: TEdit;
    memEdit: TMemo;
    mnuColor: TPopupMenu;
    sbHideReady: TSpeedButton;
    sbProjectFilter: TSpeedButton;
    sbFileName: TSpeedButton;
    sbExportClipBrd: TSpeedButton;
    sbExportFile: TSpeedButton;
    sbImportClipBrd: TSpeedButton;
    sbImportFile: TSpeedButton;
    sbShowSimilar: TSpeedButton;
    sbShowDoubles: TSpeedButton;
    sbReplace: TSpeedButton;
    sbYandex: TSpeedButton;
    sbFindNext: TSpeedButton;
    cbPartAsReady: TSpeedButton;
    sbShowTemplate: TSpeedButton;
    TL2ProjectFilterPanel: TPanel;
    TL2ProjectGrid: TStringGrid;
    procedure actOpenSourceExecute(Sender: TObject);
    procedure actPartAsReadyExecute(Sender: TObject);
    procedure actShowTemplateExecute(Sender: TObject);
    procedure edProjectFilterChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure memEditExit(Sender: TObject);
    procedure memEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ShowDoublesClick(Sender: TObject);
    procedure ShowSimilarClick(Sender: TObject);
    procedure ImportFileClick(Sender: TObject);
    procedure ImportClipBrdClick(Sender: TObject);
    procedure ShortFNameClick(Sender: TObject);
    procedure ExportClipBrdClick(Sender: TObject);
    procedure ExportFileClick(Sender: TObject);
    procedure TL2ProjectGridHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure YandexClick(Sender: TObject);
    procedure ReplaceClick(Sender: TObject);
    procedure dlgOnReplace(Sender: TObject);
    procedure FindNextClick(Sender: TObject);
    procedure TL2ProjectGridDblClick(Sender: TObject);
    procedure TL2ProjectGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure TL2ProjectGridGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
    procedure TL2ProjectGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TL2ProjectGridSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure TL2ProjectGridSetCheckboxState(Sender: TObject; ACol,
      ARow: Integer; const Value: TCheckboxState);
  private
    FSBUpdate:TSBUpdateEvent;

    procedure CreateFileTab(idx: integer);
    function  FillColorPopup: boolean;
    function  FillParamPopup: boolean;
    procedure InsertColor(const acolor: AnsiString);
    procedure InsertParam(const aparam: AnsiString);
    procedure PopupColorChanged(Sender: TObject);
    procedure PopupParamChanged(Sender: TObject);
    function  ProjectFileScan(const fname:AnsiString; idx, atotal:integer):integer;
    procedure PasteFromClipBrd();
    function  CheckLine(const asrc, atrans: AnsiString; asame:Boolean; astate:tTextStatus=stReady): boolean;
    procedure FillProjectGrid(const afilter: AnsiString);
    function  FillProjectSGRow(aRow, idx: integer; const afilter: AnsiString): boolean;
    function  GetStatusText:AnsiString;
    function  Preload():boolean;
    procedure ReBoundEditor;
    function  RemoveColor(const textin: AnsiString; var textout: AnsiString): boolean;
    procedure Search(const aText: AnsiString; aRow: integer);
    procedure SetCellText(arow: integer; const atext: AnsiString);

  public
    cntBaseLines: integer;
    cntModLines: integer;
    cntModFiles: integer;

    FileName,
    ProjectName: AnsiString;
    Modified: Boolean;
    data:TTL2Translation;

    procedure New(const adir:AnsiString; allText:boolean; withChild:boolean);
    procedure Load(const fname:AnsiString);
    procedure Save();
    procedure DoExport();
    procedure MoveToIndex(idx: integer);
    procedure UpdateGrid(idx: integer);
    procedure CheckTheSame;

    property StatusBarText:AnsiString read GetStatusText;
    property OnSBUpdate:TSBUpdateEvent read FSBUpdate write FSBUpdate;
  end;

procedure Build(aprogress:TSBUpdateEvent);


implementation

{$R *.lfm}

uses
  Graphics,
  TL2SettingsForm,
  TL2EditText,
  TL2SimForm,
  LCLType,
  LazUtf8,
  ClipBrd;

resourcestring
  sWarning        = 'Warning';
  sBuildRead      = 'Build translation. Read';
  sBuildWrite     = 'Build translation in file.';
  sReplaces       = 'Total replaces';
  sExport         = 'Export finished. Create file';
  sAskExport      = 'Export All or just project?';
  sWhatExport     = 'What to export';
  sProject        = '&Project';
  sAll            = '&All';
  sTransFileError = 'Error %d in translation file %s, line %d:'#13#10'%s';
  sSBText         = 'Preload files: %d; lines: base = %d, mods = %d | ' +
                    'Project files: %d; tags: %d; lines: %d | ' +
                    'Translated: %d; patially: %d | Doubles: %d';
  sImporting      = 'Importing';
  sCheckTheSame   = 'Check for same text';
  sCheckSimilar   = 'Check for similar text';
  sDoDelete       = 'Are you sure to delete selected line(s)?'#13#10+
                    'This text will be just hidden until you save and reload project.';

const
  colFile    = 1;
  colTag     = 2;
  colFilter  = 3;
  colOrigin  = 4;
  colPartial = 5;
  colTrans   = 6;

//----- Other -----

function TTL2Project.ProjectFileScan(const fname:AnsiString; idx, atotal:integer):integer;
begin
  result:=0;
  OnSBUpdate(Self,'['+IntToStr(idx)+' / '+IntToStr(atotal)+'] '+fname);
end;

function TTL2Project.GetStatusText:AnsiString;
var
  ltyp:tTextStatus;
  i,lcnt,lc:integer;
begin
  lcnt:=0;
  lc  :=0;
  for i:=(cntBaseLines+cntModLines) to data.Lines-1 do
  begin
    ltyp:=data.State[i];
    if      (ltyp=stPartial) then inc(lcnt)
    else if (ltyp=stReady) then inc(lc);
  end;

  result:=Format(sSBText,
    [cntModFiles,cntBaseLines,cntModLines,
     data.Files,data.Tags,
     data.Lines-cntBaseLines-cntModLines,lc,lcnt,
     data.Doubles]);
end;

procedure TTL2Project.Search(const aText:AnsiString; aRow:integer);
var
  ltext:AnsiString;
  i:integer;
begin
  ltext:=aText; // already locase
  for i:=aRow to TL2ProjectGrid.RowCount-1 do
  begin
    if (Pos(ltext,AnsiLowerCase(TL2ProjectGrid.Cells[colOrigin,i]))>0) or
       (Pos(ltext,AnsiLowerCase(TL2ProjectGrid.Cells[colTrans ,i]))>0) then
    begin
      TL2ProjectGrid.Row   :=i;
      TL2ProjectGrid.TopRow:=i;
      ReBoundEditor;
      exit;
    end;
  end;
end;

function TTL2Project.CheckLine(const asrc,atrans:AnsiString; asame:boolean;
         astate:tTextStatus=stReady):boolean;
var
  ls:AnsiString;
  i,p:integer;
  lpart:boolean;
begin
  result:=false;
  if atrans='' then exit;

  if asame then
  begin
    lpart:=TL2Settings.cbImportParts.Checked;
    for i:=1 to TL2ProjectGrid.RowCount-1 do
    begin
      p:=IntPtr(TL2ProjectGrid.Objects[0,i]);
      if asrc=data.Line[p] then
      begin
        if data.State[p] in [stOriginal,stPartial] then
        begin
          data.Trans[p]:=atrans;
          if lpart or (astate=stPartial) then
            data.State[p]:=stPartial
          else
            data.State[p]:=stReady;
          result:=true;
        end
        else if (data.Trans[p]<>atrans) then
        begin
          //!! not sure what need to ask, just skip atm
        end;
        exit;
      end;
    end;
  end
  else
  begin
    ls:=FilteredString(asrc);
    for i:=1 to TL2ProjectGrid.RowCount-1 do
    begin
      p:=IntPtr(TL2ProjectGrid.Objects[0,i]);
      if data.State[p]=stOriginal then
      begin
        if ls=data.Template[p] then
        begin
          data.Trans[p]:=ReplaceTranslation(atrans,data.Line[p]);
          data.State[p]:=stPartial;
          result:=true;
        end;
      end;
    end;
  end;
end;

procedure TTL2Project.CheckTheSame;
var
  s:AnsiString;
  i,j:integer;
//  lrow:integer;
begin
//  lrow:=-1;

  i:=IntPtr(TL2ProjectGrid.Objects[0,TL2ProjectGrid.Row]);
  if data.Trans[i]<>'' then
  begin
    s:=data.Template[i];
    for j:=(cntBaseLines+cntModLines) to data.Lines-1 do
    begin
      if (data.Trans   [j]='') and // data.State[j]=stOriginal
         (data.Template[j]=s ) then
      begin
//        lrow:=TL2ProjectGrid.Row;
        data.Trans[j]:=ReplaceTranslation(data.Trans[i],data.Line[j]);
        data.State[j]:=stPartial;
        UpdateGrid(j);
      end;
    end;
  end;
{
  if lrow>0 then
  begin
    FillProjectGrid('');
    TL2ProjectGrid.Row   :=lrow;
    TL2ProjectGrid.TopRow:=lrow;
  end;
}
end;

//----- Visual -----

procedure TTL2Project.TL2ProjectGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ls:AnsiString;
  i,idx:integer;
begin
  if (Key=VK_SPACE) then
  begin
    for i:=1 to TL2ProjectGrid.RowCount-1 do
    begin
      if TL2ProjectGrid.IsCellSelected[TL2ProjectGrid.Col,i] then
      begin
        idx:=IntPtr(TL2ProjectGrid.Objects[0,i]);
        if data.State[idx]=stPartial then
        begin
          if data.Trans[idx]='' then
            data.State[idx]:=stOriginal
          else
            data.State[idx]:=stReady;
          TL2ProjectGrid.Cells[colPartial,i]:='0';
        end
        else
        begin
          data.State[idx]:=stPartial;
          TL2ProjectGrid.Cells[colPartial,i]:='1';
        end;
      end;
    end;
    Modified:=true;
    OnSBUpdate(Self);
    Key:=0;
  end;

  if (Key=VK_DELETE) then
  begin
    if (Shift=[ssAlt]) and (TL2ProjectGrid.Col=colTrans) then
    begin
      i:=TL2ProjectGrid.Row;
      idx:=IntPtr(TL2ProjectGrid.Objects[0,i]);
      if data.Trans[idx]<>'' then
        ls:=data.Trans[idx]
      else
        ls:=data.Line[idx];
      if RemoveColor(ls,ls) then
      begin
        data.Trans[idx]:=ls;
        data.State[idx]:=stPartial;
        TL2ProjectGrid.Cells[colPartial,i]:='1';
        TL2ProjectGrid.Cells[colTrans  ,i]:=ls;
        Modified:=true;
        OnSBUpdate(Self);
        Key:=0;
      end;
    end
    else
    begin
      if (TL2ProjectGrid.Col=colTrans) then
      begin
        i:=TL2ProjectGrid.Row;
        if TL2ProjectGrid.Cells[colTrans,i]<>'' then
        begin
          idx:=IntPtr(TL2ProjectGrid.Objects[0,i]);
          data.Trans[idx]:='';
          data.State[idx]:=stOriginal;
          TL2ProjectGrid.Cells[colPartial,i]:='0';
          TL2ProjectGrid.Cells[colTrans  ,i]:='';
          Modified:=true;
          OnSBUpdate(Self);
        end;
      end
      else
      begin
        if MessageDlg(sDoDelete,mtConfirmation,[mbOk,mbCancel],0)=mrOk then
        begin
          for i:=TL2ProjectGrid.RowCount-1 downto 1 do
          begin
            if TL2ProjectGrid.IsCellSelected[TL2ProjectGrid.Col,i] then
            begin
              idx:=IntPtr(TL2ProjectGrid.Objects[0,i]);
              data.State[idx]:=stDeleted;
              TL2ProjectGrid.DeleteRow(i);
            end;
          end;

          Modified:=true;
          OnSBUpdate(Self);
        end;
      end;
      Key:=0;
    end;
  end;

  if (Key=VK_RETURN) and
     (TL2ProjectGrid.Col=colTrans) then
    TL2ProjectGrid.EditorMode:=true;

  if (Shift=[ssCtrl]) then
  begin
    case Key of
      VK_A: begin
        TL2ProjectGrid.Selection:=
            TGridRect(Rect(colOrigin,1,colOrigin,TL2ProjectGrid.RowCount));
        Key:=0;
      end;

      VK_C: begin
        ExportClipBrdClick(self);
        Key:=0;
      end;

      VK_V: begin
        if TL2ProjectGrid.Col=colTrans then
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
  lr:=TL2ProjectGrid.Row;
  lidx:=IntPtr(TL2ProjectGrid.Objects[0,lr]);
  if (memEdit.Tag=0) and (data.Trans[lIdx]<>memEdit.Text) then
  begin
    data.Trans[lidx]:=memEdit.Text;
    TL2ProjectGrid.Cells[colTrans{TL2ProjectGrid.Col},lr]:=memEdit.Text;
    if memEdit.Text='' then
    begin
      data.State[lidx]:=stOriginal;
      TL2ProjectGrid.Cells[colPartial,lr]:='0';
    end
    else
    begin
      if TL2ProjectGrid.Cells[colPartial,lr]='1' then
        data.State[lidx]:=stPartial
      else
        data.State[lidx]:=stReady;
      CheckTheSame;
      TL2ProjectGrid.Row:=lr;
      TL2ProjectGrid.Col:=colTrans;
    end;
    Modified:=true;
    OnSBUpdate(Self);
  end;
  // when we close/change tab with active editor
  if Parent.Visible then
    TL2ProjectGrid.SetFocus;
end;

procedure TTL2Project.InsertParam(const aparam:AnsiString);
begin
  memEdit.SelText:=aparam;
end;

procedure TTL2Project.PopupParamChanged(Sender:TObject);
begin
  InsertParam(Copy((Sender as TMenuItem).Caption,4));
end;

function TTL2Project.FillParamPopup:boolean;
const
  maxparams=10;
var
  lPopItem:TMenuItem;
  ls:AnsiString;
  params :array [0..maxparams-1] of String[31];
  idx,i,lcnt,llen:integer;
begin
  result:=false;
  mnuColor.Items.Clear;

  lcnt:=0;
  idx:=IntPtr(TL2ProjectGrid.Objects[0,TL2ProjectGrid.Row]);
  ls:=data.Line[idx];
  llen:=Length(ls);
  i:=1;

  repeat
    if ls[i]='[' then
    begin
      params[lcnt]:='';
      repeat
        params[lcnt]:=params[lcnt]+ls[i];
        inc(i);
      until (i>llen) or (ls[i]=']');
      if i<=llen then
      begin
        inc(i);
        params[lcnt]:=params[lcnt]+']';
        // for case of [[param]]
        if (i<=llen) and (ls[i]=']') then
        begin
          params[lcnt]:=params[lcnt]+']';
          inc(i);
        end;
        inc(lcnt);
        if lcnt=maxparams then break;
      end;
    end
    else if ls[i]='<' then
    begin
      params[lcnt]:='';
      repeat
        params[lcnt]:=params[lcnt]+ls[i];
        inc(i);
      until (i>llen) or (ls[i]='>');
      if i<=llen then
      begin
        inc(i);
        params[lcnt]:=params[lcnt]+'>';
        inc(lcnt);
        if lcnt=maxparams then break;
      end;
    end
    else
      inc(i);
  until i>llen;

  if lcnt=0 then exit;
  
  if lcnt=1 then
  begin
    InsertParam(params[0]);
  end
  else
  begin  
    for i:=0 to lcnt-1 do
    begin
      lPopItem:=TMenuItem.Create(mnuColor);
      if i<9 then
        lPopItem.Caption:='&'+IntToStr(i+1)+' '+params[i]
      else
        lPopItem.Caption:='&0 '+params[i];
      lPopItem.OnClick:=@PopupParamChanged;
      mnuColor.Items.Add(lPopItem);
    end;

    mnuColor.PopUp;
  end;
end;

function TTL2Project.RemoveColor(const textin:AnsiString; var textout:AnsiString):boolean;
var
  ls:AnsiString;
  i,j:integer;
begin
  result:=false;
  i:=1;
  j:=1;
  SetLength(ls,Length(textin));
  while i<=Length(textin) do
  begin
    if textin[i]<>'|' then
    begin
      ls[j]:=textin[i];
      inc(i);
      inc(j);
    end
    else
    begin
      result:=true;
      inc(i);
      if      textin[i]='u' then inc(i)
      else if textin[i]='c' then inc(i,9);
    end;
  end;
  SetLength(ls,j);
  textout:=ls;
end;

procedure TTL2Project.InsertColor(const acolor:AnsiString);
var
  ls:AnsiString;
  l:integer;
begin
  if memEdit.SelLength>0 then
  begin
    ls:=memEdit.SelText;
    l:=Length(ls);
    if ((l<2  ) or (ls[l-1]<>'|') or (ls[l]<>'u')) and
       ((l<>10) or (ls[  1]<>'|') or (ls[2]<>'c')) then
      ls:=ls+'|u';
    if (l<10) or (ls[1]<>'|') or (ls[2]<>'c') then
      ls:=acolor+ls
    else
    begin
      ls[ 3]:=acolor[ 3];
      ls[ 4]:=acolor[ 4];
      ls[ 5]:=acolor[ 5];
      ls[ 6]:=acolor[ 6];
      ls[ 7]:=acolor[ 7];
      ls[ 8]:=acolor[ 8];
      ls[ 9]:=acolor[ 9];
      ls[10]:=acolor[10];
    end;
    memEdit.SelText:=ls;
  end
  else
    memEdit.SelText:=acolor;
end;

procedure TTL2Project.PopupColorChanged(Sender:TObject);
begin
  InsertColor(Copy((Sender as TMenuItem).Caption,4));
end;

function TTL2Project.FillColorPopup:boolean;
const
  maxcolors=10;
var
  lPopItem:TMenuItem;
  ls:AnsiString;
  colors :array [0..maxcolors-1] of String[10]; //#124'cAARRGGBB', 10 times per text must be enough
  idx,i,llcnt,lcnt,llen:integer;
begin
  result:=false;
  mnuColor.Items.Clear;

  //-- Fill colors array
  lcnt:=0;
  idx:=IntPtr(TL2ProjectGrid.Objects[0,TL2ProjectGrid.Row]);
  ls:=data.Line[idx];
  llen:=Length(ls)-10;
  i:=1;
  repeat
    if (ls[i]=#124) then
    begin
      inc(i);
      if (ls[i]='c') then
      begin
        inc(i);
        SetLength(colors[lcnt],10);
        colors[lcnt][ 1]:=#124;
        colors[lcnt][ 2]:='c';
        colors[lcnt][ 3]:=ls[i]; inc(i);
        colors[lcnt][ 4]:=ls[i]; inc(i);
        colors[lcnt][ 5]:=ls[i]; inc(i);
        colors[lcnt][ 6]:=ls[i]; inc(i);
        colors[lcnt][ 7]:=ls[i]; inc(i);
        colors[lcnt][ 8]:=ls[i]; inc(i);
        colors[lcnt][ 9]:=ls[i]; inc(i);
        colors[lcnt][10]:=ls[i]; inc(i);

        llcnt:=0;
        while llcnt<lcnt do
        begin
          if colors[lcnt]=colors[llcnt] then
            break;
          inc(llcnt);
        end;
        if llcnt=lcnt then
        begin
          inc(lcnt);
          if lcnt=maxcolors then break;
        end;
      end
      else
        inc(i);
    end
    else
      inc(i);
  until i>llen;

  if lcnt=0 then
    exit;

  //-- replace without confirmations if one color only
  if lcnt=1 then
  begin
    InsertColor(colors[0]);
  end
  //-- Create and call menu if several colors
  else
  begin
    for i:=0 to lcnt-1 do
    begin
      lPopItem:=TMenuItem.Create(mnuColor);
      if i<9 then
        lPopItem.Caption:='&'+IntToStr(i+1)+' '+colors[i]
      else
        lPopItem.Caption:='&0 '+colors[i];
      lPopItem.OnClick:=@PopupColorChanged;
      mnuColor.Items.Add(lPopItem);
    end;

    mnuColor.PopUp;
  end;
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
    if FillColorPopup then
    begin
      Key:=0;
    end;
  end;

  if (Key=VK_V) and (Shift=[ssAlt]) then
  begin
    if FillParamPopup then
    begin
      Key:=0;
    end;
  end;

  if Key=VK_RETURN then
  begin
    memEdit.Tag:=0;
    Key:=VK_TAB;
    TL2ProjectGrid.EditingDone;
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
  r:=TL2ProjectGrid.CellRect(colTrans,TL2ProjectGrid.Row);
  InflateRect(r,-1,-1);
  memEdit.Tag:=0;
  memEdit.BoundsRect:=r;
end;

procedure TTL2Project.TL2ProjectGridHeaderSized(Sender: TObject;
  IsColumn: Boolean; Index: Integer);
begin
  if IsColumn then
    ReBoundEditor;
end;

procedure TTL2Project.TL2ProjectGridSelectEditor(Sender: TObject; aCol,
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
  Sentence:=aText;

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

procedure TTL2Project.TL2ProjectGridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  ls:String;
  ts:TTextStyle;
  count1, count2: integer;
  lidx:integer;
begin
  if not (gdFixed in aState) then
  begin
    with TL2ProjectGrid do
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

        if gdSelected in aState then
          Canvas.Brush.Color:=clHighlight
        else
          Canvas.Brush.Color:=clWindow;
        Canvas.Brush.Style:= bsSolid;
        Canvas.FillRect(aRect);

        ls:=Cells[ACol,ARow];
        if (ACol=colOrigin) and (ls[Length(ls)]=' ') then
          ls[Length(ls)]:='~';
        Canvas.TextRect(aRect,
          aRect.Left+constCellPadding,aRect.Top+constCellPadding,ls);

        if gdFocused in aState then
          Canvas.DrawFocusRect(aRect);
        exit;
      end;
    end;
  end;

//  (Sender as TStringGrid).DefaultDrawCell(aCol,aRow,aRect,aState);
end;

procedure TTL2Project.TL2ProjectGridGetEditText(Sender: TObject; ACol,ARow: Integer; var Value: string);
begin
  memEdit.Text:=Value;
end;

procedure TTL2Project.MoveToIndex(idx:integer);
var
  i:integer;
begin
  for i:=1 to TL2ProjectGrid.RowCount-1 do
  begin
    if idx=IntPtr(TL2ProjectGrid.Objects[0,i]) then
    begin
      TL2ProjectGrid.Row   :=i;
      TL2ProjectGrid.TopRow:=i;
      exit;
    end;
  end;
end;

procedure TTL2Project.UpdateGrid(idx:integer);
var
  i:integer;
begin
  for i:=1 to TL2ProjectGrid.RowCount-1 do
  begin
    if idx=IntPtr(TL2ProjectGrid.Objects[0,i]) then
    begin
      TL2ProjectGrid.Cells[colTrans,i]:=data.Trans[idx];
      if data.State[idx]=stPartial then
        TL2ProjectGrid.Cells[colPartial,i]:='1'
      else
        TL2ProjectGrid.Cells[colPartial,i]:='0';
      exit;
    end;
  end;
end;

//----- Load -----

function TTL2Project.Preload():boolean;
var
  ls:AnsiString;
  i,lcnt:integer;
begin
  result:=true;

  data.Filter:=flNoSearch;
  data.Mode:=tmDefault;

  ls:=TL2Settings.edDefaultFile.Text;
  if ls<>'' then
  begin
    cntBaseLines:=data.LoadFromFile(ls);
    if cntBaseLines<0 then // ErrorCode<>0
    begin
      MessageDlg(sWarning,
        Format(sTransFileError,
               [data.ErrorCode,data.ErrorFile,data.ErrorLine,data.ErrorText]),
               mtError,[mbOk],0);
      cntBaseLines:=0;
    end;
  end
  else
   cntBaseLines:=0;

  if cntBaseLines>0 then
    cntModFiles:=1
  else
    cntModFiles:=0;

  cntModLines:=0;
  data.Mode  :=tmMod;
  data.Filter:=flNoFilter;
  ls:=TL2Settings.edWorkDir.Text;
  if (ls<>'') and (ls[Length(ls)]<>'\') then ls:=ls+'\';
  for i:=0 to TL2Settings.lbAddFileList.Count-1 do
  begin
    lcnt:=data.LoadFromFile(ls+TL2Settings.lbAddFileList.Items[i]);
    if lcnt>0 then
    begin
      inc(cntModFiles);
      inc(cntModLines,lcnt);
    end
    else if lcnt<0 then // ErrorCode<>0
    begin
      MessageDlg(sWarning,
        Format(sTransFileError,
               [data.ErrorCode,data.ErrorFile,data.ErrorLine,data.ErrorText]),
               mtError,[mbOk],0);
    end;
  end;

end;

procedure TTL2Project.New(const adir:AnsiString; allText:boolean; withChild:boolean);
begin
  data.Filter:=flFiltered;
  data.Scan(adir,allText,withChild);
  Modified:=true;
  OnSBUpdate(Self);
  FillProjectGrid('');
//!!  actShowDoubles.Visible:=data.Doubles<>0;
end;

procedure TTL2Project.Load(const fname:AnsiString);
var
  ls:AnsiString;
begin
  data.Filter:=flFiltered;
  data.Mode  :=tmOriginal;
  data.LoadInfo(fname);
  if data.LoadFromFile(fname)<0 then
  begin
    MessageDlg(sWarning,
      Format(sTransFileError,
             [data.ErrorCode,data.ErrorFile,data.ErrorLine,data.ErrorText]),
             mtError,[mbOk],0);
    exit;
  end;
  FileName:=fname;

//!!  actShowDoubles.Visible:=data.Doubles<>0;
  OnSBUpdate(Self);

  if data.Referals=0 then
  begin
    TL2ProjectGrid.Columns[colFile-1].Visible:=false;
    TL2ProjectGrid.Columns[colTag -1].Visible:=false;
    actFileName.Enabled:=false;
  end
  else
  begin
    if data.SrcDir='' then
    begin
      ls:=TL2Settings.edRootDir.Text;
      if ls[Length(ls)]<>'\' then ls:=ls+'\';
      ls:=ls+ProjectName;
      if FileExists(ls+'\'+data._File[0]) then
        data.SrcDir:=ls;
    end;
  end;

  FillProjectGrid('');
end;

procedure TTL2Project.Save();
begin
  data.Mode:=tmOriginal;
  data.SaveInfo(FileName);
  data.SaveToFile(FileName,stPartial);
  Modified:=false;
  OnSBUpdate(Self); // for Modified only
end;

procedure TTL2Project.DoExport();
var
  lstat:tTextStatus;
  ls:AnsiString;
  res:integer;
begin
  res:=QuestionDlg(sAskExport, sWhatExport,
                   mtConfirmation,
                   [mrNo, sProject,'IsDefault',
                   mrYes,sAll],0);
  if res=mrCancel then exit;

  if TL2Settings.cbExportParts.Checked then
    lstat:=stPartial
  else
    lstat:=stOriginal;

  ls:=TL2Settings.edWorkDir.Text;
  if (ls<>'') and (ls[Length(ls)]<>'\') then ls:=ls+'\';

  case res of
    mrYes: begin
      data.Mode:=tmDefault;
      ls:=ls+'Full_'+ProjectName+DefaultExt;
      data.SaveToFile(ls,lstat);
    end;
    mrNo : begin
      data.Mode:=tmOriginal;
      ls:=ls+ProjectName+DefaultExt;
      data.SaveToFile(ls,lstat);
    end;
  else
    // mrCancel
    exit;
  end;
  ShowMessage(sExport+' '+ls);
end;

//----- Edit -----

procedure TTL2Project.TL2ProjectGridSetCheckboxState(Sender: TObject;
  ACol, ARow: Integer; const Value: TCheckboxState);
var
  lidx:integer;
begin
  lidx:=IntPtr(TL2ProjectGrid.Objects[0,aRow]);
  if Value=cbChecked then
  begin
    TL2ProjectGrid.Cells[colPartial,ARow]:='1';
    data.State[lidx]:=stPartial;
  end
  else
  begin
    TL2ProjectGrid.Cells[colPartial,ARow]:='0';
    if data.Trans[lidx]<>'' then
      data.State[lidx]:=stReady
    else
      data.State[lidx]:=stOriginal;
  end;
  Modified:=true;
  OnSBUpdate(Self);
end;

procedure TTL2Project.CreateFileTab(idx:integer);
var
  ts:TTabSheet;
  lform:TForm;
  lmemo:TMemo;
  sl:TStringList;
  ls:AnsiString;
  i,xpos:integer;
begin
  if data.SrcDir<>'' then
    ls:=data.SrcDir
  else
  begin
    ls:=TL2Settings.edRootDir.Text;
    if ls[Length(ls)]<>'\' then
      ls:=ls+'\';
    ls:=ls+ProjectName;
  end;
  ls:=ls+'\'+data._File[idx];

  sl:=TStringList.Create;
  try
    sl.LoadFromFile(ls);
  except
    sl.Free;
    exit;
  end;
  xpos:=1;
  for i:=0 to sl.Count-1 do
  begin
    sl[i]:=StringReplace(sl[i],#9,'    ',[rfReplaceAll]);
    if i=(data.FileLine[idx]-1) then
    begin
      xpos:=Pos(data.Attrib[idx],sl[i]);
    end;
  end;

  ts:=(Self.Parent.Parent as TPageControl).AddTabSheet;
  ts.Tag:=1;
  ts.ShowHint:=false;
  ts.Caption :='***'{sSource} + ExtractFileName(data._File[idx]);

  lform:=TForm.Create(ts);
  lform.Parent     :=ts;
  lform.BorderStyle:=bsNone;
  lform.Align      :=alClient;
  lform.Visible    :=true;

  lmemo:=tMemo.Create(lform);
  lmemo.Parent    :=lform;
  lmemo.Align     :=alClient;
  lmemo.WordWrap  :=False;
  lmemo.ReadOnly  :=True;
  lmemo.Scrollbars:=ssBoth;
  lmemo.Lines.Assign(sl);
  lmemo.Show;

  sl.Free;
  (Self.Parent.Parent as TPageControl).ActivePage:=ts;
  lmemo.SetFocus;
  lmemo.CaretPos :=Point(xpos-1,data.FileLine[idx]-1);
  lmemo.SelStart :=Pos(data.Attrib[idx],lmemo.Text)-1;
  lmemo.SelLength:=Length(data.Attrib[idx]);
end;

procedure TTL2Project.TL2ProjectGridDblClick(Sender: TObject);
//var  lrow:integer;
begin
  if TL2ProjectGrid.Col in [colFile,colTag] then
  begin
    CreateFileTab(IntPtr(TL2ProjectGrid.Objects[0,TL2ProjectGrid.Row]));
  end;

  if TL2ProjectGrid.Col in [colFilter,colOrigin,colPartial,colTrans] then
  begin
    with TEditTextForm.Create(Self) do
    begin
      SelectLine(IntPtr(TL2ProjectGrid.Objects[0,TL2ProjectGrid.Row]));
      if ShowModal=mrOk then
      begin
        CheckTheSame;
        Modified:=true;
        OnSBUpdate(Self);
  {
        lrow:=TL2ProjectGrid.Row;
        FillProjectGrid('');
        TL2ProjectGrid.Row:=lrow;
  }
      end;
    end;
  end;
end;

procedure TTL2Project.actOpenSourceExecute(Sender: TObject);
begin
  CreateFileTab(IntPtr(TL2ProjectGrid.Objects[0,TL2ProjectGrid.Row]));
end;

//----- Buttons ans Editfield -----

procedure TTL2Project.edProjectFilterChange(Sender: TObject);
var
  ls:AnsiString;
  llines:integer;
begin
  llines:=data.Lines-(cntBaseLines+cntModLines);

  if Length(edProjectFilter.Text)<4 then
    ls:=''
  else
    ls:=AnsiLowerCase(edProjectFilter.Text);

  // crazy logic
  if actFilter.Checked then
  begin
    if ls='' then
    begin
      if TL2ProjectGrid.RowCount<>(llines+1) then
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
      Search(ls,TL2ProjectGrid.Row);
  end;
end;

procedure TTL2Project.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  memEdit.ExecuteCancelAction;
end;

procedure TTL2Project.actPartAsReadyExecute(Sender: TObject);
var
  i,idx:integer;
begin
  for i:=1 to TL2ProjectGrid.RowCount-1 do
  begin
    idx:=IntPtr(TL2ProjectGrid.Objects[0,i]);
    if data.State[idx]=stPartial then
    begin
      data.State[idx]:=stReady;
      TL2ProjectGrid.Cells[colPartial,i]:='0';
    end;
  end;
end;

procedure TTL2Project.actShowTemplateExecute(Sender: TObject);
begin
  if actShowTemplate.Checked then
  begin
    TL2ProjectGrid.Columns[colFilter-1].Visible:=true; //!!!!
    TL2ProjectGrid.Columns[colFilter-1].Width:=64;
  end
  else
  begin
    TL2ProjectGrid.Columns[colFilter-1].Visible:=false; //!!!!
  end;
end;

procedure TTL2Project.FindNextClick(Sender: TObject);
begin
  Search(edProjectFilter.Text,TL2ProjectGrid.Row+1);
end;

procedure TTL2Project.ShortFNameClick(Sender: TObject);
var
  ls:AnsiString;
  i,idx:integer;
begin
  for i:=1 to TL2ProjectGrid.RowCount-1 do
  begin
    idx:=IntPtr(TL2ProjectGrid.Objects[0,i]);
    ls:=data._File[idx];
    if actFileName.Checked then
      ls:=ExtractFileName(ls);
    TL2ProjectGrid.Cells[colFile,i]:=ls;
  end;
end;

procedure TTL2Project.YandexClick(Sender: TObject);
var
  ls:AnsiString;
  idx:integer;
begin
  idx:=IntPtr(TL2ProjectGrid.Objects[0,TL2ProjectGrid.Row]);

  if memEdit.Visible and (memEdit.Text<>'') then
  begin
    if memEdit.SelLength>0 then
    begin
      memEdit.SelText:=TranslateYandex(memEdit.SelText);
      ls:=memEdit.Text;
{
      ls:=memEdit.Text;
      UTF8Delete(ls,memEdit.SelStart+1,memEdit.SelLength);
      UTF8Insert(TranslateYandex(memEdit.SelText),ls,memEdit.SelStart+1);
      memEdit.Text:=ls;
}
    end
    else
      ls:=TranslateYandex(memEdit.Text);
  end
  else
  begin
    ls:=TranslateYandex(data.Line[idx]);
  end;

  data.Trans[idx]:=ls;//TranslateYandex(data.Line[idx]);
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
  for i:=TL2ProjectGrid.Row to TL2ProjectGrid.RowCount-1 do
  begin
    idx:=IntPtr(TL2ProjectGrid.Objects[0,i]);
    ls:=data.Trans[idx];//TL2ProjectGrid.Cells[colTrans,i];
    p:=Pos((Sender as TReplaceDialog).FindText,ls);
    if p>0 then
    begin
      inc(lcnt);
      ls:=StringReplace(ls,lsrc,lr,[rfReplaceAll]);
      data.Trans[idx]:=ls;
      TL2ProjectGrid.Cells[colTrans,i]:=ls;
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
begin
  with TSimilaristForm.Create(Self,true) do ShowModal;
end;

procedure TTL2Project.ShowDoublesClick(Sender: TObject);
begin
  with TSimilaristForm.Create(Self,false) do ShowModal;
end;

//----- Export - import -----

procedure TTL2Project.ExportFileClick(Sender: TObject);
var
  sl:TStringList;
  SaveDialog: TSaveDialog;
  i:integer;
begin
  sl:=TStringList.Create;
  try
    for i:=1 to TL2ProjectGrid.RowCount-1 do
    begin
      if TL2ProjectGrid.IsCellSelected[colOrigin,i] then
        sl.Add(TL2ProjectGrid.Cells[colOrigin,i]);
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

procedure TTL2Project.ImportFileClick(Sender: TObject);
var
  ldata:TTL2Translation;
  OpenDialog: TOpenDialog;
  lcnt,i,fcnt:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.InitialDir:=TL2Settings.edImportDir.Text;
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
          OnSBUpdate(Self,sImporting+' '+OpenDialog.Files[fcnt]+' - '+sCheckTheSame);
          // Check for the same
          for i:=0 to ldata.Lines-1 do
          begin
            if CheckLine(ldata.Line[i],ldata.Trans[i],true,ldata.State[i]) then
            begin
              inc(lcnt);
            end;
          end;

          OnSBUpdate(Self,sImporting+' '+OpenDialog.Files[fcnt]+' - '+sCheckSimilar);
          // Check for similar
          for i:=0 to ldata.Lines-1 do
          begin
            if CheckLine(ldata.Line[i],ldata.Trans[i],false) then
            begin
              inc(lcnt);
            end;
          end;
        end;
      end;
      ShowMessage(sReplaces+' = '+IntToStr(lcnt));
      if lcnt>0 then
      begin
        Modified:=true;
        FillProjectGrid('');
      end;
      OnSBUpdate(Self);
      ldata.Free;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TTL2Project.ExportClipBrdClick(Sender: TObject);
var
  sl:TStringList;
  i:integer;
begin
  sl:=TStringList.Create;
  try
    for i:=1 to TL2ProjectGrid.RowCount-1 do
    begin
      if TL2ProjectGrid.IsCellSelected[TL2ProjectGrid.Col{colOrigin},i] then
      begin
        sl.Add(TL2ProjectGrid.Cells[TL2ProjectGrid.Col{colOrigin},i]);
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
    // Same
    for lline:=0 to sl.Count-1 do
    begin
      s:=sl[lline];
      // Split to parts
      p:=Pos(#9,s);
      if p>0 then
      begin
        lsrc:=Copy(s,1,p-1);
        ltrans:=Copy(s,p+1);
        if CheckLine(lsrc,ltrans,true) then
          inc(lcnt);
      end
    end;
    // Similar
    for lline:=0 to sl.Count-1 do
    begin
      s:=sl[lline];
      // Split to parts
      p:=Pos(#9,s);
      if p>0 then
      begin
        lsrc:=Copy(s,1,p-1);
        ltrans:=Copy(s,p+1);
        if CheckLine(lsrc,ltrans,false) then
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
  idx:=IntPtr(TL2ProjectGrid.Objects[0,arow]);
  data.Trans[idx]:=atext;
  data.State[idx]:=stReady;
  TL2ProjectGrid.Cells[colTrans  ,arow]:=atext;
  TL2ProjectGrid.Cells[colPartial,arow]:='0';
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
  while ls[i] in [#10,#13] do dec(i);
  if i<Length(ls) then SetLength(ls,i);

  sl:=TStringList.Create;
  try
    sl.Text:=ls;
    lcnt:=sl.Count;
    if lcnt=1 then
    begin
      for i:=1 to TL2ProjectGrid.RowCount-1 do
      begin
        if TL2ProjectGrid.IsCellSelected[colTrans,i] then
        begin
          SetCellText(i,ls);
        end;
      end;
    end
    else if lcnt>1 then
    begin
      i:=TL2ProjectGrid.Row;
      for j:=0 to lcnt-1 do
      begin
        SetCellText(i,sl[j]);
        inc(i);
        if i=TL2ProjectGrid.RowCount then break;
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
  ls,lsrc,ltrans:AnsiString;
  lstatus:tTextStatus;
begin
  result:=false;

  lstatus:=data.State[idx];
  if lstatus=stDeleted then exit;

  ltrans :=data.Trans[idx];

  if actHideReady.Checked and
    (ltrans<>'') and
    (lstatus=stReady) then exit;

  lsrc:=data.Line [idx];

  if (afilter = '') or
   (pos(afilter,AnsiLowerCase(lsrc  ))>0) or
   (pos(afilter,AnsiLowerCase(ltrans))>0) then
  begin

    if data.Referals>0 then
    begin
      ls:=data._File[idx];
      if actFileName.Checked then
        ls:=ExtractFileName(ls);
      TL2ProjectGrid.Cells[colFile,aRow]:=ls;                 // File
      TL2ProjectGrid.Cells[colTag ,aRow]:=data.Attrib[idx];   // Tag
    end;

    TL2ProjectGrid.Cells[colFilter,aRow]:=data.Template[idx]; // Template

    TL2ProjectGrid.Cells[colOrigin,aRow]:=lsrc;               // Value
    if (lstatus<>stPartial) then                              // Part
      TL2ProjectGrid.Cells[colPartial,aRow]:='0'
    else
      TL2ProjectGrid.Cells[colPartial,aRow]:='1';
    if (lstatus in [stPartial,stReady]) then                  // Translation
      TL2ProjectGrid.Cells[colTrans,aRow]:=ltrans;

    TL2ProjectGrid.Objects[0,aRow]:=TObject(idx);
    result:=true;
  end;
end;

procedure TTL2Project.FillProjectGrid(const afilter:AnsiString);
var
  i,lline:integer;
begin
  TL2ProjectGrid.Clear;
  TL2ProjectGrid.BeginUpdate;
  lline := 1;

  TL2ProjectGrid.RowCount:=data.Lines-cntBaseLines-cntModLines+1;

  for i:=(cntBaseLines+cntModLines) to data.Lines-1 do
  begin
    if FillProjectSGRow(lline,i,afilter) then
      inc(lline);
  end;

  TL2ProjectGrid.RowCount:=lline;
  TL2ProjectGrid.EndUpdate;

  TL2ProjectGrid.Row:=1;
  if afilter='' then
  begin
    TL2ProjectGrid.SetFocus;
  end;
end;

//----- Form -----

procedure TTL2Project.FormCreate(Sender: TObject);
begin
  data.Init;
  data.OnFileScan:=@ProjectFileScan;

  SetFilterWords(TL2Settings.edFilterWords.Caption);
  Preload();
//  TL2ProjectGrid.ValidateOnSetSelection:=true;
end;

//==== BUILD ====

procedure CycleDirBuild(sl:TStringList; const adir:AnsiString);
var
  sr:TSearchRec;
  lext,lname:AnsiString;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDirBuild(sl, lname);
      end
      else
      begin
        lext:=UpCase(ExtractFileExt(lname));
        if lext='.DAT' then
          sl.Add(lname);
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

procedure Build(aprogress:TSBUpdateEvent);
var
  data:TTL2Translation;
  sl:TStringList;
  ldir:AnsiString;
  i:integer;
begin
  data.Init;
  
  data.Filter:=flNoSearch;
  data.Mode:=tmDefault;

  ldir:=TL2Settings.edDefaultFile.Text;
  if ldir='' then
    ldir:=DefDATFile;

  aprogress(TObject(1),sBuildRead+' '+ldir);
  data.LoadFromFile(ldir);
  
  // ready for import files

  ldir:=TL2Settings.edImportDir.Text;
  
  if ldir[Length(ldir)]='\' then
    SetLength(ldir,Length(ldir)-1);

  sl:=TStringList.Create();
  CycleDirBuild(sl, ldir);

  //!! think about preload here
  data.Mode  :=tmMod;
  data.Filter:=flNoFilter;
  for i:=0 to sl.Count-1 do
  begin
    aprogress(TObject(1),sBuildRead+' '+sl[i]);
    data.LoadFromFile(sl[i]);
  end;

  sl.Free;

  //!! Here export all
  data.Mode:=tmDefault;

//  ldir:=TL2Settings.edWorkDir.Text;
//  if (ldir<>'') and (ldir[Length(ldir)]<>'\') then ldir:=ldir+'\';

  aprogress(TObject(1),sBuildWrite);
  data.SaveToFile(''{ldir+DefDATFile},stPartial);
  aprogress(nil,sBuildWrite);

  data.Free;
end;

end.

