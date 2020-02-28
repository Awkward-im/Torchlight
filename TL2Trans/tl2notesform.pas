unit TL2NotesForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, Grids;

type

  { TTL2Notes }

  TTL2Notes = class(TForm)
    bbSave: TBitBtn;
    bbCancel: TBitBtn;
    edTitle: TEdit;
    edSearch: TEdit;
    memNote: TMemo;
    pnlEdit: TPanel;
    pnlTop: TPanel;
    sbAdd: TSpeedButton;
    sbDelete: TSpeedButton;
    sbSave: TSpeedButton;
    sbTranslate: TSpeedButton;
    sgNotes: TStringGrid;
    procedure bbCancelClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
    procedure edSearchChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sbAddClick(Sender: TObject);
    procedure sbDeleteClick(Sender: TObject);
    procedure sbSaveClick(Sender: TObject);
    procedure sbTranslateClick(Sender: TObject);
    procedure sgNotesDblClick(Sender: TObject);
  private

  public

  end;

var
  TL2Notes: TTL2Notes=nil;

implementation

{$R *.lfm}

uses
  TL2SettingsForm;

resourcestring
  sTitle = 'Notes';

const
  TL2NotesFile = 'TL2Notes';
  TL2NotesExt  = '.csv';

{ TTL2Notes }

procedure TTL2Notes.sbSaveClick(Sender: TObject);
begin
  try
    sgNotes.SaveToCSVFile(
        TL2NotesFile+'.'+TL2Settings.edTransLang.Text+TL2NotesExt,#9,false);
    Caption:=sTitle;
  except
    exit;
  end;
  sgNotes.Modified:=false;
  sbSave.Enabled:=sgNotes.Modified;
end;

procedure TTL2Notes.sbDeleteClick(Sender: TObject);
begin
  sgNotes.DeleteRow(sgNotes.Row);
  Caption:='* '+sTitle;

  if sgNotes.RowCount=1 then
    sbDelete.Enabled:=false;
end;

procedure TTL2Notes.sbAddClick(Sender: TObject);
begin
  edTitle.Text:='';
  memNote.Text:='';
  pnlEdit.Tag    :=0;
  pnlEdit.Visible:=true;
  edSearch.Enabled:=false;
  sgNotes .Enabled:=false;
  sbAdd   .Enabled:=false;
  sbDelete.Enabled:=false;
end;

procedure TTL2Notes.sgNotesDblClick(Sender: TObject);
var
  i:integer;
begin
  i:=sgNotes.Row;
  edTitle.Text:=sgNotes.Cells[0,i];
  memNote.Text:=sgNotes.Cells[1,i];
  pnlEdit.Tag    :=1;
  pnlEdit.Visible:=true;
  edSearch.Enabled:=false;
  sgNotes .Enabled:=false;
  sbAdd   .Enabled:=false;
  sbDelete.Enabled:=false;
end;

procedure TTL2Notes.bbCancelClick(Sender: TObject);
begin
  pnlEdit.Visible:=false;
  edSearch.Enabled:=true;
  sgNotes .Enabled:=true;
  sbAdd   .Enabled:=true;
  if sgNotes.RowCount>1 then
    sbDelete.Enabled:=true;
  sbSave.Enabled:=sgNotes.Modified;
end;

procedure TTL2Notes.bbSaveClick(Sender: TObject);
var
  i:integer;
begin
  if pnlEdit.Tag=0 then
  begin
    i:=sgNotes.RowCount;
    sgNotes.RowCount:=i+1;
  end
  else
  begin
    i:=sgNotes.Row;
  end;
  sgNotes.Cells[0,i]:=edTitle.Text;
  sgNotes.Cells[1,i]:=memNote.Text;
  sgNotes.SortColRow(true,0);
  Caption:='* '+sTitle;

  bbCancelClick(Sender);
end;

procedure TTL2Notes.sbTranslateClick(Sender: TObject);
begin
  memNote.Text:=TranslateYandex(edTitle.Text);
end;

procedure TTL2Notes.edSearchChange(Sender: TObject);
var
  ls:AnsiString;
  i:integer;
begin
  if (Length(edSearch.Text)<4) and (sgNotes.RowCount>1) then
  begin
    ls:=AnsiLowerCase(edSearch.Text);
    for i:=1 to sgNotes.RowCount-1 do
    begin
      if Pos(ls,AnsiLowerCase(sgNotes.Cells[0,i]))>0 then
      begin
        sgNotes.Row   :=i;
        sgNotes.TopRow:=i;
        exit;
      end;
    end;
  end;
end;

procedure TTL2Notes.FormCreate(Sender: TObject);
begin
  Caption:=sTitle;
  try
    sgNotes.LoadFromCSVFile(
        TL2NotesFile+'.'+TL2Settings.edTransLang.Text+TL2NotesExt,#9,false);
  except
  end;
  bbCancelClick(Sender);
end;

end.

