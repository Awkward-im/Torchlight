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
  unitscan;

resourcestring
  sDoTheScan      = 'Do tree scan?';
  sDoProcessScan  = 'Do you want to scan this directory?';

procedure TfmScan.bbScanClick(Sender: TObject);
begin
  if MessageDlg(sDoTheScan,sDoProcessScan,mtConfirmation,[mbOk,mbCancel],0)<>mrOk then
    exit;
  memLog.Append('Preparing...');
  if not PrepareScan(tvMain.Path) then exit;
  memLog.Append('Ok, prepared!');
  RGLog.Clear;

  // Wardrobe
  memLog.Append('Go wardrobe!');
  ScanWardrobe();
  memLog.Append(RGLog.Text); RGLog.Clear;

  // Pets
  if cbPets.Checked then
  begin
    memLog.Append('Go pets!');
    ScanPets();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Quests
  if cbQuests.Checked then
  begin
    memLog.Append('Go quests!');
    ScanQuests();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Stats
  if cbStats.Checked then
  begin
    memLog.Append('Go stats!');
    ScanStats();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Recipes
  if cbRecipes.Checked then
  begin
    memLog.Append('Go recipes!');
    ScanRecipes();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Mobs
  if cbMobs.Checked then
  begin
    memLog.Append('Go mobs!');
    ScanMobs();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Items
  if cbItems.Checked then
  begin
    memLog.Append('Go items!');
    ScanItems();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Props
  if cbProps.Checked then
  begin
    memLog.Append('Go props!');
    ScanProps();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Skills
  if cbSkills.Checked then
  begin
    memLog.Append('Go skills!');
    ScanSkills();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  // Classes
  if cbClasses.Checked then
  begin
    memLog.Append('Go classes!');
    ScanClasses();
    memLog.Append(RGLog.Text); RGLog.Clear;
  end;

  memLog.Append('Saving...');
  FinishScan;
  RGLog.Clear;
  memLog.Append('Done!');
end;

procedure TfmScan.tvMainDblClick(Sender: TObject);
begin
  bbScanClick(Sender);
end;

end.

