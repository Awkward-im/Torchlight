{%REGION Affixes}
{NOTE: add base/mod NEW affixes only, not edit existing}
{TODO: implement modid for aeffects}

function AddAffixToBase(ams:pointer; const aname,acat:string):integer;
var
  lmodid, lSQL, ls1, ls2:string;
begin
  ls1:=FixedText(aname);
  ls2:=FixedText(acat);
  lmodid:=CheckNamePlusForMod(ams,'affixes', aname,'category='+ls2);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO affixes (name, modid, category) VALUES ('+
        ls1+', '+lmodid+', '+ls2+') RETURNING id;';

    result:=ReturnInt(PModScanner(ams)^.db,lSQL);
    if result=-1 then result:=0;
  end
  else
    result:=-ReturnInt(PModScanner(ams)^.db,
      'SELECT id FROM affixes WHERE (name='+ls1+') AND (category='+ls2+')');
end;


type
  TAffixEffectInfo = record
    name    :string;
    dmgtype :string;
    effect  :integer;
    affix   :integer;
    duration:integer;
    values  :array [0..5] of single;
  end;

function AddAffixEffectToBase(ams:pointer; const aei:TAffixEffectInfo):boolean;
var
  lSQL:string;
begin
  lSQL:='REPLACE INTO aeffects (affix, effect, name, dmgtype, duration, '+
        'value, value1, value2, value3, value4 ,value5) VALUES ('+
        IntToStr(aei.affix)+', '+IntToStr(aei.effect)+', '+
        FixedText(aei.name)+', '''+aei.dmgtype+''', '+IntToStr(aei.duration)+', '+
        FloatToStr(aei.values[0])+', '+FloatToStr(aei.values[1])+', '+
        FloatToStr(aei.values[2])+', '+FloatToStr(aei.values[3])+', '+
        FloatToStr(aei.values[4])+', '+FloatToStr(aei.values[5])+')';

  result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
end;

function AddAffixEffectNode(ams:pointer; anode:pointer; aid:integer):boolean;
var
  laei:TAffixEffectInfo;
  llnode,lnode:pointer;
  vm,lunode:pointer;
  pcw:PWideChar;
  ls:string;
  ltime:single;
  i,j,k:integer;
begin
  result:=true;

  laei.affix:=aid;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    if GetNodeType(lnode)=rgGroup then
    begin
      if CompareWide(GetNodeName(lnode),'EFFECT')=0 then
      begin
        laei.name   :='';
        laei.dmgtype:='';
        laei.effect :=-1;
        laei.duration :=0;
        laei.values[0]:=0.0;
        laei.values[1]:=0.0;
        laei.values[2]:=0.0;
        laei.values[3]:=0.0;
        laei.values[4]:=0.0;
        laei.values[5]:=0.0;
        for j:=0 to GetChildCount(lnode)-1 do
        begin
          llnode:=GetChild(lnode,j);
          pcw:=GetNodeName(llnode);
          if CompareWide(pcw,'NAME')=0 then
            laei.name:=AsString(llnode)
          else if CompareWide(pcw,'DAMAGE_TYPE')=0 then
            laei.dmgtype:=AsString(llnode)
          else if CompareWide(pcw,'VALUE')=0 then
            laei.values[0]:=AsFloat(llnode)
          else if CompareWide(pcw,'DURATION')=0 then
          begin
            ls:=AsString(llnode);
            if (ls='0') or (ls='ALWAYS') or (ls='INSTANT') then
            else
            begin
              Val(ls,ltime);
              laei.duration:=trunc(ltime*100);
            end;
          end
          // effect name in EFFECTLIST.DAT
          else if CompareWide(pcw,'TYPE')=0 then
          begin
            ls:=AsString(llnode);

            // search in list
            ls:='SELECT id, value1, value2, value3, value4, value5 '+
            'FROM effects WHERE name='+FixedText(ls);
            if sqlite3_prepare_v2(PModScanner(ams)^.db,
                PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
            begin
              if sqlite3_step(vm)=SQLITE_ROW then
              begin
               laei.effect:=sqlite3_column_int(vm,0);
               for k:=1 to 5 do
               begin

                 pcw:=sqlite3_column_text16(vm,k);
                 if pcw<>nil then
                 begin
                   lunode:=FindNode(lnode,pcw);
                   if lunode<>nil then
                     laei.values[k]:=AsFloat(lunode);
                 end;
{
                 ls:=sqlite3_column_text(vm,k);
                 if ls<>'' then
                 begin
                   pcw:=FastStrToWide(ls);
                   lunode:=FindNode(llnode,pcw);
                   FreeMem(pcw);
                   if lunode<>nil then
                     laei.values[k]:=AsFloat(lunode);
                 end;
}
               end;
              end;
              sqlite3_finalize(vm);
            end;

          end;
        end;
        if laei.effect>=0  then
          result:=result and AddAffixEffectToBase(ams, laei);
      end;
    end;
  end;
end;

function ProcessAffixes(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p,lnode:pointer;
  lname,lcat:string;
  i,lid:integer;
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
      // ExtractName(adir) analog
      i:=Length(adir);
      dec(i);
      while (i>0) and not (adir[i] in ['/','\']) do dec(i);
      if i>0 then lcat:=copy(adir,i+1,Length(adir)-i-1) else lcat:='';

      lnode:=FindNode(p,'NAME');
      if lnode<>nil then
        lname:=AsString(lnode)
      else
        lname:=ExtractNameOnly(aname);

      lid:=AddAffixToBase(aparam,lname,lcat);
      if lid>0 then
      begin
        result:=1;
        AddAffixEffectNode(aparam,p,lid);
      end
      else if lid=0 then
      begin
        if RGDebugLevel=dlDetailed then
          RGLog.Add('can''t update '+aname);
      end
      else
      begin
{
        if RGDebugLevel=dlDetailed then
          RGLog.Add('Affix '+aname+' exists already');
}
      end;
      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanAffixes(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning affixes');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/AFFIXES', @ProcessAffixes);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' affix records added');
end;

function CreateAffixesTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'affixes') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE affixes ('+
      '  id        INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  name      TEXT,'+
      '  modid     TEXT,'+
      '  category  TEXT);')
  else
    result:=true;

  if not IsTableExists(adb,'aeffects') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE aeffects ('+
      '  affix    INTEGER,'+
      '  effect   INTEGER,'+
      '  name     TEXT,'   +
      '  dmgtype  TEXT,'   +
      '  duration INTEGER,'+
      '  value    REAL,'+
      '  value1   REAL,'+
      '  value2   REAL,'+
      '  value3   REAL,'+
      '  value4   REAL,'+
      '  value5   REAL);')
  else
    result:=true;
  
end;

{%ENDREGION Effects}
