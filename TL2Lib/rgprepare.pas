{
  Unit for any preparations: scan dir/files for constants mainly
}
unit RGPrepare;

interface

uses
  RGCtrl;

procedure PrepareFeatureTags();
procedure PrepareFeatureTags(const adir:string);
procedure PrepareFeatureTags(actrl:PRGController);


implementation

uses
  SysUtils,
  RGGlobal,
  LayList,
  RGIO.Text,
  RGIO.Dat,
  RGNode;

procedure ProcessHie(anode:pointer);
var
  p1,p2:pointer;
  i:integer;
begin
  // Clear, force rebuild
  if FeatureTags<>nil then
  begin
    for i:=0 to High(FeatureTags) do
      FreeMem(FeatureTags[i].name);
    SetLength(FeatureTags,0);
  end;
  
  if anode<>nil then
  begin
    // Skip CONFIG, get UNITTYPES
    p1:=GetChild(anode,1);
    SetLength(FeatureTags,GetChildCount(p1));
    for i:=0 to GetChildCount(p1)-1 do
    begin
      p2:=GetChild(p1,i);
      with FeatureTags[i] do
      begin
        id  :=AsInteger(FindNode(p2,'ID'));
        name:=CopyWide (FindNode(p2,'NAME'));
      end;
    end;
  end
  else
  begin
    SetLength(FeatureTags,Length(DefFeatureTags));
    for i:=0 to High(DefFeatureTags) do
    begin
      with FeatureTags[i] do
      begin
        id  :=DefFeatureTags[i].id;
        name:=CopyWide(DefFeatureTags[i].name);
      end;
    end;
  end;
end;

procedure ProcessName(const aname:PUnicodeChar);
var
  lcnt,i,j,id:integer;
begin
  if (aname[0]='I') and (aname[1]='D') then
  begin
    // cut ID and NAME
    id:=0;
    i:=2;
    while aname[i] in ['0'..'9'] do
    begin
      id:=id*10+ORD(aname[i])-ORD('0');
      inc(i);
    end;
    if aname[i]='_' then inc(i);
    j:=i+1;
    while (j<Length(aname)) and (aname[j]<>'.') do inc(j);
    if id>0 then
    begin
      // search and overwrite existing
      for lcnt:=0 to High(FeatureTags) do
      begin
        if FeatureTags[lcnt].id=id then
        begin
//          if CompareWide(FeatureTags[i].name,aname+i,j-1)<>0 then
          begin
            FreeMem(FeatureTags[lcnt].name);
            FeatureTags[lcnt].name:=CopyWide(aname+i,j-1);
          end;
          id:=-1;
          break;
        end;
      end;
      // add non-existing
      if id>0 then
      begin
        lcnt:=Length(FeatureTags);
        SetLength(FeatureTags,lcnt+1);
        FeatureTags[lcnt].id  :=id;
        FeatureTags[lcnt].name:=CopyWide(aname+i,j-1);
      end;
    end;
  end;
end;

{
  scan MEDIA/FEATURETAGS for files with name like ID###_NAME
  get ID and NAME from filename
  if doubling (.DAT and .DAT.BINDAT) just overwrite existing
}
procedure ScanForFTags(const adir:string);
var
  sr:TUnicodeSearchRec;
  ls:UnicodeString;
  i:integer;
begin
  SetLength(ls,Length(adir));
  for i:=1 to  Length(adir) do ls[i]:=WideChar(ord(adir[i]));

  if FindFirst(ls+'MEDIA/FEATURETAGS/*.*',faAnyFile,sr)=0 then
  begin
    repeat
      ProcessName(pointer({UpCase}((sr.Name))));
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

procedure PrepareFeatureTags(const adir:string);
var
  ldir:string;
  p:pointer;
begin
  ldir:=adir;
  if (ldir<>'') and (ldir[Length(ldir)]<>'/') and (ldir[Length(ldir)]<>'\') then ldir:=ldir+'/';

                p:=ParseTextFile(PChar(ldir+'MEDIA/FEATURETAGS.HIE'));
  if p=nil then p:=ParseDatFile (PChar(ldir+'MEDIA/FEATURETAGS.HIE'));
  if p=nil then p:=ParseDatFile (PChar(ldir+'MEDIA/FEATURETAGS.HIE.BINDAT'));

  ProcessHie(p);
  if p<>nil then DeleteNode(p);
  
  ScanForFTags(ldir);
end;

procedure ScanForFTags(actrl:PRGController);
var
  ldir,lfile:integer;
begin
  ldir:=actrl^.SearchPath('MEDIA/FEATURETAGS/');
  if ldir<0 then exit;

  if actrl^.GetFirstFile(lfile,ldir) then
  begin
    repeat
      ProcessName(actrl^.Files[lfile]^.Name);
    until not actrl^.GetNextFile(lfile);
  end;
end;

procedure PrepareFeatureTags(actrl:PRGController);
var
  p:pointer;
  lbuf:PByte;
begin
  lbuf:=nil;
  if actrl^.GetAsIs(actrl^.SearchFile('MEDIA/','FEATURETAGS.HIE'),lbuf)=0 then exit;

                p:=ParseTextMem(lbuf);
  if p=nil then p:=ParseDatMem (lbuf);

  FreeMem(lbuf);
  
  ProcessHie(p);
  if p<>nil then DeleteNode(p);

  ScanForFTags(actrl);
end;

procedure PrepareFeatureTags();
begin
  ProcessHie(nil);
end;

end.
