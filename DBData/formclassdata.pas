{TODO: choose database at start}
unit formClassData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, ListFilterEdit,
  rgglobal;

type

  { TfmClassData }

  TfmClassData = class(TForm)
    bbGetList: TBitBtn;
    gbGender: TGroupBox;
    gbMode: TGroupBox;
    lblBase: TLabel;
    lblAlt: TLabel;
    lblDescr: TLabel;
    lbMain: TListBox;
    lbAlt: TListBox;
    lfeMain: TListFilterEdit;
    lbBase: TListBox;
    memSecond: TMemo;
    memDescr: TMemo;
    rbByClass: TRadioButton;
    rbByMod: TRadioButton;
    rbNone: TRadioButton;
    rbMale: TRadioButton;
    rbFemale: TRadioButton;
    StatusBar: TStatusBar;
    procedure bbGetListClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lbAltSelectionChange(Sender: TObject; User: boolean);
    procedure lbMainSelectionChange(Sender: TObject; User: boolean);
    procedure GenderClick(Sender: TObject);
    procedure lfeMainAfterFilter(Sender: TObject);
    procedure ListTypeClick(Sender: TObject);
  private
    Fdb:pointer;
    FListMain:TDict64DynArray;
    FListAlt:TDict64DynArray;

    procedure FillBaseInfo(aid:int64);
    procedure FillAltClassList(amodid: int64);
    procedure FillAltModList(aclassid: int64);
    procedure FillClassInfo(aid: int64);
    procedure FillMainModList;
    procedure FillMainClassList;
    procedure FillAltList(aid: int64);
    procedure FillMainList;

  public

  end;

var
  fmClassData: TfmClassData;

implementation

{$R *.lfm}

uses
  sqlite3dyn,
  rgdb,
  sqlitedb;

{ TfmClassData }

{%REGION GUI}
procedure TfmClassData.lfeMainAfterFilter(Sender: TObject);
begin
  if lbMain.Items.Count>0 then lbMain.ItemIndex:=0;
end;

procedure TfmClassData.lbMainSelectionChange(Sender: TObject; User: boolean);
var
  lid:int64;
begin
  if lbMain.ItemIndex<0 then exit;

  lid:=IntPtr(lbMain.Items.Objects[lbMain.ItemIndex]);
  FillAltList(FListMain[lid].id);

  if rbByClass.Checked then FillClassInfo(FListMain[lid].id);

  if rbByClass.Checked and rbNone.Checked then FillBaseInfo(FListMain[lid].id);
end;

procedure TfmClassData.lbAltSelectionChange(Sender: TObject; User: boolean);
var
  lid:int64;
begin
  lid:=IntPtr(lbAlt.Items.Objects[lbAlt.ItemIndex]);
  if rbByMod.Checked then FillClassInfo(FListAlt[lid].id);

  if rbByMod.Checked and rbNone.Checked then FillBaseInfo(FListAlt[lid].id);
end;

procedure TfmClassData.GenderClick(Sender: TObject);
begin
  if rbByMod.Checked then lbMainSelectionChange(Sender, true)
  else FillMainList();
end;

procedure TfmClassData.ListTypeClick(Sender: TObject);
begin
  FillMainList();

  if rbByClass.Checked then
    lblAlt.Caption:='Mods with class'
  else
    lblAlt.Caption:='Classes in mod';
end;

procedure TfmClassData.bbGetListClick(Sender: TObject);
begin
  FillMainList();
end;
{%ENDREGION GUI}

{%REGION Lists}
procedure TfmClassData.FillBaseInfo(aid:int64);
var
  vm:pointer;
  pc:PAnsiChar;
  ls:string;
