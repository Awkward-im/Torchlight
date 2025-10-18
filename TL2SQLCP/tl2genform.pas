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
    bbToggle: TBitBtn;
    btnGenerate: TButton;
    cbPartial: TCheckBox;
    cbLanguages: TComboBox;
    cbAll: TCheckBox;
    lblLanguage: TLabel;
    memStat: TMemo;
    sgMods: TStringGrid;
    procedure bbGenerateClick(Sender: TObject);
    procedure bbToggleClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure cbLanguagesSelect(Sender: TObject);
    procedure UpdateStatistic(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sgModsCheckboxToggled(Sender: TObject; aCol, aRow: Integer; aState: TCheckboxState);
    procedure sgModsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FModList:TDict64DynArray;
    FLangs:TDictDynArray;
    FSelected:Int64;

    procedure FillLangList();
    procedure FillModList();
    // Set FSelected to FModList Index
    function  GetSelCount():integer;
    procedure CacheModId();
  public

  end;

var
  GenForm: TGenForm;

implementation

{$R *.lfm}

uses
  LCLType,
  iso639,
  sqlite3dyn,
  sqlitedb,
  tl2SettingsForm,
  rgdb.text;

resourcestring
  rsTransPlace     = 'Choose file to save translation data';
  rsNothingToBuild = 'Nothing to build. Check at least one mod';
  rsNoLanguage     = 'Choose language first';
  rsGenCaption     = 'Just'#13#10'Build'#13#10'All';
  rsBuildDone      = 'Translation file generated';
  rsBuildFailed    = 'Translation file is NOT generated';
  rsTotal          = 'Total mods';
  rsModsSelected   = 'Selected';
  rsLineCount      = 'Line count';
  rsNothing        = 'Nothing selected';
  rsTranslated     = 'Translated';
  rsPartially      = 'Partially';
  rsVanilla        = 'You choosed base game translation.'#13#10'It will include unreferred info too.';

{ TGenForm }

function TGenForm.GetSelCount():integer;
var
  i:integer;
begin
  result:=0;
  for i:=1 to sgMods.RowCount-1 do
    if sgMods.Cells[0,i]='1' then
    begin
      inc(result);
      FSelected:=FModList[IntPtr(sgMods.Objects[0,i])].id;
    end;
end;

procedure TGenForm.CacheModId();
var
  ls,lmod:AnsiString;
  i:integer;
begin
  ls:='';
  for i:=1 to sgMods.RowCount-1 do
    if sgMods.Cells[0,i]='1' then
    begin
      Str(FModList[IntPtr(sgMods.Objects[0,i])].id,lmod);
      if ls='' then ls:='(' else ls:=ls+',(';
      ls:=ls+lmod+')';
    end;

  ExecuteDirect(tldb,'DROP TABLE tmpmods');
  ExecuteDirect(tldb,'CREATE TEMP TABLE tmpmods (id INTEGER PRIMARY KEY)');
  if ls<>'' then
  begin
    ls:='INSERT INTO tmpmods VALUES '+ls;
    ExecuteDirect(tldb,ls);
  end;
end;

procedure TGenForm.UpdateStatistic(Sender:TObject);
var
  vm:pointer;
  ls,lmem:AnsiString;
  lcnt,i:integer;
begin
  // 1 - mods
  lmem:=rsTotal+': '+IntToStr(Length(FModList)); // sgMods.RowCount-1
  lcnt:=GetSelCount();
  lmem:=lmem+#13#10+rsModsSelected+': '+IntToStr(lcnt);

  // 2 - lines
  if lcnt=0 then
  begin
    lmem:=lmem+#13#10#13#10+rsNothing;
  end
  else
  begin
         if lcnt=Length(FModList) then begin i:=GetLineCount(modAll   ); CacheSrcId(modAll   ) end
    else if lcnt>1                then begin i:=GetLineCount(modList  ); CacheSrcId(modList  ) end
    else                               begin i:=GetLineCount(FSelected); CacheSrcId(FSelected) end;
    lmem:=lmem+#13#10+rsLineCount+':'+IntToStr(i);

    // 3 - translated
    ls:='SELECT count(t.srcid), sum(t.part)'+
        ' FROM [trans_'+FLangs[cbLanguages.ItemIndex].value+
        '] t INNER JOIN tmpref ON t.srcid=tmpref.srcid';
    if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        i   :=sqlite3_column_int(vm,0);
        lcnt:=sqlite3_column_int(vm,1);
      end;
      sqlite3_finalize(vm);
    end;
    lmem:=lmem+#13#10+rsTranslated+': '+IntToStr(i);
    lmem:=lmem+#13#10+rsPartially +': '+IntToStr(lcnt);
  end;

  memStat.Text:=lmem;
end;

procedure TGenForm.bbGenerateClick(Sender: TObject);
var
  ldlg:TSaveDialog;
  lcnt,i:integer;
  lcode:Int64;
begin
  if cbLanguages.ItemIndex<0 then
  begin
    ShowMessage(rsNoLanguage);
    exit;
  end;

  lcnt:=0;
  for i:=1 to sgMods.RowCount-1 do
    if sgMods.Cells[0,i]='1' then
    begin
      inc(lcnt);
      lcode:=i;
    end;

       if lcnt=Length(FModList) then lcode:=modAll
  else if lcnt=1                then lcode:=FModList[IntPtr(sgMods.Objects[0,lcode])].id
  else if lcnt>0                then lcode:=modList
  else
  begin
    ShowMessage(rsNothingToBuild);
    exit;
  end;
  
  ldlg:=TSaveDialog.Create(nil);
  try
    ldlg.Title:=rsTransPlace;
    ldlg.FileName:=DefTransFile;
    ldlg.DefaultExt:='.DAT';
    ldlg.Filter:='DAT files|*.DAT|All Files|*.*';
    if ldlg.Execute then
    begin

//      if lcode=modList    then CacheModId();
      if lcode=modVanilla then ShowMessage(rsVanilla);

      if BuildTranslation(ldlg.FileName,
         FLangs[cbLanguages.ItemIndex].value,
         cbPartial.Checked,
         cbAll.Checked,
         lcode) then
        ShowMessage(rsBuildDone)
      else
        ShowMessage(rsBuildFailed);
    end;
  finally
    ldlg.Free;
  end;

end;

procedure TGenForm.btnGenerateClick(Sender: TObject);
var
  ldlg:TSaveDialog;
begin
  if cbLanguages.ItemIndex<0 then
  begin
    ShowMessage(rsNoLanguage);
    exit;
  end;
  ldlg:=TSaveDialog.Create(nil);
  try
    ldlg.Title:=rsTransPlace;
    ldlg.FileName:=DefTransFile;
    if ldlg.Execute then
    begin
      if BuildTranslation(ldlg.FileName,
         FLangs[cbLanguages.ItemIndex].value,
         cbPartial.Checked,
         cbAll.Checked,
         modAll) then
        ShowMessage(rsBuildDone)
      else
        ShowMessage(rsBuildFailed);
    end;
  finally
    ldlg.Free;
  end;
end;

procedure TGenForm.cbLanguagesSelect(Sender: TObject);
begin
  UpdateStatistic(Sender);
end;

procedure TGenForm.bbToggleClick(Sender: TObject);
var
  lcnt,i:integer;
begin
  lcnt:=0;
  for i:=1 to sgMods.RowCount-1 do
    if sgMods.Cells[0,i]='1' then
      inc(lcnt);

  sgMods.BeginUpdate;
  if lcnt=(sgMods.RowCount-1) then //Length(FModList)
  begin
    for i:=1 to sgMods.RowCount-1 do
      sgMods.Cells[0,i]:='0';
  end
  else
    for i:=1 to sgMods.RowCount-1 do
      sgMods.Cells[0,i]:='1';
  sgMods.EndUpdate;

  CacheModId();
  UpdateStatistic(Sender);
end;

procedure TGenForm.sgModsCheckboxToggled(Sender: TObject; aCol, aRow: Integer; aState: TCheckboxState);
begin
  CacheModId();
  UpdateStatistic(Sender);
end;

procedure TGenForm.sgModsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  i:integer;
begin
  if Key = VK_SPACE then
  begin
    for i:=1 to sgMods.RowCount-1 do
    begin
      if sgMods.IsCellSelected[sgMods.Col,i] then
      begin
        sgMods.Cells[0,i]:=BoolNumber[sgMods.Cells[0,i]='0'];
      end;
    end;
    Key:=0;

    CacheModId();
    UpdateStatistic(Sender);
  end;
end;

procedure TGenForm.FillModList();
var
//  lstat:TModStatistic;
//  lcnt,lcnt1:integer;
  ls:AnsiString;
  vm:pointer;
  i:integer;
begin
  sgMods.BeginUpdate;
  sgMods.Clear;
  GetModList(FModList,false);
  sgMods.RowCount:=1+Length(FModList);

  ls:='WITH'+
      ' UniqueRefs AS (SELECT DISTINCT srcid,modid FROM refs)'+
      'SELECT count(distinct s.id)'+
      ' FROM dicMods d'+
      ' JOIN UniqueRefs r ON d.id=r.modid'+
      ' JOIN strings    s ON s.id=r.srcid AND s.deleted=0'+
      ' GROUP BY d.id';
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    i:=0;
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      inc(i);
      sgMods.Cells[0,i]:='1';
      sgMods.Cells[1,i]:=FModList[i-1].value;
      sgMods.Cells[2,i]:=IntToStr(sqlite3_column_int(vm,0));
      sgMods.Objects[0,i]:=TObject(IntPtr(i-1));
    end;
    sqlite3_finalize(vm);
  end;

  ls:='WITH'+
    ' UniqueRefs AS (SELECT DISTINCT srcid,modid FROM refs),'+
    ' SingleSrc  AS (SELECT srcid FROM UniqueRefs GROUP BY srcid HAVING COUNT(1) = 1),'+
    ' Counts     AS ('+
    '   SELECT r.modid, COUNT(1) AS cnt'+
    '     FROM  SingleSrc s'+
    '     JOIN UniqueRefs r ON r.srcid = s.srcid'+
    '     GROUP BY r.modid)'+
    'SELECT c.cnt'+
    ' FROM dicmods m  LEFT JOIN Counts c ON c.modid = m.id';
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
uprof.Start('count');
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
uprof.stop;
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
  UpdateStatistic(Sender);
  btnGenerate.Caption:=rsGenCaption;
end;

end.

