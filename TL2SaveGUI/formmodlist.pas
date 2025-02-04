{NOTE: save List index in Objects of ListBox coz skip Vanilla}
{NOTE: llist:=RGDBGetModList cached DB data just once in global mod list}
unit formModList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  Grids, ListFilterEdit, ListViewFilterEdit, tlsave, rgglobal, rgdb;

type

  { TfmModList }

  TfmModList = class(TForm)
    bbClear: TBitBtn;
    bbUpdate: TBitBtn;
    cbModList: TComboBox;
    lblChoosedModId: TLabel;
    lbAvailMods: TListBox;
    lfeAvailMods: TListFilterEdit;
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
    procedure lbAvailModsDblClick(Sender: TObject);
    procedure lbAvailModsSelectionChange(Sender: TObject; User: boolean);
    procedure sbClipboardClick(Sender: TObject);
    procedure bbClearClick    (Sender: TObject);
    procedure bbUpdateClick   (Sender: TObject);
    procedure sbAddClick      (Sender: TObject);
    procedure sbDeleteClick   (Sender: TObject);
    procedure sbDownClick     (Sender: TObject);
    procedure sbUpClick       (Sender: TObject);
    procedure sgBoundAfterSelection(Sender: TObject; aCol, aRow: Integer);

  private
    FSGame:TTLSaveFile;

    procedure CheckButtons(doupdate:boolean);
    procedure FillGrid(agrid: TStringGrid; alist: TTL2ModList);
    procedure FillGridRow(agrid: TStringGrid; arow: integer; const amod: TTL2Mod);

  public
    procedure FillInfo(aSGame: TTLSaveFile);

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
  rsMaximum  = 'Can''t add more than 10 mods.';
  rsDoClear  = 'Are you sure to clear mod list?';
  rsReminder = 'Don''t forget to check modded objects.'#13#10+
               'Or use "Fix Modded objects" item from Main menu';

procedure TfmModList.CheckButtons(doupdate:boolean);
begin
  sbDelete   .Enabled:=sgBound.RowCount>1;
  sbUp       .Enabled:=sgBound.Row>1;
  sbDown     .Enabled:=sgBound.Row<sgBound.RowCount-1;
  sbClipboard.Enabled:=sgBound.RowCount>1;

  bbClear.Enabled:=(sgBound.RowCount >1) or
                   (sgRecent.RowCount>1) or
                   (sgFull.RowCount  >1);

  bbUpdate.Enabled:=bbUpdate.Enabled or doupdate;
end;

procedure TfmModList.sgBoundAfterSelection(Sender: TObject; aCol, aRow: Integer);
begin
  CheckButtons(false);
end;

procedure TfmModList.sbUpClick(Sender: TObject);
begin
  sgBound.MoveColRow(false,sgBound.Row,sgBound.Row-1);
  CheckButtons(true);
end;

procedure TfmModList.sbDownClick(Sender: TObject);
begin
  sgBound.MoveColRow(false,sgBound.Row,sgBound.Row+1);
  CheckButtons(true);
end;

procedure TfmModList.sbDeleteClick(Sender: TObject);
begin
  sgBound.DeleteRow(sgBound.Row);
  CheckButtons(true);
end;

procedure TfmModList.bbClearClick(Sender: TObject);
begin
  if MessageDlg(rsDoClear,mtConfirmation,[mbOk,mbCancel],0,mbOk)=mrOk then
  begin
    sgBound .Clear;
    sgRecent.Clear;
    sgFull  .Clear;

    CheckButtons(true);
  end;
end;

procedure TfmModList.sbClipboardClick(Sender: TObject);
var
  ls:string;
  i:integer;
begin
  ls:='';
  for i:=1 to sgBound.RowCount-1 do
    ls:=ls+sgBound.Cells[0,i]+' v.'+sgBound.Cells[1,i]+#13#10;

  Clipboard.asText:=ls;
end;

procedure TfmModList.sbAddClick(Sender: TObject);
var
  lid,gid:TRGID;
  llist:tModDataArray;
  i,idx:integer;
  found:boolean;
begin
  if sgBound.RowCount<11 then
  begin
    idx:=lbAvailMods.ItemIndex;
    if idx>=0 then
    begin
      idx:=IntPtr(lbAvailMods.Items.Objects[idx]);
      llist:=RGDBGetModList;
      lid:=llist[idx].id;
      found:=false;
      for i:=1 to sgBound.RowCount-1 do
      begin
        Val(sgBound.Cells[2,i],gid);
        found:=gid=lid;
        if found then break;
      end;
      if not found then
      begin
        if sgBound.RowCount=0 then
        begin
          i:=1;
          sgBound.RowCount:=2;
        end
        else
        begin
          i:=sgBound.RowCount;
          sgBound.RowCount:=sgBound.RowCount+1;
        end;

        with llist[idx] do
        begin
          sgBound.Cells[0,i]:=title;
          sgBound.Cells[1,i]:=IntToStr(version);
          sgBound.Cells[2,i]:=TextId  (id);
        end;
      end;
    end;
  end
  else
    ShowMessage(rsMaximum);

  CheckButtons(true);
end;

procedure TfmModList.lbAvailModsSelectionChange(Sender: TObject; User: boolean);
var
  llist:tModDataArray;
  idx:integer;
begin
  idx:=lbAvailMods.ItemIndex;
  if idx>=0 then
  begin
    idx:=IntPtr(lbAvailMods.Items.Objects[idx]);
    llist:=RGDBGetModList();
    lblChoosedModId.Caption:=TextId(llist[idx].id)
  end
  else
    lblChoosedModId.Caption:='';
end;

procedure TfmModList.lbAvailModsDblClick(Sender: TObject);
begin
  sbAddClick(Sender);
end;

procedure TfmModList.FillGridRow(agrid:TStringGrid; arow:integer; const amod:TTL2Mod);
begin
  agrid.Cells[0,arow]:=RGDBGetMod(amod.id);
  agrid.Cells[1,arow]:=IntToStr  (amod.version);
  agrid.Cells[2,arow]:=TextId    (amod.id);
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

procedure TfmModList.FillInfo(aSGame:TTLSaveFile);
var
  llist:tModDataArray;
  i:integer;
begin
  FSGame:=aSGame;

  llist:=RGDBGetModList();
  lfeAvailMods.Clear;
  lfeAvailMods.Items.Capacity:=Length(llist);
  for i:=0 to High(llist) do
    with llist[i] do
    begin
      if id<>0 then
        lfeAvailMods.Items.AddObject(title+' v.'+IntToStr(version),TObject(IntPtr(i)));
    end;

  lfeAvailMods.ForceFilter(' ');
  lfeAvailMods.ForceFilter('');

  FillGrid(sgBound ,FSGame.BoundMods);
  FillGrid(sgRecent,FSGame.RecentModHistory);
  FillGrid(sgFull  ,FSGame.FullModHistory);

  CheckButtons(false);

  RGDBSetFilter(FSGame.BoundMods);
  bbUpdate.Enabled:=false;
end;

procedure TfmModList.bbUpdateClick(Sender: TObject);
var
  llist:TTL2ModList;
//  ls:string;
  i:integer;
begin
{
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;
}
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

  RGDBSetFilter(FSGame.BoundMods);

  FSGame.Modified:=true;
  fmSettings.ModListChanged:=true;

  bbUpdate.Enabled:=false;
  ShowMessage(rsReminder);
end;

end.
