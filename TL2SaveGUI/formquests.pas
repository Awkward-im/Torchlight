unit formQuests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  tlsave;

type

  { TfmQuests }

  TfmQuests = class(TForm)
    btnSaveQuest: TButton;
    sgQuests: TStringGrid;
    procedure btnSaveQuestClick(Sender: TObject);
    procedure sgQuestsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);

  private
    FSGame:TTLSaveFile;

  public
    procedure FillInfo(aSGame:TTLSaveFile);

  end;


implementation

{$R *.lfm}

uses
  formSettings,
  rgdb;

procedure TfmQuests.sgQuestsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  btnSaveQuest.Enabled:=sgQuests.Cells[1,aRow]='0';
end;

procedure TfmQuests.btnSaveQuestClick(Sender: TObject);
var
  f:file of byte;
  ldlg:TSaveDialog;
begin
  ldlg:=TSaveDialog.Create(nil);
  try
    ldlg.FileName  :=sgQuests.Cells[2,sgQuests.Row];
    ldlg.DefaultExt:='.qst';
//      ldlg.Title     :=rsExportData;
    ldlg.Options   :=ldlg.Options+[ofOverwritePrompt];
    if ldlg.Execute then
    begin
      AssignFile(f,ldlg.FileName);
      Rewrite(f);
      if IOResult=0 then
        with FSGame.Quests.QuestsUnDone[IntPtr(sgQuests.Objects[0,sgQuests.Row])] do
        begin
          BlockWrite(f,id,SizeOf(id));
          BlockWrite(f,q1,SizeOf(q1));
          BlockWrite(f,d1,SizeOf(d1));
          BlockWrite(f,d2,SizeOf(d2));
          BlockWrite(f,data^,len);
          CloseFile(f);
        end;
    end;
  finally
    ldlg.Free;
  end;
end;

procedure TfmQuests.FillInfo(aSGame:TTLSaveFile);
var
  lname:string;
  lmod:string;
  i,j:integer;
begin
  FSGame:=aSGame;

  sgQuests.BeginUpdate;
  sgQuests.Clear;

  sgQuests.Columns[4].Visible:=fmSettings.cbShowTech.Checked;
  sgQuests.RowCount:=1;
  j:=1;
  if Length(aSGame.Quests.QuestsDone)>0 then
  begin
    sgQuests.RowCount:=sgQuests.RowCount+Length(aSGame.Quests.QuestsDone);
    for i:=0 to High(aSGame.Quests.QuestsDone) do
    begin
      sgQuests.Cells[0,j]:=RGDBGetQuest(aSGame.Quests.QuestsDone[i],lmod,lname);
      sgQuests.Cells[1,j]:='1';
      sgQuests.Cells[2,j]:=lname;
      sgQuests.Cells[3,j]:=RGDBGetMod(lmod);
      sgQuests.Cells[4,j]:=TextId(aSGame.Quests.QuestsDone[i]);
      inc(j);
    end;
  end;

  if Length(aSGame.Quests.QuestsUnDone)>0 then
  begin
    sgQuests.RowCount:=sgQuests.RowCount+Length(aSGame.Quests.QuestsUnDone);
    for i:=0 to High(aSGame.Quests.QuestsUnDone) do
    begin
      sgQuests.Objects[0,j]:=TObject(IntPtr(i));

      sgQuests.Cells[0,j]:=RGDBGetQuest(aSGame.Quests.QuestsUnDone[i].id,lmod,lname);
      sgQuests.Cells[1,j]:='0';
      sgQuests.Cells[2,j]:=lname;
      sgQuests.Cells[3,j]:=RGDBGetMod(lmod);
      sgQuests.Cells[4,j]:=TextId(aSGame.Quests.QuestsUnDone[i].id);
      inc(j);
    end;
  end;

  sgQuests.EndUpdate;
end;

end.
