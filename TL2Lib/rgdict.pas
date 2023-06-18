{TODO: export as UTF8 binary (UCS16LE right now) - add sign for type: UCS16, UTF8, w/zero}
unit RGDict;

interface

uses
  Dict;

type
  TRGDict = object(THashDict)
  public
    type
      TExportDictType = (asTags, asText, asBin, asZBin{, asBin8, asZBin8});
    function  Import(aptr: PByte): integer;
    function  Import(const fname:AnsiString=''):integer;
    function  Import(const resname:string; restype:PChar):integer;
    procedure Export(const fname:AnsiString;
          afmt:TExportDictType=asTags; sortbyhash:boolean=true);

    procedure Init(usecache:boolean=true);
  end;

function DictLoadTranslation(var aDict:TTransDict; aptr:PByte):integer;
function DictLoadTranslation(var aDict:TTransDict; const fname:AnsiString):integer;

var
  RGTags:TRGDict;


implementation

{.$R dicttag.rc}    // Less size and easier to edit
{.$R dicttagbin.rc} // Faster load

uses
  logging,
  rgglobal;

resourcestring
  resCantOpen = 'Can''t open ';
  resCantLoad = 'Can''t load ';

const
  defdictname = 'dictionary.txt';
  deftagsname = 'tags.dat';

const
  SIGN_UNICODE = $FEFF;
  SIGN_UTF8    = $BFBBEF;


procedure TRGDict.Init(usecache:boolean=true);
begin
  inherited Init(@RGHash,usecache);
end;


//----- Load -----

//--- binary (like DAT files)

