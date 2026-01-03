{}
{TODO: modified flag}
{TODO: need to unify sources initial loading and reload}
unit rgvText;

interface

uses
  Forms,
  RGCtrl;


function PreviewText  (var actrl:TRGController; aidx:integer):TForm;
function PreviewSource(var actrl:TRGController; aidx:integer):TForm;

function PreviewSkeleton(var actrl:TRGController; aidx:integer):TForm;


implementation

uses
  Controls,
  Buttons,
  Dialogs,
  SynEdit,
  SynEditMouseCmds,
  SynGutterCodeFolding,
  SynEditTypes,
  SynHighlighterXML,
  SynHighlighterOgre,
  SynHighlighterT,

  RGSkeleton,
  
  RGGlobal,
  RGFile,
  DMViewer;


resourcestring
  rsUnknownEncoding = 'Unknown source encoding';
  rsSave   = 'Save changes';
  rsFind   = 'Find/Replace info';
  rsReload = 'Reload content';

type
  TEditForm = class(TBaseViewer)
    sbSave  :TSpeedButton;
    sbFind  :TSpeedButton;
    sbReload:TSpeedButton;
    SynEdit:TSynEdit;
    ReplaceDialog: TReplaceDialog;

    procedure DoSave  (Sender:TObject);
    procedure DoReload(Sender:TObject);
    procedure DoFind  (Sender:TObject);
    procedure ReplaceExecute(Sender:TObject);
  private
    srcenc:integer;  

    procedure DoSkeleton(Sender:TObject);
  end;

procedure TEditForm.DoSave(Sender:TObject);
var
  lbuf:PByte;
  pc:PWideChar;
  lpc:PAnsiChar;
  lsize:integer;
begin
  if SynEdit.Highlighter=Viewer.SynTSyn then
    lsize:=CompileFile(PByte(PChar(SynEdit.Text)),Ctrl^.Files[Idx]^.Name,lbuf,Ctrl^.PAK.Version)
  else
  begin
    if srcenc=2 then
    begin
      lsize:=2+Length(SynEdit.Text)*2;
      GetMem(lbuf,lsize+2);
      PWord(lbuf)^:=SIGN_UNICODE;
      pc:=StrToWide(SynEdit.Text);
      move(pc^,(lbuf+2)^,lsize-2);
      FreeMem(pc);
      lbuf[lsize  ]:=0;
      lbuf[lsize+1]:=0;
    end
    else // skip UTF8 check
    begin
      lsize:=3+Length(SynEdit.Text);
      GetMem(lbuf,lsize+1);
      PDword(lbuf)^:=SIGN_UTF8;
      lpc:=PAnsiChar(SynEdit.Text);
      move(lpc^,(lbuf+3)^,lsize-3);
      lbuf[lsize]:=0;
    end;
  end;

  if lsize>0 then
  begin
    pc:=ConcatWide(Ctrl^.PathOfFile(Idx),Ctrl^.Files[Idx]^.Name);
    Ctrl^.AddUpdate(lbuf,lsize,pc);
    FreeMem(pc);
    FreeMem(lbuf);

    PRGCtrlInfo(Ctrl^.Files[Idx])^.size:=Length(SynEdit.Text);
  end;
end;

procedure TEditForm.ReplaceExecute(Sender:TObject);
var
  lopt:TSynSearchOptions;
//  lcnt:integer;
begin
//  lcnt:=0;
  with ReplaceDialog do
  begin
    lopt := [];
    if frReplace    in Options then lopt:=[ssoReplace];
    if frReplaceAll in Options then lopt:=[ssoReplaceAll];
    {lcnt:=}SynEdit.SearchReplace{Ex}(FindText, ReplaceText, lopt{, Position});
{
    if lcnt>=0 then
    begin
    //   if lcnt>1 then ShowMessage('Replaces = '+IntToStr(lcnt));
      SynEdit.SetFocus()
    end
    else
      Beep();
}
  end;
end;

procedure TEditForm.DoFind(Sender:TObject);
begin
  ReplaceDialog.Execute();
end;

procedure TEditForm.DoReload(Sender:TObject);
var
  lbuf:PByte;
  ltext:AnsiString;
  pc:PWideChar;
  lpc:PAnsiChar;
  lsize:integer;
begin
  lbuf:=nil;
  lsize:=Ctrl^.GetSource(Idx,lbuf);

  ltext:='';
  // Check for Unicode
  if lsize>=2 then
  begin
    pc:=PWideChar(lbuf);
    if ORD(pc^)=SIGN_UNICODE then
    begin
      inc(pc);
      dec(lsize,2);
    end;
    if (pc<>PWideChar(lbuf)) or (((lsize and 1)=0) and (ORD(pc^)<256)) then
      ltext:=WideToStr(pc,lsize div 2);
    if ltext<>'' then srcenc:=2;
  end;
  // Check for Ansi/UTF8
  if ltext='' then
  begin
    lpc:=PAnsiChar(lbuf);
    if (lsize>3) and ((PDword(lbuf)^ and $00FFFFFF)=SIGN_UTF8) then
    begin
      inc(lpc,3);
      dec(lsize,3);
    end;
    SetString(ltext,lpc,lsize);
    if ltext<>'' then srcenc:=1;
  end;
  FreeMem(lbuf);

  SynEdit.Text:=ltext;
end;

function MakeEditForm(var actrl:TRGController; aidx:integer):TForm;
begin
  result:=TEditForm.Create(actrl,aidx);
  with TEditForm(result) do
  begin
    sbSave:=TSpeedButton.Create(result);
    with sbSave do
    begin
      Left:=4;
      Top :=4;
