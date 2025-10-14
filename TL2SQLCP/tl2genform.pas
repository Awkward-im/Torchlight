unit TL2GenForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls, Buttons,
  rgglobal;

type

  { TGenForm }

  TGenForm = class(TForm)
    bbGenerate: TBitBtn;
    bbClose: TBitBtn;
    cbPartial: TCheckBox;
    cbLanguages: TComboBox;
    lblLanguage: TLabel;
    memStat: TMemo;
    sgMods: TStringGrid;
    procedure bbGenerateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sgModsCheckboxToggled(Sender: TObject; aCol, aRow: Integer; aState: TCheckboxState);
    procedure sgModsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  private
    FModList:TDict64DynArray;
    FLangs:TDictDynArray;
    procedure FillLangList();
    procedure FillModList();

  public

  end;

var
  GenForm: TGenForm;

implementation

{$R *.lfm}

uses
  iso639,
  sqlite3dyn,
  sqlitedb,
  tl2SettingsForm,
  rgdb.text;

{ TGenForm }

procedure TGenForm.bbGenerateClick(Sender: TObject);
var
  ldlg:TSaveDialog;
begin
{
  ldlg:=TSaveDialog.Create(nil);
  try
    ldlg.Title:=rsTransPlace;
    ldlg.FileName:=DefTransFile;
    if ldlg.Execute then
    begin
      if BuildTranslation(ldlg.FileName,
         gdModStat.Cells[2,gdModStat.Row],
    //     gdLanguages.Cells[1,gdLanguages.Row],
         cbPartial.Checked,
         //!! list must be here
         CurMod) then
        ShowMessage(rsBuildDone)
      else
        ShowMessage(rsBuildFailed);
    end;
  finally
    ldlg.Free;
  end;
}
end;

procedure TGenForm.sgModsCheckboxToggled(Sender: TObject; aCol, aRow: Integer; aState: TCheckboxState);
begin

end;

procedure TGenForm.sgModsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin

end;

procedure TGenForm.FillModList();
var
  lstat:TModStatistic;
  i,lcnt,lcnt1:integer;
  ls:AnsiString;
vm:pointer;
begin
  sgMods.BeginUpdate;
  sgMods.Clear;
  GetModList(FModList,false);
  sgMods.RowCount:=1+Length(FModList);

  ls:='SELECT count(distinct s.id)'+
  ' FROM dicMods d'+
  ' LEFT JOIN refs    r ON d.id=r.modid'+
  ' LEFT JOIN strings s ON s.id=r.srcid AND s.deleted=0'+
  ' GROUP BY d.id';
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    i:=0;
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      inc(i);
      sgMods.Cells[0,i]:='0';
      sgMods.Cells[1,i]:=FModList[i-1].value;
      sgMods.Cells[2,i]:=IntToStr(sqlite3_column_int(vm,0));
      sgMods.Objects[0,i]:=TObject(IntPtr(i-1));
    end;
    sqlite3_finalize(vm);
  end;

  ls:='SELECT count(distinct r1.srcid)'+
  ' FROM dicMods d'+
  ' LEFT JOIN refs r1 ON d.id=r1.modid AND NOT EXISTS'+
  '  (SELECT 1 FROM refs r2 WHERE r2.srcid=r1.srcid AND r2.modid<>d.id)'+
  ' GROUP BY d.id';
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    i:=0;
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      inc(i);
      sgMods.Cells[3,i]:=IntToStr(sqlite3_column_int(vm,0));
    end;
    sqlite3_finalize(vm);
  end;
{  
  sgMods.BeginUpdate;
  sgMods.Clear;
  GetModList(FModList,false);
  sgMods.RowCount:=1+Length(FModList);

  for i:=0 to High(FModList) do
  begin
    Str(FModList[i].id,ls);
    lcnt:=GetLineCount(FModList[i].id);
    lcnt1:=GetUniqueLineCount(FModList[i].id);

    sgMods.Cells[0,i+1]:='0';
    sgMods.Cells[1,i+1]:=FModList[i].value;
    sgMods.Cells[2,i+1]:=IntToStr(lcnt);
    sgMods.Cells[3,i+1]:=IntToStr(lcnt1);
    sgMods.Objects[0,i+1]:=TObject(IntPtr(i));
  end;
}
  sgMods.EndUpdate;
  sgMods.Row:=1;
end;

procedure TGenForm.FillLangList();
var
  ls:string;
  i,lcnt,lrow:integer;
begin
  FLangs:=nil;

  cbLanguages.Clear;

  lcnt:=GetLangList(FLangs);
  lrow:=0;
  for i:=0 to lcnt-1 do
  begin
    ls:=FLangs[i].value;
    if ls=TL2Settings.edTransLang.Text then lrow:=i;
    
    cbLanguages.Items.AddObject(
      ls+' '+GetLangName(ls)+' ['+IntToStr(FLangs[i].id)+']',
      TObject(IntPtr(i)));
  end;
  if lcnt>0 then cbLanguages.ItemIndex:=lrow;
end;

procedure TGenForm.FormCreate(Sender: TObject);
begin
  FillModList();
  FillLangList();
end;

end.

