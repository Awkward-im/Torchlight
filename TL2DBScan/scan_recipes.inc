{%REGION Recipes}

function AddRecipeToBase(ams:pointer; var aname:string; aId:int64;
          const atitle, aicon, fname:string):integer;
var
  lmodid,lSQL,sid:string;
begin
  if aId=-1 then
  begin
    lmodid:=CheckNameForMod(ams,'recipes', aname);
    if lmodid='' then
    begin
      if RGDebugLevel=dlDetailed then RGLog.Add('Looks like name "'+aname+
          '" used already. trying to use filename.');
      aname:=ExtractNameOnly(fname);
      lmodid:=CheckNameForMod(ams,'recipes',aname);
    end;
    sid:='-1';
  end
  else
  begin
    Str(aid,sid);
    lmodid:=CheckIdForMod(ams,'recipes', sid);
  end;
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO recipes (id, name, title, icon, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+aicon+', '+lmodid+')';

    if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
      result:=1
    else
      result:=0;
  end
  else
    result:=-1
end;

function AddRecipeNode(ams:pointer; anode:pointer; const fname:string):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  name,title,licon:string;
  lid:int64;
  i:integer;
begin
  title:='';
  licon:='';
  lid:=-1;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    if GetNodeType(lnode)<>rgGroup then
    begin
      pcw:=GetNodeName(lnode);
      if CompareWide(pcw,'NAME'  )=0 then name :=AsString(lnode)
      // TL2 only
      else if CompareWide(pcw,'GUID'  )=0 then lid  :=AsInteger64(lnode)
      else if CompareWide(pcw,'ICON'  )=0 then licon:=AsString   (lnode)
      else if CompareWide(pcw,'RESULT')=0 then title:=AsString   (lnode)
    end;
  end;
{
  if PModScanner(ams)^.gamever=verTL1 then
    title:=name;
}
  result:=AddRecipeToBase(ams,name,lid,title,licon,fname);
end;

function ProcessRecipes(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p:pointer;
  lres:integer;
begin
  result:=sres_fail;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      lres:=AddRecipeNode(aparam,p,aname);
           if lres>0 then result:=1
      else if lres<0 then result:=0
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanRecipes(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning recipes');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/RECIPES', @ProcessRecipes);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

// Variant: to make two different structures, for TL1 and TL2 games
// id can be AUTOINCREMENT then
function CreateRecipesTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'recipes') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE recipes ('+
//      '    id    INTEGER PRIMARY KEY,'+
      '    id    INTEGER,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    icon  TEXT,'+
      '    modid TEXT );')
  else
    result:=true;
end;

{%ENDREGION}