//        SetBounds(4,4,32,30);
      ShowCaption:=False;
      Images     :=Viewer.ilViewer;
      ImageIndex :=iiSave;
      Hint       :=rsSave;
      ShowHint   :=True;
      OnClick    :=@DoSave;
      Parent     :=pnlInfo;
    end;

    ReplaceDialog:=TReplaceDialog.Create(result);
    with Replacedialog do
    begin
      Options  :=[frDown, frFindNext, frReplace, frReplaceAll, frHidePromptOnReplace];
//      Options  :=[frDown, frFindNext, frReplace, frReplaceAll, frHidePromptOnReplace];
      OnFind   :=@ReplaceExecute;
      OnReplace:=@ReplaceExecute;
    end;

    sbFind:=TSpeedButton.Create(result);
    with sbFind do
    begin
      Left:=sbSave.Left+sbSave.Width+4;
      Top :=4;
//        SetBounds(4,4,32,30);
      ShowCaption:=False;
      Images     :=Viewer.ilViewer;
      ImageIndex :=iiFind;
      Hint       :=rsFind;
      ShowHint   :=True;
      OnClick    :=@DoFind;
      Parent     :=pnlInfo;
    end;

    sbReload:=TSpeedButton.Create(result);
    with sbReload do
    begin
      Left:=sbFind.Left+sbFind.Width+4;
      Top :=4;
//        SetBounds(4,4,32,30);
      ShowCaption:=False;
      Images     :=Viewer.ilViewer;
      ImageIndex :=iiReload;
      Hint       :=rsReload;
      ShowHint   :=True;
      OnClick    :=@DoReload;
      Parent     :=pnlInfo;
    end;

    SynEdit:=TSynEdit.Create(result);
//!!    SynEdit.Highlighter:=SynTSyn;
    SynEdit.BookmarkOptions.BookmarkImages:=Viewer.ilBookmarks;
    SynEdit.MouseOptions:=[emCtrlWheelZoom];
    SynEdit.TabWidth :=2;
    SynEdit.PopupMenu:=Viewer.SynPopupMenu;
    SynEdit.Align    :=alClient;
    SynEdit.Parent   :=result;
    SynEdit.Font.Assign(Viewer.Font);
  {
    for i:=0 to SynTSyn.FoldConfigCount-1 do
      SynTSyn.FoldConfig[i].Modes:=SynTSyn.FoldConfig[i].Modes+[fmOutline];
   }
  end;
end;

function PreviewText(var actrl:TRGController; aidx:integer):TForm;
begin
  result:=MakeEditForm(actrl,aidx);
  with TEditForm(result) do
  begin
    if Viewer.SynOgreSyn=nil then Viewer.SynOgreSyn:=TSynOgreSyn.Create(Viewer);

    if Viewer.SynOgreSyn.CheckType(ExtractExt(FastWideToStr(actrl.Files[aidx]^.Name))) then
      SynEdit.Highlighter:=Viewer.SynOgreSyn
    else
      SynEdit.Highlighter:=Viewer.SynXMLSyn;

    DoReload(sbReload);
  end;
end;

function PreviewSource(var actrl:TRGController; aidx:integer):TForm;
var
  lbuf:PByte;
  pc :PWideChar;
  lpc:PAnsiChar;
  ltext:string;
  lsize:integer;
//  i:integer;
begin
  lbuf:=nil;
  lsize:=actrl.GetSource(aidx,lbuf);
  if lsize=0 then exit(nil);

  result:=MakeEditForm(actrl,aidx);

  if Viewer.SynTSyn=nil then Viewer.SynTSyn:=TSynTSyn.Create(Viewer);

  with TEditForm(result) do
  begin
    SynEdit.Highlighter:=Viewer.SynTSyn;
     case GetSourceEncoding(lbuf) of
      tofSrcUTF8: begin
        lpc:=PAnsiChar(lbuf);
        if (PDword(lbuf)^ and $00FFFFFF)=SIGN_UTF8 then
        begin
          inc(lpc,3);
          dec(lsize,3);
        end;
        SetString(ltext,lpc,lsize);
        SynEdit.Text:=ltext;
      end;

      tofSrcWide: begin
        pc:=PWideChar(lbuf);
        if ORD(pc^)=SIGN_UNICODE then
        begin
          inc(pc);
          dec(lsize,2);
        end;
        SynEdit.Text:=WideToStr(pc,lsize div 2);
      end;

    else
      SynEdit.Text:=rsUnknownEncoding;
    end;

    SynEdit.Modified:=false;
  end;
  FreeMem(lbuf);
end;


procedure TEditForm.DoSkeleton(Sender:TObject);
var
  lbuf:PByte;
  lsize:integer;
  sk:TRGSkeleton;
begin
  lbuf:=nil;
  lsize:=Ctrl^.GetAsIs(Idx,lbuf);

  sk.Init;
  sk.ImportFromMemory(lbuf,lsize);
  SynEdit.Text:=sk.SaveToXML();
  sk.Free;
  FreeMem(lbuf);
end;

function PreviewSkeleton(var actrl:TRGController; aidx:integer):TForm;
begin
  result:=MakeEditForm(actrl,aidx);
  with TEditForm(result) do
  begin
    sbSave.Enabled:=false;
    if Viewer.SynOgreSyn=nil then Viewer.SynOgreSyn:=TSynOgreSyn.Create(Viewer);
    SynEdit.Highlighter:=Viewer.SynXMLSyn;

    sbReload.OnClick:=@DoSkeleton;
    DoSkeleton(sbReload);
  end;
end;

end.
