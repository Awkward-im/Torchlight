unit formScanAll;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ShellCtrls, ExtCtrls;

type

  { TfmScan }

  TfmScan = class(TForm)
    bbScan: TBitBtn;

    cbPets   : TCheckBox;
    cbMobs   : TCheckBox;
    cbQuests : TCheckBox;
    cbStats  : TCheckBox;
    cbRecipes: TCheckBox;
    cbItems  : TCheckBox;
    cbProps  : TCheckBox;
    cbSkills : TCheckBox;
    cbClasses: TCheckBox;

    cbUpdateAll: TCheckBox;
    memLog: TMemo;
    pnlMain: TPanel;
    pnlTree: TPanel;
    tvMain: TShellTreeView;
    Splitter: TSplitter;
    procedure bbScanClick(Sender: TObject);
    procedure tvMainDblClick(Sender: TObject);
  private

  public

  end;

var
  fmScan: TfmScan;

implementation

{$R *.lfm}

{ TfmScan }

uses
  rglogging,
  rgscan,
  unitscan;

resourcestring
  sDoTheScan      = 'Do tree scan?';
  sDoProcessScan  = 'Do you want to scan this directory?';

{
function DoCheck(const adir,aname:string; aparam:pointer):integer;
var
  lms:pointer;
begin
  result:=1;

  if (UpCase(ExtractFileExt(aname))='.MOD') or
     (UpCase(ExtractFileExt(aname))='.PAK')
  then
  begin
    Prepare(aparam,adir+'/'+aname,lms);
  end
  else if (UpCase(aname)='MOD.DAT') then
  begin
    Prepare(aparam,adir,lms);
  end
  else
    exit(0);

  if lms<>nil then
  begin
    ScanAll(lms);
    Finish(lms);
  end
  else
    exit(0);

end;
}
procedure TfmScan.bbScanClick(Sender: TObject);
var
  db,lms:pointer;
begin
{
  RGOpenBase(db);
  MakeRGScan(tvMain.Path,'',['.PAK','.MOD','.DAT'],nil,db,@DoCheck);
  RGCloseBase(db);

exit;
}
  if MessageDlg(sDoTheScan,sDoProcessScan,mtConfirmation,[mbOk,mbCancel],0)<>mrOk then
    exit;
  memLog.Append('Preparing...');
  if not Prepare(db,tvMain.Path,lms) then exit;
  memLog.Append('Ok, prepared!');
  RGLog.Clear;

  // Wardrobe
  memLog.Append('Go wardrobe!');
  ScanWardrobe(lms);
  memLog.Append(RGLog.Text); RGLog.Clear;

  // Pets
  if cbPets.Checked then
  begin
    memLog.Append('Go pets!');
    ScanPets(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Quests
  if cbQuests.Checked then
  begin
    memLog.Append('Go quests!');
    ScanQuests(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Stats
  if cbStats.Checked then
  begin
    memLog.Append('Go stats!');
    ScanStats(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Recipes
  if cbRecipes.Checked then
  begin
    memLog.Append('Go recipes!');
    ScanRecipes(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Mobs
  if cbMobs.Checked then
  begin
    memLog.Append('Go mobs!');
    ScanMobs(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Items
  if cbItems.Checked then
  begin
    memLog.Append('Go items!');
    ScanItems(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Props
  if cbProps.Checked then
  begin
    memLog.Append('Go props!');
    ScanProps(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Skills
  if cbSkills.Checked then
  begin
    memLog.Append('Go skills!');
    ScanSkills(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Classes
  if cbClasses.Checked then
  begin
    memLog.Append('Go classes!');
    ScanClasses(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  memLog.Append('Saving...');
  Finish(lms);
  RGLog.Clear;
  memLog.Append('Done!');

end;

procedure TfmScan.tvMainDblClick(Sender: TObject);
begin
  bbScanClick(Sender);
end;

end.

