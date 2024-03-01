{
  Unit for any preparations: scan dir/files for constants mainly
}
unit RGPrepare;

interface

procedure PrepareFeatureTags(const adir:string);


implementation

uses
  SysUtils,
  rgglobal,
  rgio.text,
  rgio.dat,
  rgio.layout,
  rgnode;

{
  scan MEDIA/FEATURETAGS for files with name like ID###_NAME
  get ID and NAME from filename
  if doubling (.DAT and .DAT.BINDAT) just overwrite existing
}
procedure ScanForFTags(const adir:string);
var
  sr:TUnicodeSearchRec;
  ls:UnicodeString;
  i,j,id:integer;
begin
  SetLength(ls,Length(adir));
  for i:=1 to  Length(adir) do ls[i]:=WideChar(ord(adir[i]));

  if FindFirst(ls+'MEDIA/FEATURETAGS/*.*',faAnyFile,sr)=0 then
  begin
    repeat
      ls:=UpCase({ExtractFileNameOnly}(sr.Name));
      if (ls[1]='I') and (ls[2]='D') then
      begin
        // cut ID and NAME
        id:=0;
        i:=3;
        while ls[i] in ['0'..'9'] do
        begin
          id:=id*10+ORD(ls[i])-ORD('0');
          inc(i);
        end;
        if ls[i]='_' then inc(i);
        j:=i+1;
        while (j<Length(ls)) and (ls[j]<>'.') do inc(j);
        ls:=Copy(ls,i,j-i);
        if id>0 then
        begin
          // search and overwrite existing
          for i:=0 to High(FeatureTags) do
          begin
            if FeatureTags[i].id=id then
            begin
              FeatureTags[i].name:=ls;
              id:=-1;
              break;
            end;
          end;
          // add non-existing
          if id>0 then
          begin
            i:=Length(FeatureTags);
            SetLength(FeatureTags,i+1);
            FeatureTags[i].id  :=id;
            FeatureTags[i].name:=ls;
          end;
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

procedure PrepareFeatureTags(const adir:string);
var
  ldir:string;
  p,p1,p2:pointer;
  i:integer;
begin
  ldir:=adir;
  if (ldir[Length(ldir)]<>'/') and (ldir[Length(ldir)]<>'\') then ldir:=ldir+'/';

                p:=ParseTextFile(PChar(ldir+'MEDIA/FEATURETAGS.HIE'));
  if p=nil then p:=ParseDatFile (PChar(ldir+'MEDIA/FEATURETAGS.HIE'));
  if p=nil then p:=ParseDatFile (PChar(ldir+'MEDIA/FEATURETAGS.HIE.BINDAT'));

  if p<>nil then
  begin
    p1:=GetChild(p,1);
    SetLength(FeatureTags,GetChildCount(p1));
    for i:=0 to GetChildCount(p1)-1 do
    begin
      p2:=GetChild(p1,i);
      FeatureTags[i].id  :=              AsInteger(FindNode(p2,'ID'));
      FeatureTags[i].name:=UnicodeString(AsString (FindNode(p2,'NAME')));
    end;
  end;
  DeleteNode(p);
  
  ScanForFTags(ldir);
end;

end.
