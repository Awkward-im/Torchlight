unit formModList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  Grids, tl2save, tl2types, tl2db;

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
    procedure bbClearClick(Sender: TObject);
    procedure bbUpdateClick(Sender: TObject);
    procedure sbAddClick(Sender: TObject);
    procedure sbDeleteClick(Sender: TObject);
    procedure sbDownClick(Sender: TObject);
    procedure sbUpClick(Sender: TObject);
  private
    FSGame:TTL2SaveFile;

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
  formSettings;

{ TfmModList }

resourcestring
  rsDoClear = 'Are you sure to clear mod list?';

procedure TfmModList.sbUpClick(Sender: TObject);
var
  i:integer;
begin
  for i:=2 to sgBound.RowCount-1 do
  begin
    if sgBound.IsCellSelected[0,i] then
    begin
      sgBound.MoveColRow(false,i,i-1);
      bbUpdate.Enabled:=true;
      break;
    end;
  end;
end;

procedure TfmModList.sbDownClick(Sender: TObject);
var
  i:integer;
begin
  for i:=1 to sgBound.RowCount-2 do
  begin
    if sgBound.IsCellSelected[0,i] then
    begin
      sgBound.MoveColRow(false,i,i+1);
      bbUpdate.Enabled:=true;
      break;
    end;
  end;
end;

procedure TfmModList.sbDeleteClick(Sender: TObject);
var
  i:integer;
begin
  for i:=1 to sgBound.RowCount-1 do
  begin
    if sgBound.IsCellSelected[0,i] then
    begin
      sgBound.DeleteRow(i);
      bbUpdate.Enabled:=true;
      break;
    end;
  end;
end;

procedure TfmModList.bbClearClick(Sender: TObject);
begin
  if MessageDlg(rsDoClear,mtConfirmation,[mbOk,mbCancel],0,mbOk)=mrOk then
  begin
    sgBound .Clear;
    sgRecent.Clear;
    sgFull  .Clear;

    bbUpdate.Enabled:=true;
  end;
end;

procedure TfmModList.sbAddClick(Sender: TObject);
var
  lid:TL2ID;
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
      for i:=1 to sgBound.Rowcount-1 do
      begin
        found:=StrToInt(sgBound.Cells[2,i])=lid;
        if found then break;
      end;
      if not found then
      begin
        sgBound.RowCount:=sgBound.RowCount+1;
        FillGridRow(sgBound,sgBound.RowCount-1,llist[idx]);
      end;
    end;
  end;
end;

procedure TfmModList.FillGridRow(agrid:TStringGrid; arow:integer; const amod:TModData);
begin
  agrid.Cells[0,arow]:=amod.title;
  agrid.Cells[1,arow]:=IntToStr(amod.version);
  if fmSettings.cbIdAsHex.Checked then
    agrid.Cells[2,arow]:='0x'+HexStr(amod.id,16)
  else
    agrid.Cells[2,arow]:=IntToStr(amod.id);
end;

procedure TfmModList.FillGridRow(agrid:TStringGrid; arow:integer; const amod:TTL2Mod);
begin
  agrid.Cells[0,arow]:=GetTL2Mod(amod.id);
  agrid.Cells[1,arow]:=IntToStr(amod.version);
  if fmSettings.cbIdAsHex.Checked then
    agrid.Cells[2,arow]:='0x'+HexStr(amod.id,16)
  else
    agrid.Cells[2,arow]:=IntToStr(amod.id);
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

  bbUpdate.Enabled:=false;
end;

procedure TfmModList.bbUpdateClick(Sender: TObject);
var
  llist:TTL2ModList;
  i:integer;
begin
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
end;

end.