begin
  lbBase.Items.Clear;

  ls:=RGDBGetClassFile(aid);
  ls:='SELECT title, gender FROM classes c'+
      ' LEFT JOIN dicfiles f ON c.base=f.id'+
      ' WHERE f.file='''+ls+'''';

  if sqlite3_prepare_v2(Fdb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      pc:=sqlite3_column_text(vm,1);
      if pc^='' then ls:=''
      else ls:=' ('+pc+')';
      lbBase.Items.Add(sqlite3_column_text(vm,0)+ls);
    end;
    sqlite3_finalize(vm);
  end;
  if lbBase.Items.Count>0 then
  begin
    lblBase.Visible:=true;
    lbBase .Visible:=true;
  end;
end;

procedure TfmClassData.FillClassInfo(aid:int64);
var
  lid,ldescr,licon,lfile,lbase:string;
  lstr,ldex,lint,lvit:integer;
begin
  ldescr:=RGDBGetClassInfo(aid,licon,lstr,ldex,lint,lvit);
  lfile:=RGDBGetClassFile(aid,false);
  lbase:=RGDBGetClassFile(aid,true);

  memDescr.Text:=ldescr;
  Str(aid,lid);
  memSecond.Text:=Format('str: %d; dex: %d; int: %d; vit: %d',[lstr,ldex,lint,lvit])+#13#10+
    'file: '+lfile+#13#10+
    'base: '+lbase+#13#10+
    'ID: '+lid;
end;

procedure TfmClassData.FillAltList(aid:int64);
var
  i:integer;
begin
  lblBase.Visible:=false;
  lbBase .Visible:=false;

  lbAlt.Items.Clear;

  SetLength(FListAlt,0);
  if Fdb=nil then exit;

  if rbByClass.Checked then
  begin
    FillAltModList(aid);
  end
  else
  begin
    FillAltClassList(aid);
  end;

  for i:=0 to High(FListAlt) do
  begin
    lbAlt.Items.AddObject(FListAlt[i].value,TObject(IntPtr(i)));
  end;

  if lbAlt.Items.Count>0 then
    lbAlt.ItemIndex:=0;
end;

procedure TfmClassData.FillAltModList(aclassid:int64);
var
  vm:pointer;
  lmods:TInt64DynArray;
  ls:string;
  i:integer;
begin
  SetLength(FListAlt,0);
  Str(aclassid,ls);
  ls:=ReturnText(Fdb,'SELECT modid FROM classes WHERE id='+ls);
  lmods:=splitInt64(ls,' ');
  for i:=0 to High(lmods) do
  begin
    Str(lmods[i],ls);
    ls:='SELECT id, title FROM mods WHERE id='+ls;
    if sqlite3_prepare_v2(Fdb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
    begin
      SetLength(FListAlt,Length(lmods));
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        FListAlt[i].id   :=sqlite3_column_int64(vm,0);
        FListAlt[i].value:=sqlite3_column_text (vm,1);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure TfmClassData.FillAltClassList(amodid:int64);
var
  vm:pointer;
  ls,lgender,ltitle:string;
  i:integer;
begin
  SetLength(FListAlt,0);
  Str(amodid,ls);

       if rbMale  .Checked then begin lgender:='M'; ltitle:=' AND title<>''''' end
  else if rbFemale.checked then begin lgender:='F'; ltitle:=' AND title<>''''' end
  else                          begin lgender:='' ; ltitle:='' end;
  i:=ReturnInt(Fdb,'SELECT count(id) FROM classes'+
    ' WHERE instr(modid,'' ''+'+ls+'+'' '')>0'+
    ltitle+' AND (gender='''+lgender+''')');

  if i>0 then
  begin
    ls:='SELECT id,title,name FROM classes'+
        ' WHERE instr(modid,'' ''+'+ls+'+'' '')>0'+
        ltitle+
        ' AND (gender='''+lgender+''')'+
        ' ORDER BY title';
    if sqlite3_prepare_v2(Fdb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
    begin
      SetLength(FListAlt,i);
      i:=0;
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        FListAlt[i].id   :=sqlite3_column_int64(vm,0);
        FListAlt[i].value:=sqlite3_column_text (vm,1);
        if FListAlt[i].value='' then
          FListAlt[i].value:='['+sqlite3_column_text(vm,2)+']';
        inc(i);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure TfmClassData.FillMainModList;
var
  vm:pointer;
  ls:string;
  i:integer;
begin
  i:=ReturnInt(Fdb,
      'SELECT count(distinct mods.id) FROM mods INNER JOIN classes'+
      ' ON instr(classes.modid,'' ''+mods.id+'' '')>0');
  if i>0 then
  begin
    ls:='SELECT distinct mods.id, mods.title FROM mods INNER JOIN classes'+
        ' ON instr(classes.modid,'' ''+mods.id+'' '')>0 ORDER BY mods.title';

    if sqlite3_prepare_v2(Fdb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
    begin
      SetLength(FListMain,i);
      i:=0;
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        FListMain[i].id   :=sqlite3_column_int64(vm,0);
        FListMain[i].value:=sqlite3_column_text (vm,1);
        inc(i);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure TfmClassData.FillMainClassList;
var
  vm:pointer;
  ls,lgender,ltitle:string;
  i:integer;
begin
       if rbMale  .Checked then begin lgender:='M'; ltitle:=' title<>''''' end
  else if rbFemale.checked then begin lgender:='F'; ltitle:=' title<>''''' end
  else                          begin lgender:='' ; ltitle:='1=1' end;
  i:=ReturnInt(Fdb,'SELECT count(id) FROM classes'+
     ' WHERE '+ltitle+' AND (gender='''+lgender+''')');

  if i>0 then
  begin
    ls:='SELECT id,title,name FROM classes'+
       ' WHERE '+ltitle+' AND (gender='''+lgender+''')'+
       ' ORDER BY title';
    if sqlite3_prepare_v2(Fdb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
    begin
      SetLength(FListMain,i);
      i:=0;
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        FListMain[i].id   :=sqlite3_column_int64(vm,0);
        FListMain[i].value:=sqlite3_column_text (vm,1);
        if FListMain[i].value='' then
          FListMain[i].value:='['+sqlite3_column_text(vm,2)+']';
        inc(i);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure TfmClassData.FillMainList;
var
  i:integer;
begin
  lblBase.Visible:=false;
  lbBase .Visible:=false;

  lfeMain.FilteredListBox:=nil;
  lfeMain.Clear;

  lbMain.Items.Clear;
  SetLength(FListMain,0);

  if Fdb<>nil then
  begin
    if rbByClass.Checked then
    begin
      FillMainClassList();
    end
    else
    begin
      FillMainModList();
    end;

    for i:=0 to High(FListMain) do
    begin
      lbMain.Items.AddObject(FListMain[i].value,TObject(IntPtr(i)));
    end;
  end;
  StatusBar.SimpleText:='Total: '+IntToStr(Length(FListMain))+' records';

  lfeMain.FilteredListBox:=lbMain;
  lfeMain.SortData:=true;
  if lbMain.Items.Count>0 then
    lbMain.ItemIndex:=0;
end;
{%ENDREGION Lists}

procedure TfmClassData.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FreeBase(Fdb);
end;

procedure TfmClassData.FormCreate(Sender: TObject);
begin
//  gbMode  .Enabled:=false;
//  gbGender.Enabled:=false;
  bbGetList.Visible:=false;
  if LoadBase(Fdb,TL2DataBase)=SQLITE_OK then
    RGDBUseBase(Fdb);
  rbByMod .Checked:=true;
  rbFemale.Checked:=true;
end;

end.

