{TODO: Show "STRING/TRANSLATE" flag}
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
    bbDelete: TBitBtn;
    clbLines: TCheckListBox;
    memDescr: TMemo;
    procedure bbDeleteClick(Sender: TObject);
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
  rsNoDeleted  = 'Strange, no deleted lines at all.';
  rsOKToDelete = 'Are you sure to delete totally selected lines from base?';

{ TDelForm }

procedure TDelForm.clbLinesSelectionChange(Sender: TObject; User: boolean);
var
  larr:array [0..2] of AnsiString;
  ls:AnsiString;
  i,lid,lcnt:integer;
  lflags:cardinal;
begin
  memDescr.Text:='';

  lid:=IntPtr(clbLines.Items.Objects[clbLines.ItemIndex]);

  lcnt:=GetLineRefList(lid,larr,1);
  if lcnt=0 then
    ls:='No info about this text placement'
  else
  begin
    lflags:=GetLineFlags(lid,'');
    if (lflags and rfIsTranslate)<>0 then
      ls:='Exists as Translate somethere'#13#10
    else
      ls:='Exists as String type only'#13#10;

    if lcnt>3 then
      ls:=ls+'Exists in '+IntToStr(lcnt)+' mods'
    else
    begin
      ls:=ls+'In these mods:';
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
  bbDelete .Enabled:=clbLines.Count>0;
end;

procedure TDelForm.bbDeleteClick(Sender: TObject);
var
  i:integer;
begin
  if  MessageDlg(rsOKToDelete,mtWarning,mbYesNoCancel,0,mbCancel)=mrYes then
  begin
    for i:=clbLines.Count-1 downto 0 do
      if clbLines.Checked[i] then
      begin
        RemoveOriginal(IntPtr(clbLines.Items.Objects[i]));
        clbLines.Items.Delete(i);
      end;
    bbRestore.Enabled:=clbLines.Count>0;
    bbDelete .Enabled:=clbLines.Count>0;
  end;
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
    bbDelete .Enabled:=false;
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

