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
    ltitle: AnsiString;

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
  if lid<0 then
    ls:='Unique, after mod deleting'
  else
  begin
    lcnt:=GetLineRefList(lid,larr,lrMod);
    if lcnt=0 then
      ls:='No info about this text placement'
    else
    begin
      ls:='';

      lflags:=GetLineFlags(lid,'');
      if (lflags and rfIsTranslate)<>0 then
        ls:=ls+'Exists as Translate somethere'#13#10
      else
        ls:=ls+'Exists as String type only'#13#10;

  {$IFDEF DEBUG}
      ls:=ls+'DB id is '+IntToStr(lid)+#13#10;
  {$ENDIF}

      if lcnt>3 then
        ls:=ls+'Exists in '+IntToStr(lcnt)+' mods'
      else
      begin
        ls:=ls+'In these mods:';
        for i:=0 to lcnt-1 do
          ls:=ls+' "'+larr[i]+'"';
      end;

      lcnt:=GetLineRefList(lid,larr,lrDir);
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

      lcnt:=GetLineRefList(lid,larr,lrFile);
      if lcnt=0 then
        ls:=ls+#13#10'No info about this text files'
      else
      if lcnt>3 then
        ls:=ls+#13#10'Exists in '+IntToStr(lcnt)+' files'
      else
      begin
        ls:=ls+#13#10'In these files:';
        for i:=0 to lcnt-1 do
          ls:=ls+#13#10+larr[i];
      end;

      lcnt:=GetLineRefList(lid,larr,lrTag);
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
  end;

  memDescr.Text:=ls;
end;

procedure TDelForm.bbRestoreClick(Sender: TObject);
var
  lcnt,lcnt1,i,lid:integer;
begin
  lcnt :=0;
  lcnt1:=0;
  for i:=clbLines.Count-1 downto 0 do
  begin
    lid:=IntPtr(clbLines.Items.Objects[i]);
    if clbLines.Checked[i] then
    begin
      if lid<0 then
        ShowMessage('Line is unique, can''t be restored')
      else
      begin
        RestoreOriginal(IntPtr(clbLines.Items.Objects[i]));
        clbLines.Items.Delete(i);
      end;
    end
    else
    begin
      if lid>0 then inc(lcnt) else inc(lcnt1);
    end;
  end;

  bbRestore.Enabled:=clbLines.Count>0;
  bbDelete .Enabled:=clbLines.Count>0;
  Caption:=ltitle+' ['+IntToStr(lcnt)+'/'+IntToStr(lcnt1)+']';
end;

procedure TDelForm.bbDeleteClick(Sender: TObject);
var
  lcnt,lcnt1,i,lid:integer;
begin
  if  MessageDlg(rsOKToDelete,mtWarning,mbYesNoCancel,0,mbCancel)=mrYes then
  begin
    lcnt :=0;
    lcnt1:=0;
    for i:=clbLines.Count-1 downto 0 do
    begin
      lid:=IntPtr(clbLines.Items.Objects[i]);
      if clbLines.Checked[i] then
      begin
        RemoveOriginal(ABS(lid));
        clbLines.Items.Delete(i);
      end
      else
      begin
        if lid>0 then inc(lcnt) else inc(lcnt1);
      end;
    end;
    bbRestore.Enabled:=clbLines.Count>0;
    bbDelete .Enabled:=clbLines.Count>0;
    Caption:=ltitle+' ['+IntToStr(lcnt)+'/'+IntToStr(lcnt1)+']';
  end;
end;

procedure TDelForm.FillList();
var
  larr1,larr:TDictDynArray;
  lcnt1,lcnt,i:integer;
begin
  clbLines.Clear;
//  lcnt:=GetLineCount(modDeleted);
  lcnt :=GetDeletedList(larr);
  lcnt1:=GetDeletedList(larr1,true);
  if (lcnt1+lcnt)<=0 then
  begin
    memDescr.Text:=rsNoDeleted;
    bbRestore.Enabled:=false;
    bbDelete .Enabled:=false;
  end
  else
  begin
    Caption:=ltitle+' ['+IntToStr(lcnt)+'/'+IntToStr(lcnt1)+']';
    for i:=0 to lcnt -1 do clbLines.AddItem(larr [i].value,TObject(IntPtr( larr [i].id)));
    for i:=0 to lcnt1-1 do clbLines.AddItem(larr1[i].value,TObject(IntPtr(-larr1[i].id)));

    clbLines.ItemIndex:=0;
  end;
end;

procedure TDelForm.FormCreate(Sender: TObject);
begin
  ltitle:=Caption;

  FillList();
end;

end.

