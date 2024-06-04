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
    cbDetailedLog: TCheckBox;
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
    db:pointer;

    function  AddToLog(var adata:string):integer;
    procedure ProcessSingleMod(const aname: string);

  public

  end;

var
  fmScan: TfmScan;

implementation

{$R *.lfm}

{ TfmScan }

uses
  logging,
  rgglobal,
  rgscan,
  unitscan;

function TfmScan.AddToLog(var adata:string):integer;
begin
  memLog.Append(adata);
  adata:='';
  result:=0;
end;

procedure TfmScan.ProcessSingleMod(const aname:string);
var
  lms:pointer;
  lloglvl:integer;
begin
  if cbDetailedLog.Checked then
    lloglvl:=10
  else
    lloglvl:=1;

  if not Prepare(db,aname,lms,lloglvl) then
  begin
    memLog.Append('Can''t prepare "'+aname+'" scanning');
    exit;
  end;

  if cbUpdateAll.Checked then
  begin
    memLog.Append('Scanning all');
    ScanAll(lms);
  end
  else
  begin
{
    // Wardrobe
    ScanWardrobe(lms);
}
    // Pets
    if cbPets.Checked then
    begin
      ScanPets(lms);
      Application.ProcessMessages;
    end;

    // Quests
    if cbQuests.Checked then
    begin
      ScanQuests(lms);
      Application.ProcessMessages;
    end;

    // Stats
    if cbStats.Checked then
    begin
      ScanStats(lms);
      Application.ProcessMessages;
    end;

    // Recipes
    if cbRecipes.Checked then
    begin
      ScanRecipes(lms);
      Application.ProcessMessages;
    end;

    // Mobs
    if cbMobs.Checked then
    begin
      ScanMobs(lms);
      Application.ProcessMessages;
    end;

    // Items
    if cbItems.Checked then
    begin
      ScanItems(lms);
      Application.ProcessMessages;
    end;

    // Props
    if cbProps.Checked then
    begin
      ScanProps(lms);
      Application.ProcessMessages;
    end;

    // Skills
    if cbSkills.Checked then
    begin
      ScanSkills(lms);
      Application.ProcessMessages;
    end;

    // Classes
    if cbClasses.Checked then
    begin
      ScanClasses(lms);
      Application.ProcessMessages;
    end;
  end;

  Finish(lms);
end;

function DoCheck(const adir,aname:string; aparam:pointer):integer;
var
  lext:string;
begin
  result:=1;
  lext:=UpCase(ExtractFileExt(aname));
  if (lext='.MOD') or
     (lext='.PAK') then
  begin
    with TfmScan(aparam) do
      ProcessSingleMod(edDirName.Text+'\'+adir+'\'+aname);
  end
  else if (UpCase(aname)='MOD.DAT') then
  begin
    with TfmScan(aparam) do
      if (adir='\') or (adir='/') then
        ProcessSingleMod(edDirName.Text)
      else
        ProcessSingleMod(edDirName.Text+'\'+adir);
  end
  else
    exit(0);
end;

procedure TfmScan.bbScanClick(Sender: TObject);
begin
  memLog.Append('Preparing...');

  if not RGOpenBase(db,TL2DataBase) then
  begin
    memLog.Append('Can''t prepare database');
    exit;
  end;

  if rbDirToScan.Checked then
  begin
    MakeRGScan(edDirName.Text,'',['.PAK','.MOD','.DAT'],nil,Self,@DoCheck);
  end
  else //if rbFileToScan then
    ProcessSingleMod(edFileName.Text);

  memLog.Append('Saving...');

  if not RGCloseBase(db,TL2DataBase) then
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

  cbUpdateAllChange(cbUpdateAll);

  RGLog.OnAdd:=@AddToLog;
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

