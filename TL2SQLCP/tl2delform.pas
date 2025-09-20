unit TL2DelForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  CheckLst;

type

  { TDelForm }

  TDelForm = class(TForm)
    bbRestore: TBitBtn;
    bbClose: TBitBtn;
    clbLines: TCheckListBox;
    lblHelp: TLabel;
    memDescr: TMemo;
    procedure bbRestoreClick(Sender: TObject);
    procedure clbLinesSelectionChange(Sender: TObject; User: boolean);
    procedure FormCreate(Sender: TObject);
  private
    procedure FillList();

  public

  end;

var
  DelForm: TDelForm;

implementation

{$R *.lfm}

uses
  rgglobal,
  rgdb.text;

resourcestring
  rsNoDeleted = 'Strange, no deleted lines at all.';

{ TDelForm }

procedure TDelForm.clbLinesSelectionChange(Sender: TObject; User: boolean);
var
  larr:array [0..2] of AnsiString;
  ls:AnsiString;
  i,lid,lcnt:integer;
begin
  memDescr.Text:='';

  lid:=IntPtr(clbLines.Items.Objects[clbLines.ItemIndex]);

  lcnt:=GetLineRefList(lid,larr,1);
  if lcnt=0 then
    ls:='No info about this text placement'
  else
  begin
    if lcnt>3 then
      ls:='Exists in '+IntToStr(lcnt)+' mods'
    else
    begin
      ls:='In these mods:';
      for i:=0 to lcnt-1 do
        ls:=ls+' "'+larr[i]+'"';
    end;
    lcnt:=GetLineRefList(lid,larr,2);
    if lcnt=0 then
      ls:=ls+#13#10'No info about this text directories'
    else
    if lcnt>3 then
      ls:=ls+#13#10'Exists in '+IntToStr(lcnt)+' dirs'
    else
    begin
      ls:=ls+#13#10'In these dirs:';
      for i:=0 to lcnt-1 do
        ls:=ls+#13#10+larr[i];
    end;
    lcnt:=GetLineRefList(lid,larr,3);
    if lcnt=0 then
      ls:=ls+#13#10'No info about this text tags'
    else
    if lcnt>3 then
      ls:=ls+#13#10'Exists in '+IntToStr(lcnt)+' tags'
    else
    begin
      ls:=ls+#13#10'With these tags:';
      for i:=0 to lcnt-1 do
        ls:=ls+' "'+larr[i]+'"';
    end;
  end;

  memDescr.Text:=ls;
end;

procedure TDelForm.bbRestoreClick(Sender: TObject);
var
  i:integer;
begin
  for i:=clbLines.Count-1 downto 0 do
    if clbLines.Checked[i] then
    begin
      RestoreOriginal(IntPtr(clbLines.Items.Objects[i]));
      clbLines.Items.Delete(i);
    end;

  bbRestore.Enabled:=clbLines.Count>0;
end;

procedure TDelForm.FillList();
var
  larr:TDictDynArray;
  lcnt,i:integer;
begin
  clbLines.Clear;
//  lcnt:=GetLineCount(modDeleted);
  lcnt:=GetDeletedList(larr);
  if lcnt<=0 then
  begin
    memDescr.Text:=rsNoDeleted;
    bbRestore.Enabled:=false;
  end
  else
  begin
    for i:=0 to lcnt-1 do
    begin
      clbLines.AddItem(larr[i].value,TObject(IntPtr(larr[i].id)));
    end;
    clbLines.ItemIndex:=0;
  end;
end;

procedure TDelForm.FormCreate(Sender: TObject);
begin
  FillList();
end;

end.

