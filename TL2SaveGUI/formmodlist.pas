unit formModList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  Grids, tl2save, rgglobal, tl2db;

type

  { TfmModList }

  TfmModList = class(TForm)
    bbClear: TBitBtn;
    bbUpdate: TBitBtn;
    cbModList: TComboBox;
    sgBound: TStringGrid;
    sgFull: TStringGrid;
    lblFull: TLabel;
    lblRecent: TLabel;
    lblBound: TLabel;
    sgRecent: TStringGrid;
    sbUp: TSpeedButton;
    sbDown: TSpeedButton;
    sbAdd: TSpeedButton;
    sbDelete: TSpeedButton;
    sbClipboard: TSpeedButton;
    procedure sbClipboardClick(Sender: TObject);
    procedure bbClearClick    (Sender: TObject);
    procedure bbUpdateClick   (Sender: TObject);
    procedure sbAddClick      (Sender: TObject);
    procedure sbDeleteClick   (Sender: TObject);
    procedure sbDownClick     (Sender: TObject);
    procedure sbUpClick       (Sender: TObject);
    procedure sgBoundAfterSelection(Sender: TObject; aCol, aRow: Integer);

  private
    FSGame:TTL2SaveFile;

    procedure CheckButtons;
    procedure FillGrid(agrid: TStringGrid; alist: TTL2ModList);
    procedure FillGridRow(agrid: TStringGrid; arow: integer; const amod: TTL2Mod);
    procedure FillGridRow(agrid: TStringGrid; arow: integer; const amod: TModData);

  public
    procedure FillInfo(aSGame: TTL2SaveFile);

  end;

var
  fmModList: TfmModList;

implementation

{$R *.lfm}

uses
  ClipBrd,
  formSettings;

{ TfmModList }

resourcestring
  rsDoClear  = 'Are you sure to clear mod list?';
  rsReminder = 'Don''t forget to check modded objects.'#13#10+
               'Or use "Fix Modded objects" item from Main menu';

procedure TfmModList.CheckButtons;
begin
  sbDelete   .Enabled:=sgBound.RowCount>1;
  sbUp       .Enabled:=sgBound.Row>1;
  sbDown     .Enabled:=sgBound.Row<sgBound.RowCount-1;
  sbClipboard.Enabled:=sgBound.RowCount>1;
end;

procedure TfmModList.sgBoundAfterSelection(Sender: TObject; aCol, aRow: Integer);
begin
  CheckButtons;
end;

procedure TfmModList.sbUpClick(Sender: TObject);
begin
  sgBound.MoveColRow(false,sgBound.Row,sgBound.Row-1);
  CheckButtons;
end;

procedure TfmModList.sbDownClick(Sender: TObject);
begin
  sgBound.MoveColRow(false,sgBound.Row,sgBound.Row+1);
  CheckButtons;
end;

procedure TfmModList.sbDeleteClick(Sender: TObject);
begin
  sgBound.DeleteRow(sgBound.Row);
  CheckButtons;
end;

procedure TfmModList.bbClearClick(Sender: TObject);
begin
  if MessageDlg(rsDoClear,mtConfirmation,[mbOk,mbCancel],0,mbOk)=mrOk then
  begin
    sgBound .Clear;
    sgRecent.Clear;
    sgFull  .Clear;

    CheckButtons;
    bbUpdate.Enabled:=true;
  end;
end;

procedure TfmModList.sbAddClick(Sender: TObject);
var
  lid:TRGID;
  llist:tModDataArray;
  i,idx:integer;
  found:boolean;
begin
  if sgBound.RowCount<11 then
  begin
    idx:=cbModList.ItemIndex;
    if idx>=0 then
    begin
      llist:=GetModList;
      idx:=IntPtr(cbModList.Items.Objects[idx]);
      lid:=llist[idx].id;
      found:=false;
      for i:=1 to sgBound.RowCount-1 do
      begin
        found:=StrToInt(sgBound.Cells[2,i])=lid;
        if found then break;
      end;
      if not found then
      begin
        if sgBound.RowCount=0 then
          sgBound.RowCount:=2
        else
          sgBound.RowCount:=sgBound.RowCount+1;
        FillGridRow(sgBound,sgBound.RowCount-1,llist[idx]);
      end;
    end;
  end;
  CheckButtons;
end;

procedure TfmModList.sbClipboardClick(Sender: TObject);
var
  sl:TStringList;
  i:integer;
begin
  sl:=TStringList.Create;
  try
    for i:=1 to sgBound.RowCount-1 do
      sl.Add(sgBound.Cells[0,i]+' v.'+sgBound.Cells[1,i]);

    Clipboard.asText:=sl.Text;
  finally
    sl.Free;
  end;
end;

procedure TfmModList.FillGridRow(agrid:TStringGrid; arow:integer; const amod:TModData);
begin
  agrid.Cells[0,arow]:=amod.title;
  agrid.Cells[1,arow]:=IntToStr(amod.version);
  agrid.Cells[2,arow]:=TextId  (amod.id);
end;

procedure TfmModList.FillGridRow(agrid:TStringGrid; arow:integer; const amod:TTL2Mod);
begin
  agrid.Cells[0,arow]:=GetTL2Mod(amod.id);
  agrid.Cells[1,arow]:=IntToStr (amod.version);
  agrid.Cells[2,arow]:=TextId   (amod.id);
end;

procedure TfmModList.FillGrid(agrid:TStringGrid; alist:TTL2ModList);
var
  i:integer;
begin
  agrid.Clear;
  if Length(alist)>0 then
  begin
    agrid.RowCount:=1+Length(alist);
    for i:=0 to High(alist) do
    begin
      FillGridRow(agrid,i+1,alist[i]);
    end;
    agrid.Columns[2].Visible:=fmSettings.cbShowTech.Checked;
  end;
end;

procedure TfmModList.FillInfo(aSGame:TTL2SaveFile);
var
  llist:tModDataArray;
  i:integer;
begin
  FSGame:=aSGame;

  llist:=GetModList;
  cbModList.Clear;
  cbModList.Items.Capacity:=Length(llist);
  for i:=0 to High(llist) do
    cbModList.AddItem(llist[i].title,TObject(IntPtr(i)));

  FillGrid(sgBound ,FSGame.BoundMods);
  FillGrid(sgRecent,FSGame.RecentModHistory);
  FillGrid(sgFull  ,FSGame.FullModHistory);

  CheckButtons;
  SetFilter(FSGame.BoundMods);
  bbUpdate.Enabled:=false;
end;

procedure TfmModList.bbUpdateClick(Sender: TObject);
var
  llist:TTL2ModList;
  ls:string;
  i:integer;
begin
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;

  if sgBound.RowCount=0 then
    FSGame.BoundMods:=nil
  else
  begin
    SetLength(llist,sgBound.RowCount-1);
    for i:=1 to sgBound.RowCount-1 do
    begin
      llist[i-1].version:=StrToInt  (sgBound.Cells[1,i]);
      llist[i-1].id     :=StrToInt64(sgBound.Cells[2,i]);
    end;
    FSGame.BoundMods:=llist;
  end;

  if sgRecent.RowCount=0 then FSGame.RecentModHistory:=nil;
  if sgFull  .RowCount=0 then FSGame.FullModHistory  :=nil;
  bbUpdate.Enabled:=false;
  ShowMessage(rsReminder);
end;

end.
