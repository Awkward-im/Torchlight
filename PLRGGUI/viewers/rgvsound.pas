{}
{TODO: sound file info}
unit rgvSound;

interface

uses
  Forms,
  RGCtrl;


function PreviewSound(var actrl:TRGController; aidx:integer):TForm;


implementation

{$IFDEF Windows}
  {$R bass64.rc}
{$ENDIF}

uses
  Classes,
  Controls,
  Buttons,
  fpc.Dynamic_Bass,
  DMViewer;


resourcestring
  rsPlay     = 'Play';
  rsStop     = 'Stop';
  rsHintPlay = 'Play file';
  rsHintStop = 'Stop playing';

type
  TSoundForm = class(TBaseViewer)
    bbPlay:TBitBtn;
    bbStop:TBitBtn;
    procedure bbPlayClick(Sender: TObject);
    procedure bbStopClick(Sender: TObject);
  private
    FChannel:THandle;
    FBuffer :PByte;
    FSize   :integer;
  public
    destructor Destroy; override;
  end;

procedure PrepareSound;
{$IFDEF Windows}
var
  res:TResourceStream;
{$ENDIF}
{
  f:File Of Byte;
  res:TFPResourceHandle;
  lHandle:THANDLE;
  lptr:PByte;
  lsize:integer;
}
begin
{$IFDEF Windows}
  if not Load_BASSDLL(bassdll) then
  begin
    res:=TResourceStream.Create(hInstance,'BASS','RT_RCDATA');
    try
      res.SaveToFile(bassdll);
    finally
      res.Free;
    end;
(*
    res:=FindResource(hInstance, 'BASS', 'TEXT');
    if res<>0 then
    begin
      lHandle:=LoadResource(hInstance,Res);
      if lHandle<>0 then
      begin
        lptr :=LockResource(lHandle);
        lsize:=SizeOfResource(hInstance,res);

        {$I-}
        AssignFile(f,'bass.dll');
        Rewrite(f);
        if IOResult=0 then
        begin
          BlockWrite(f,lptr^,lsize);
          CloseFile(f);
        end;

        UnlockResource(lHandle);
        FreeResource(lHandle);
      end;
    end;
*)
  end;
{$ENDIF}
  if Load_BASSDLL(bassdll) then
  begin
    {$IFDEF MSWINDOWS}
    BASS_Init(-1, 44100, 0, hInstance, nil);
    {$ELSE}
    BASS_Init(-1, 44100, 0, nil, nil);
    {$ENDIF}
  end;
end;

procedure EndOfSoundPlay(handle: HSYNC; channel, data: DWORD; user: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
begin
  with TSoundForm(user) do
  begin
    FChannel:=0;
    bbPlay.Visible:=true;
    bbStop.Visible:=false;
  end;
end;

destructor TSoundForm.Destroy;
begin
  if FChannel<>0 then bbStopClick(self);
  FreeMem(FBuffer);
  inherited;
end;

procedure TSoundForm.bbPlayClick(Sender: TObject);
begin
  bbPlay.Visible:=false;
  bbStop.Visible:=true;
  FChannel:=BASS_StreamCreateFile(true,FBuffer,0,FSize,BASS_STREAM_AUTOFREE);

  BASS_ChannelSetSync(FChannel,BASS_SYNC_END or BASS_SYNC_ONETIME,0,@EndOfSoundPlay,Self);

  BASS_ChannelPlay(FChannel, false);
end;

procedure TSoundForm.bbStopClick(Sender: TObject);
begin
  BASS_ChannelStop(FChannel);
  FChannel:=0;
  bbPlay.Visible:=true;
  bbStop.Visible:=false;
end;

function PreviewSound(var actrl:TRGController; aidx:integer):TForm;
var
  lbuf:PByte;
  lsize:integer;
begin
  result:=nil;

  if BASS_Handle=0 then PrepareSound;
  if BASS_Handle=0 then exit;
  lbuf:=nil;
  lsize:=actrl.GetBinary(aidx,lbuf);
  if lsize=0 then exit;

  result:=TSoundForm.Create(actrl,aidx);
  with TSoundForm(result) do
  begin
    FBuffer:=lbuf;
    FSize:=lsize;

    bbPlay:=TBitBtn.Create(result);
    with bbPlay do
    begin
  //    SetBounds(8, 8, 72, 26);
      Left       := 8;
      Height     := 26;
      Top        := (pnlInfo.ClientHeight-Height) div 2;
      Top        := 4;
      Width      := 72;
      Caption    := rsPlay;
      Hint       := rsHintPlay;
      Images     := Viewer.ilViewer;
      ImageIndex := iiPlay;
//      Enabled    := BASS_Handle<>0; // always true coz check before
      OnClick    := @bbPlayClick;
      Parent     := pnlInfo;
      Visible    := True;
    end;

    bbStop:=TBitBtn.Create(result);
    with bbStop do
    begin
  //    SetBounds(8, 8, 72, 26);
      Left       := 8;
      Height     := 26;
      Top        := (pnlInfo.ClientHeight-Height) div 2;
      Top        := 4;
      Width      := 72;
      Caption    := rsStop;
      Hint       := rsHintStop;
      Images     := Viewer.ilViewer;
      ImageIndex := iiStop;
//      Enabled    := BASS_Handle<>0; // always true coz check before
      OnClick    := @bbStopClick;
      Visible    := False;
      Parent     := pnlInfo;
    end;
  end;
end;

finalization
  Unload_BASSDLL;

end.
