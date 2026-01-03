{}
{TODO: modified flag}
unit rgvLayout;

interface

uses
  Forms,
  rgctrl;

function PreviewLayout(var actrl:TRGController; aidx:integer):TForm;


implementation

uses
  Controls,
  Buttons,
  rgglobal,
  rgio.Text,
  fmLayoutEdit,
  DMViewer;

resourcestring
  rsSave = 'Save changes';

type
  TLayViewer = class(TBaseViewer)
    sbSave:TSpeedButton;
    procedure DoSave(Sender:TObject);
  private
    FEdit:TFormLayoutEdit;
  end;

procedure TLayViewer.DoSave(Sender:TObject);
var
  lbuf:PByte;
  pc:PWideChar;
  lsize:integer;
begin
  lbuf:=nil;
  lsize:=FEdit.GetFile(lbuf,Ctrl^.PAK.Version);
  if lsize>0 then
  begin
    pc:=ConcatWide(Ctrl^.PathOfFile(Idx),Ctrl^.Files[Idx]^.Name);
    Ctrl^.AddUpdate(lbuf,lsize,pc);
    FreeMem(pc);
    FreeMem(lbuf);

    if NodeToWide(FEdit.Root,pc) then
    begin
      PRGCtrlInfo(Ctrl^.Files[Idx])^.size:=Length(pc);
      FreeMem(pc);
    end;
  end;
end;

function PreviewLayout(var actrl:TRGController; aidx:integer):TForm;
var
  lbuf:PByte;
  lsize:integer;
begin
  lbuf:=nil;
  lsize:=actrl.GetBinary(aidx,lbuf);
  if lsize>0 then
  begin
    result:=TLayViewer.Create(actrl,aidx);

    with TLayViewer(result) do
    begin
      sbSave:=TSpeedButton.Create(result);
      with sbSave do
      begin
        Left       :=4;
        Top        :=4;
//        SetBounds(4,4,32,30);
        ShowCaption:=False;
        Images     :=Viewer.ilViewer;
        ImageIndex :=iiSave;
        Hint       :=rsSave;
        ShowHint   :=True;
        OnClick    :=@DoSave;
        Parent     :=pnlInfo;
      end;

      FEdit:=TFormLayoutEdit.Create(result);
      FEdit.SynEdit.PopupMenu:=Viewer.SynPopupMenu;
      FEdit.SynEdit.Font.Assign(Viewer.Font);

      FEdit.BuildTree(lbuf,actrl.PAK.Version);

      FEdit.Align  :=alClient;
      FEdit.Parent :=result;
      FEdit.Visible:=True;

      FreeMem(lbuf);
    end;
  end
  else
    result:=nil;
end;

end.
