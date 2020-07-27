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
  unitscan;

resourcestring
  sDoTheScan      = 'Do tree scan?';
  sDoProcessScan  = 'Do you want to scan this directory?';

procedure TfmScan.bbScanClick(Sender: TObject);
begin
  if MessageDlg(sDoTheScan,sDoProcessScan,mtConfirmation,[mbOk,mbCancel],0)<>mrOk then
    exit;
  if not PrepareScan(tvMain.Path) then exit;

  // Pets
  if cbPets.Checked then
  begin
    memLog.Append('Go pets!');
    ScanPets();
  end;

  // Quests
  if cbQuests.Checked then
  begin
    memLog.Append('Go quests!');
    ScanQuests();
  end;

  // Stats
  if cbStats.Checked then
  begin
    memLog.Append('Go stats!');
    ScanStats();
  end;

  // Recipes
  if cbRecipes.Checked then
  begin
    memLog.Append('Go recipes!');
    ScanRecipes();
  end;

  // Mobs
  if cbMobs.Checked then
  begin
    memLog.Append('Go mobs!');
    ScanMobs();
  end;

  // Items
  if cbItems.Checked then
  begin
    memLog.Append('Go items!');
    ScanItems();
  end;

  // Props
  if cbProps.Checked then
  begin
    memLog.Append('Go props!');
    ScanProps();
  end;

  // Skills
  if cbSkills.Checked then
  begin
    memLog.Append('Go skills!');
    ScanSkills();
  end;

  // Classes
  if cbClasses.Checked then
  begin
    memLog.Append('Go classes!');
    ScanClasses();
  end;

  FinishScan;
end;

procedure TfmScan.tvMainDblClick(Sender: TObject);
begin
  bbScanClick(Sender);
end;

end.

