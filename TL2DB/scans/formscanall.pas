unit formScanAll;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ShellCtrls, ExtCtrls, EditBtn;

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
    edDirName: TDirectoryEdit;
    edFileName: TFileNameEdit;
    gbWhatToScan: TGroupBox;
    memLog: TMemo;
    pnlMain: TPanel;
    rbDirToScan: TRadioButton;
    rbFileToScan: TRadioButton;
    Splitter: TSplitter;
    procedure bbScanClick(Sender: TObject);
    procedure cbUpdateAllChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rbDirToScanChange(Sender: TObject);
    procedure rbFileToScanChange(Sender: TObject);
  private

  public

  end;

var
  fmScan: TfmScan;

implementation

{$R *.lfm}

{ TfmScan }

uses
  rgglobal,
  rglogging,
  unitscan;

procedure TfmScan.bbScanClick(Sender: TObject);
var
  db,lms:pointer;
begin
  RGLog.Clear;
  memLog.Append('Preparing...');

  if not RGOpenBase(db) then
  begin
    memLog.Append('Can''t prepare database');
    exit;
  end;

  if rbDirToScan.Checked then
  begin
    if not Prepare(db,edDirName.Text,lms) then exit;
    memLog.Append('Scanning '+edDirName.Text);
  end
  else // if rbFileToScan then
  begin
    if not Prepare(db,edFileName.Text,lms) then exit;
    memLog.Append('Scanning '+edFileName.Text);
  end;

  memLog.Append('Ok, prepared!');

  if cbUpdateAll.Checked then
  begin
    memLog.Append('Scanning all');
    ScanAll(lms);

  end
  else
  begin
{
    // Wardrobe
    memLog.Append('Go wardrobe!');
    ScanWardrobe(lms);
    memLog.Append(RGLog.Text); RGLog.Clear;
}
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
  end;

  memLog.Append('Saving...');
  Finish(lms);
  RGLog.Clear;

  if not RGCloseBase(db) then
    memLog.Append('Error while save database');
  memLog.Append('Done!');
end;

procedure TfmScan.cbUpdateAllChange(Sender: TObject);
begin
  cbPets   .Enabled:=not cbUpdateAll.Checked;
  cbQuests .Enabled:=not cbUpdateAll.Checked;
  cbStats  .Enabled:=not cbUpdateAll.Checked;
  cbRecipes.Enabled:=not cbUpdateAll.Checked;
  cbMobs   .Enabled:=not cbUpdateAll.Checked;
  cbItems  .Enabled:=not cbUpdateAll.Checked;
  cbProps  .Enabled:=not cbUpdateAll.Checked;
  cbSkills .Enabled:=not cbUpdateAll.Checked;
  cbClasses.Enabled:=not cbUpdateAll.Checked;
end;

procedure TfmScan.FormCreate(Sender: TObject);
begin
  if not FileExists(TL2DataBase) then
    ShowMessage('Database file not found.'#13#10+
    'Better to use base game file scan first.');
end;

procedure TfmScan.rbDirToScanChange(Sender: TObject);
begin
  edFileName.Enabled:=false;
  edDirName .Enabled:=true;
end;

procedure TfmScan.rbFileToScanChange(Sender: TObject);
begin
  edDirName .Enabled:=false;
  edFileName.Enabled:=true;
end;

end.