{ in: raw data
  4 bytes  = count of next blocks
  4 bytes  = hash
  2 bytes  = length (chars, with or without #0)
  length*2 = text
}
function DictLoadBinary(var aDict:THashDict; aptr:PByte):integer;
var
  pcw:PWideChar;
  i,llen,lsize:integer;
  lhash:dword;
begin
  result:=pInt32(aptr)^; inc(aptr,SizeOf(Int32));
  aDict.Capacity:=result;

  lsize:=0;
  pcw  :=nil;

  for i:=0 to result-1 do
  begin
    lhash:=pUInt32(aptr)^; inc(aptr,SizeOf(UInt32));
    llen:=PWord(aptr)^; inc(aptr,2);

{
  1 - len of text, no zero
  2 - len of text, zero
  3 - len of text with zero
}
    if llen=0 then
    begin
      aDict.Add(nil,lhash);
    end
    // how to recognize case 2 if next field have hash=0?
    // else if PWideChar(aptr)[llen]=#0 then
    //
    // for case 3
    else if PWideChar(aptr)[llen-1]=#0 then
    begin
      pcw:=PWideChar(aptr);
      aDict.Add(pcw,lhash);
      inc(aptr,llen*2);
      pcw:=nil;
    end
    else // needs for case 1 only
    begin
      if (llen+1)>lsize then
      begin
        if lsize=0 then
        begin
          lsize:=4096;
          GetMem(pcw,lsize*SizeOf(WideChar));
        end
        else
        begin
          lsize:=Align(llen+1,16);
          ReallocMem(pcw,lsize*SizeOf(WideChar));
        end;
      end;
      move(aptr^,pByte(pcw)^,llen*SizeOf(WideChar)); inc(aptr,llen*SizeOf(WideChar));
      pcw[llen]:=#0;
      aDict.Add(pcw,lhash);
    end;
  end;
  FreeMem(pcw);
end;

//--- Tags.dat

{ in: UTF16-LE text in next format
  [Tags]
    <STRING>:text
    <INTEGER>:hash
  	...
  [/Tags]
}

const
  sString  = '<STRING>:';
  sInteger = '<INTEGER>:';

function DictLoadTags(var aDict:THashDict; aptr:PByte):integer;
var
  pcw,lsrc,lstart,lend:PWideChar;
  ltmp:integer;
  lhash:dword;
  lsign:boolean;
begin
  result:=0;

  lend:=pointer(aptr);
  if (pword(lend)^=SIGN_UNICODE) then inc(lend);

  repeat
    if (lend^=#0) then break;

    lstart:=lend;
    while not (lend^ in [#0, #10, #13]) do inc(lend);

    if lend^<>#0 then
    begin
      lend^:=#0;
      inc(lend);
    end;
    
    while (lend^ in [#10, #13]) do inc(lend);

    if lstart^='[' then
    begin
      if lstart[1]='/' then
        break
      else
        continue;
    end;

    if lstart^<>#0 then
    begin

      pcw:=PosWide(sString,lstart);
      if pcw<>nil then
      begin
        lsrc:=pcw+Length(sString);
      end
      else
      begin
        pcw:=PosWide(sInteger,lstart);
        if pcw<>nil then
        begin
          pcw:=pcw+Length(sInteger);
          if pcw^='-' then
          begin
            inc(pcw);
            lsign:=true;
          end
          else
            lsign:=false;

          ltmp:=0;
          while pcw^ in ['0'..'9'] do
          begin
            ltmp:=ltmp*10+ORD(pcw^)-ORD('0');
            inc(pcw);
          end;
          if lsign then
            lhash:=dword(-integer(ltmp))
          else
            lhash:=ltmp;
          aDict.Add(lsrc, lhash);
        end;
      end;

    end;
  until false;

end;

//--- dictionary.txt

{ in: UTF8 text in next format
  hash<1-char separator>text
}
function DictLoadDictionary(var aDict:THashDict; aptr:PByte):integer;
var
  lptr,lend:PAnsiChar;
  llen,lcnt,lstart,i,p:integer;
  ltmp:cardinal;
  lhash:dword;
begin
  result:=0;

  lcnt:=0;
  lptr:=PAnsiChar(aptr);
  while lptr^<>#0 do
  begin
    if lptr^=#13 then inc(lcnt);
    inc(lptr);
  end;
  aDict.Capacity:=lcnt;
  
  lend:=PAnsiChar(aptr);
  try
    for i:=0 to lcnt-1 do
    begin
      lptr:=lend;
      while not (lend^ in [#0,#13]) do inc(lend);
      llen:=lend-lptr;
      while lend^ in [#1..#32] do inc(lend);

      if llen>0 then
      begin
        if lptr^='-' then
          lstart:=1
        else
          lstart:=0;

        ltmp:=0;
        for p:=lstart to llen-1 do
        begin
          if (lptr[p] in ['0'..'9']) then
            ltmp:=(ltmp)*10+ORD(lptr[p])-ORD('0')
          else
          begin
            if lstart>0 then
              lhash:=dword(-integer(ltmp))
            else
              lhash:=ltmp;
            aDict.Add(Copy(lptr,p+1+1,llen-p-1), lhash); //!!
            inc(result);
            break;
          end;
        end;
      end;

      if lend^=#0 then break;
    end;

  except
    if lcnt>0 then RGLog.Add('Possible problem with '+copy(lptr,1,lcnt));
    aDict.Clear;
  end;
end;

//--- raw text
{ in: UTF8 text
  just text, line by line
}
function DictLoadList(var aDict:THashDict; aptr:PByte):integer;
var
  ls:AnsiString;
  lptr,lend:PByte;
  lcnt,i:integer;
begin
  result:=0;

  lcnt:=0;
  lptr:=aptr;
  while lptr^<>0 do
  begin
    if lptr^=13 then inc(lcnt);
    inc(lptr);
  end;
  aDict.Capacity:=lcnt;
  
  lend:=aptr;
  for i:=0 to lcnt-1 do
  begin
    lptr:=lend;
    while not lend^ in [0,13] do inc(lend);
    SetString(ls, PansiChar(lptr), lend-lptr);
    while lend^ in [1..32] do inc(lend);

    if ls<>'' then
    begin
      aDict.Add(ls, RGHash(pointer(ls),Length(ls))); //!! RGHash not necessary if used in adict.init
      inc(result);
    end;

    if lend^=0 then break;
  end;
end;


function TRGDict.Import(aptr:PByte):integer;
begin
  if (pword(aptr)^=SIGN_UNICODE) and (aptr[2]=ORD('[')) then
  begin
    result:=DictLoadTags(self,aptr)
  end

  else if aptr[3]=0 then
  begin
    result:=DictLoadBinary(self,aptr)
  end

  else if (CHAR(aptr[0]) in ['-','0'..'9']) or
      (((pdword(aptr)^ and $FFFFFF)=SIGN_UTF8) and
       ((CHAR(aptr[3]) in ['-','0'..'9']))) then
  begin
    result:=DictLoadDictionary(self,aptr);
  end

  else
  begin
    result:=DictLoadList(self,aptr);
  end;

  if result>0 then SortBy(0); //!!
end;

function TRGDict.Import(const resname:string; restype:PChar):integer;
var
  res:TFPResourceHandle;
  Handle:THANDLE;
//  lstrm: TResourceStream;
  lptr,buf:PByte;
  lsize,loldcount:integer;
begin
  result:=0;
  loldcount:=Count;

  res:=FindResource(hInstance, PChar(resname), restype);
  if res<>0 then
  begin
    Handle:=LoadResource(hInstance,Res);
    if Handle<>0 then
    begin
      lptr :=LockResource(Handle);
      lsize:=SizeOfResource(hInstance,res);

      GetMem(buf,lsize+2);
      move(lptr^,buf^,lsize);

      UnlockResource(Handle);
      FreeResource(Handle);

      buf[lsize  ]:=0;
      buf[lsize+1]:=0;

      result:=Import(buf);

      FreeMem(buf);
    end;
  end;
{
  lstrm:=TResourceStream.Create(HINSTANCE,resname, restype);
  try
    result:=Import(lstrm.Memory);
  finally
    lstrm.Free;
  end;
}
  if result=0 then
    RGLog.Add(resCantLoad+resname);

  result:=Count-loldcount;
end;

function TRGDict.Import(const fname:AnsiString=''):integer;
var
  f:file of byte;
  buf:PByte;
  ls:AnsiString;
  i,loldcount:integer;
begin
  result:=0;
  loldcount:=Count;
  
  // 1 - trying to open dict file (empty name = load defaults)
  if fname<>'' then
    ls:=fname
  else
    ls:=defdictname;
{$PUSH}
{$I-}
  Assign(f,ls);
  Reset(f);
  if IOResult<>0 then
  begin
    if fname='' then
    begin
      ls:=deftagsname;
      Assign(f,ls);
      Reset(f);
      if IOResult<>0 then
      begin
        if fname='' then
          ls:='default tags file'
        else
          ls:='tag info file "'+fname+'"';
        RGLog.Add(resCantOpen+ls);
        exit;
      end;
    end
    else
    begin
      RGLog.Add(resCantOpen+ls);
      exit;
    end;
  end;
  i:=FileSize(f);
  GetMem(buf,i+2);
  BlockRead(f,buf^,i);
  Close(f);
{$POP}

  buf[i  ]:=0;
  buf[i+1]:=0;

  result:=Import(buf);

  FreeMem(buf);

  if result=0 then
    RGLog.Add(resCantLoad+fname);

  result:=Count-loldcount;
end;


procedure TRGDict.Export(const fname:AnsiString;
    afmt:TExportDictType=asTags; sortbyhash:boolean=true);
var
  i:integer;
  slb:TBaseLog;
  sl:TLog;
  slw:TLogWide;
//  lnode:pointer;
  lstr:UnicodeString;
  llen:cardinal;
  ldelta:integer;
begin
  case afmt of
    asTags: begin
      slw.Init;

//      if sortbyhash then aDict.SortBy(0) else aDict.SortBy(1); //!!

      slw.Add('[TAGS]');
      for i:=0 to Count-1 do
      begin
        slw.Add('  <STRING>:'+Tags[i]);
        Str(Integer(Hashes[i]),lstr);
        slw.Add('  <INTEGER>:'+lstr);
      end;
      slw.Add('[/TAGS]');

      slw.SaveToFile(fname);
      slw.Free;
    end;

    asText: begin
      sl.Init;

      if sortbyhash then SortBy(0) else SortBy(1); //!!

      for i:=0 to Count-1 do
      begin
        Str(Hashes[i],lstr);
        sl.Add(UTF8Encode(lstr+':'+(Tags[i])));
      end;

      sl.SaveToFile(fname);
      sl.Free;
    end;

    asBin, asZBin: begin
      slb.Init;

      if afmt=asZBin then ldelta:=1 else ldelta:=0;

      slb.AddValue(Count,4);

      if sortbyhash then SortBy(0) else SortBy(1); //!!

      for i:=0 to Count-1 do
      begin
        slb.AddValue(Hashes[i],4);
        if Tags[i]=nil then
          slb.AddValue(0,2)
        else
        begin
          llen:=Length(Tags[i])+ldelta;
          slb.AddValue(llen,2);
          slb.AddData (Tags[i],llen*SizeOf(WideChar));
        end;
      end;

      slb.SaveToFile(fname);
      slb.Free;
    end;
  end;
end;

resourcestring
  sNoFileStart     = 'No file starting tag';
  sNoBlockStart    = 'No block start';
  sNoOrignText     = 'No original text';
  sNoTransText     = 'No translated text';
  sNoEndBlock      = 'No end of block';
  sMoreOriginal    = 'More than one original';
  sMoreTranslation = 'More than one translation';

const
  // TRANSLATION.DAT
  sBeginFile   = '[TRANSLATIONS]';
  sEndFile     = '[/TRANSLATIONS]';
  sBeginBlock  = '[TRANSLATION]';
  sEndBlock    = '[/TRANSLATION]';
  sOriginal    = '<STRING>ORIGINAL:';
  sTranslation = '<STRING>TRANSLATION:';


function DictLoadTranslation(var aDict:TTransDict ; aptr:PByte):integer;
var
  lstart,lend:PWideChar;
  s,lsrc,ldst:PWideChar;
  lline:integer;
  stage:integer;
begin
  lsrc:='';
  ldst:='';

  lline:=0;
  stage:=1;
  lend:=pointer(aptr);

  if (pword(lend)^=SIGN_UNICODE) then inc(lend);

  repeat
    if lend^=#0 then break;

    lstart:=lend;
    while not (lend^ in [#0, #10, #13]) do inc(lend);

    if lend^<>#0 then
    begin
      lend^:=#0;
      inc(lend);
    end;
    
    while lend^ in [#10, #13] do inc(lend);

    if lstart^<>#0 then
    begin
      case stage of
        // <STRING>ORIGINAL:
        // <STRING>TRANSLATION:
        // [/TRANSLATION]
        3: begin
          if lsrc=nil then
          begin
            s:=PosWide(sOriginal,lstart);
            if s<>nil then
            begin
              lsrc:=s+Length(sOriginal);
              continue;
            end;
          end
          else
            RGLog.Add('',lline,sMoreOriginal);

          if ldst=nil then
          begin
            s:=PosWide(sTranslation,lstart);
            if s<>nil then
            begin
              ldst:=s+Length(sTranslation);
              continue;
            end;
          end
          else
            RGLog.Add('',lline,sMoreTranslation);

          if PosWide(sEndBlock,lstart)<>nil then
          begin
            stage:=2;

            if lsrc<>nil then
            begin
              result:=0;

              aDict.Add(lsrc,ldst);
            end
            else// if lsrc='' then
            begin
              RGLog.Add('',lline,sNoOrignText);
              result:=-3;
            end;

          end
          // really, can be custom tag
          else
          begin
            RGLog.Add('',lline,sNoEndBlock);
            result:=-5;
          end;

        end;

        // [TRANSLATION] and [/TRANSLATIONS]
        2: begin
          if PosWide(sBeginBlock,lstart)<>nil then
          begin
            stage:=3;
            lsrc:=nil;
            ldst:=nil;
          end
          else if PosWide(sEndFile,lstart)<>nil then break // end of file
          else
          begin
            RGLog.Add('',lline,sNoBlockStart);
            result:=-2;
          end;
        end;

        // [TRANSLATIONS]
        1: begin
          if PosWide(sBeginFile,lstart)<>nil then
            stage:=2
          else
          begin
            RGLog.Add('',lline,sNoFileStart);
            result:=-1;
            break;
          end;
        end;
      end;
    end;
  until false;

end;

function DictLoadTranslation(var aDict:TTransDict; const fname:AnsiString):integer;
var
  f:file of byte;
  buf:PByte;
  i:integer;
begin
  result:=0;

  if fname='' then exit;

  Assign(f,fname);
  Reset(f);
  if IOResult<>0 then
  begin
    RGLog.Add(resCantOpen+fname);
    exit;
  end;

  i:=FileSize(f);
  GetMem(buf,i+SizeOf(WideChar));
  BlockRead(f,buf^,i);
  Close(f);
  PByte(buf)[i  ]:=0;
  PByte(buf)[i+1]:=0;

  result:=DictLoadTranslation(aDict,buf);

  FreeMem(buf);
end;

initialization

  RGTags.Init();
//  RGTags.Import('RGDICT','TEXT');


finalization

  RGTags.Clear;

end.
