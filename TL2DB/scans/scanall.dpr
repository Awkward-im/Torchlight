{$I-}
uses
  sqlite3
  ,awkSQLite3
  ,sysutils
  ,TL2DatNode
  ;

var
  smodid:string;
  db:PSQLite3;

type
  tScanProc = procedure (fname:PChar);


function FixedText(const astr:string):string;
begin
  result:=#39+StringReplace(astr,#39,#39#39,[rfReplaceAll])+#39;
end;

function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);
  repeat
    if s1^<>s2^ then exit(false);
    if s1^=#0 then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;

function CheckForMod(const atable,anid,amodid:string):boolean;
var
  lSQL,lmodid:string;
  vm:pointer;
begin
  result:=false;
  lSQL:='SELECT modid FROM '+atable+' WHERE id='+anid;
  if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      lmodid:=sqlite3_column_text(vm,0);
      if lmodid<>'' then
      begin
        result:=true;
        if Pos(' '+amodid+' ',lmodid)=0 then
        begin
          sqlite3_finalize(vm);
          lmodid:=lmodid+amodid+' ';
          lSQL:='UPDATE '+atable+' SET modid='''+lmodid+''' WHERE id='+anid;
          sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil);
          sqlite3_step(vm);
        end;
      end;
    end;
    sqlite3_finalize(vm);
  end;
end;

//----- Pet -----

type
  tpetinfo = record
    id      :string;
    title   :string;
    name    :string;
    icon    :string;
    atype   :integer;
    scale   :single;
    textures:integer;
  end;

function AddPetToBase(var apet:tpetinfo):boolean;
var
  lSQL,lscale:string;
  vm:pointer;
begin
  result:=CheckForMod('pets', aPet.id, smodid);
  if not result then
  begin
    Str(aPet.Scale:0:2,lscale);

    lSQL:='INSERT INTO pets (id, name, title, type, scale, skins, icon, modid) VALUES ('+
        aPet.id+', '+FixedText(apet.name)+', '+FixedText(apet.title)+', '+
        IntToStr(apet.atype)+', '+lscale+', '+IntToStr(apet.textures)+
        ', '''+apet.icon+''', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddPet(fname:PChar);
var
  p:PTL2Node;
  lpet:tpetinfo;
  i:integer;
begin
  p:=ParseDatFile(fname);
  lpet.scale:=1.0;
  lpet.textures:=0;
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      lpet.name:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      lpet.title:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lpet.id:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNITTYPE') then
    begin
      if CompareWide(p^.children^[i].asString,'STARTING PET') then
        lpet.atype:=0
      else
        lpet.atype:=1;
    end
    else if CompareWide(p^.children^[i].name,'ICON') then
    begin
      lpet.icon:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'SCALE') then
    begin
      lpet.scale:=p^.children^[i].asFloat;
    end
    else if CompareWide(p^.children^[i].name,'TEXTURE_OVERRIDE_LIST') then
    begin
      lpet.textures:=p^.children^[i].childcount;
    end;
  end;
  if not AddPetToBase(lpet) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Quests -----

function AddQuestToBase(const aname:string; aId:int64; const atitle:string):boolean;
var
  lSQL,sid:string;
  vm:pointer;
begin
  Str(aid,sid);
  result:=CheckForMod('quests', sid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO quests (id, name, title, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddQuest(fname:PChar);
var
  p:PTL2Node;
  name,title:string;
  lid:int64;
  i:integer;
begin
  p:=ParseDatFile(fname);
  title:='';
  lid:=-1;

  for i:=0 to p^.childcount-1 do
  begin
    if p^.children^[i].nodetype<>ntGroup then
    begin
      if CompareWide(p^.children^[i].name,'NAME') then
      begin
        name:=p^.children^[i].asString;
      end
      else if CompareWide(p^.children^[i].name,'QUEST_GUID') then
      begin
        lid:=p^.children^[i].asInteger64;
      end
      else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
      begin
        title:=p^.children^[i].asString;
      end;
    end;
  end;
  if lid<>-1 then
  begin
    if not AddQuestToBase(name,lid,title) then
      writeln('can''t update ',fname);
  end
  else
    writeln(' don''t added',fname);
  DeleteNode(p);
end;

//----- Stats -----

function AddStatToBase(const aname:string; aId:int64; const atitle:string; asaves:boolean):boolean;
var
  lSQL,sid,ssaves:string;
  vm:pointer;
begin
  Str(aid,sid);
  result:=CheckForMod('stats', sid, smodid);
  if not result then
  begin
    if asaves then ssaves:='1' else ssaves:='0';

    lSQL:='INSERT INTO stats (id, name, title, saves, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+ssaves+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddStat(fname:PChar);
var
  p:PTL2Node;
  name,title:string;
  lid:int64;
  saves:boolean;
  i:integer;
begin
  p:=ParseDatFile(fname);
  title:='';
  saves:=false;
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      name:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIQUE_GUID') then
    begin
      lid:=p^.children^[i].asInteger64;
    end
    else if CompareWide(p^.children^[i].name,'SAVES') then
    begin
      saves:=p^.children^[i].asBoolean;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      title:=p^.children^[i].asString;
    end;
  end;
  if not AddStatToBase(name,lid,title,saves) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Recipes -----

function AddRecipeToBase(const aname:string; aId:int64; const atitle:string):boolean;
var
  lSQL,sid:string;
  vm:pointer;
begin
  Str(aid,sid);
  result:=CheckForMod('recipes', sid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO recipes (id, name, title, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddRecipe(fname:PChar);
var
  p:PTL2Node;
  name,title:string;
  lid:int64;
  i,mask:integer;
begin
  p:=ParseDatFile(fname);
  title:='';
  lid:=-1;

  mask:=0;
  for i:=0 to p^.childcount-1 do
  begin
    if p^.children^[i].nodetype<>ntGroup then
    begin
      if CompareWide(p^.children^[i].name,'NAME') then
      begin
        mask:=mask or 1;
        name:=p^.children^[i].asString;
      end
      else if CompareWide(p^.children^[i].name,'GUID') then
      begin
        mask:=mask or 2;
        lid:=p^.children^[i].asInteger64;
      end
      else if CompareWide(p^.children^[i].name,'RESULT') then
      begin
        mask:=mask or 4;
        title:=p^.children^[i].asString;
      end;
      if mask=7 then break;
    end;
  end;
  if lid<>-1 then
  begin
    if not AddRecipeToBase(name,lid,title) then
      writeln('can''t update ',fname);
  end
  else
    writeln(' don''t added ',fname);
  DeleteNode(p);
end;

//----- Mobs -----

function AddMobToBase(const anid,aname,atitle:string):boolean;
var
  lSQL:string;
  vm:pointer;
begin
  result:=CheckForMod('mobs', anid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO mobs (id, name, title, modid) VALUES ('+
        anid+', '+FixedText(aname)+', '+FixedText(atitle)+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddMob(fname:PChar);
var
  p:PTL2Node;
  lid,lname,ltitle:string;
  i,mask:integer;
begin
  if Pos('MEDIA\UNITS\MONSTERS\PETS'           ,fname)<>0 then exit;
  if Pos('MEDIA\UNITS\MONSTERS\WARBOUNDS'      ,fname)<>0 then exit;
  if Pos('MEDIA\UNITS\MONSTERS\BROTHER-IN-ARMS',fname)<>0 then exit;

  p:=ParseDatFile(fname);
  mask:=0;
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      mask:=mask or 1;
      lname:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      mask:=mask or 2;
      ltitle:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      mask:=mask or 4;
      lid:=p^.children^[i].asString;
    end;
    if mask=7 then break;
  end;
  if not AddMobToBase(lid,lname,ltitle) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Items -----

function AddItemToBase(const anid,aname,atitle,adescr,aicon,auses,aquest:string):boolean;
var
  lSQL:string;
  vm:pointer;
begin
  result:=CheckForMod('items', anid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO items (id, name, title, descr, icon, uses, quest, modid) VALUES ('+
        anid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+FixedText(adescr)+
        ', '''+aicon+''', '+auses+', '+aquest+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddItem(fname:PChar);
var
  p:PTL2Node;
  ldescr,lid,lname,ltitle,licon,luses,lquest:string;
  i:integer;
begin
  p:=ParseDatFile(fname);
  ltitle:='';
  luses:='0';
  if Pos('MEDIA\UNITS\ITEMS\QUEST_ITEMS\',fname)>0 then lquest:='1' else lquest:='0';
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      lname:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      ltitle:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DESCRIPTION') then
    begin
      ldescr:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'ICON') then
    begin
      licon:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lid:=p^.children^[i].asString;
    end
    else if (lquest='0') and CompareWide(p^.children^[i].name,'UNITTYPE') then
    begin
      if CompareWide(p^.children^[i].asString,'LEVEL ITEM') or 
         CompareWide(p^.children^[i].asString,'QUESTITEM') then
           lquest:='1';
    end
    else if CompareWide(p^.children^[i].name,'USES') then
    begin
      luses:=p^.children^[i].asString;
    end;
  end;
  if not AddItemToBase(lid,lname,ltitle,ldescr,licon,luses,lquest) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Props -----

function AddPropToBase(const anid,aname,atitle,aquest:string):boolean;
var
  lSQL:string;
  vm:pointer;
begin
  result:=CheckForMod('props', anid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO props (id, name, title, quest, modid) VALUES ('+
        anid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+
        aquest+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddProp(fname:PChar);
var
  p:PTL2Node;
  lid,lname,ltitle,lquest:string;
  i:integer;
begin
  p:=ParseDatFile(fname);
  ltitle:='';
  if Pos('MEDIA\UNITS\PROPS\QUESTPROPS\',fname)>0 then lquest:='1' else lquest:='0';
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      lname:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      ltitle:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lid:=p^.children^[i].asString;
    end;
{
    else if (lquest='0') and CompareWide(p^.children^[i].name,'UNITTYPE') then
    begin
    end
}
  end;
  if not AddPropToBase(lid,lname,ltitle,lquest) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Skills -----

type
  tSkillInfo = record
    id     :string;
    name   :string;
    title  :string;
    descr  :string;
    graph  :string;
    icon   :string;
    minlvl :string;
    maxlvl :string;
    passive:char;
    shared :char;
  end;

function AddSkillToBase(const askill:tSkillInfo):boolean;
var
  lSQL:string;
  vm:pointer;
begin
  result:=CheckForMod('skills', askill.id, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO skills (id, name, title, descr, tier, icon,'+
          ' minlevel, maxlevel, passive, shared, modid) VALUES ('+
        askill.id+', '+FixedText(askill.name)+', '+FixedText(askill.title)+', '+FixedText(askill.descr)+
        ', '''+askill.graph+''', '''+askill.icon+''', '+
        askill.minlvl+', '+askill.maxlvl+', '+askill.passive+', '+askill.shared+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddSkill(fname:PChar);
var
  p,pp,ppp:PTL2Node;
  lskill:TSkillInfo;
  levels:array [0..63] of integer;
  ls:string;
  i,j,lcnt:integer;
  haslevels:boolean;
begin
  p:=ParseDatFile(fname);

  fillchar(levels,SizeOf(levels),0);
  fillchar(lskill,sizeof(lskill),0);

  if Pos('MEDIA\SKILLS\SHARED',fname)>0 then
    lskill.shared:='1'
  else
    lskill.shared:='0';

  lskill.passive:='0';
  lskill.minlvl :='0';

  lcnt:=0;
  haslevels:=false;

  for i:=0 to p^.childcount-1 do
  begin
    pp:=@p^.children^[i];

    if CompareWide(pp^.name,'NAME') then
    begin
      lskill.name:=pp^.asString;
    end
    else if CompareWide(pp^.name,'DISPLAYNAME') then
    begin
      lskill.title:=pp^.asString;
    end
    else if CompareWide(pp^.name,'DESCRIPTION') then
    begin
      lskill.descr:=pp^.asString;
    end
    else if CompareWide(pp^.name,'BASE_DESCRIPTION') then
    begin
      lskill.descr:=pp^.asString;
    end
    else if CompareWide(pp^.name,'REQUIREMENT_GRAPH') then
    begin
      lskill.graph:=pp^.asString;
    end
    else if CompareWide(pp^.name,'ACTIVATION_TYPE') then
    begin
      if pp^.asString='PASSIVE' then
        lskill.passive:='1';
    end
    else if CompareWide(pp^.name,'SKILL_ICON') then
    begin
      lskill.icon:=pp^.asString;
    end
    else if CompareWide(pp^.name,'LEVEL_REQUIRED') then
    begin
      Str(pp^.asInteger,lskill.minlvl);
    end
    else if CompareWide(pp^.name,'UNIQUE_GUID') then
    begin
      Str(pp^.asInteger64,lskill.id);
    end;
    if (pp^.nodeType=ntGroup) and (Pos('LEVEL',WideString(pp^.name))=1) then
    begin
      for j:=0 to pp^.childcount-1 do
      begin
        ppp:=@pp^.children^[j];
        if CompareWide(ppp^.name,'LEVEL_REQUIRED') then
        begin
          levels[lcnt]:=ppp^.asInteger;
          if levels[lcnt]>0 then
            haslevels:=true;
        end;
      end;
      inc(lcnt);
    end;
  end;

  if lcnt=0 then
    lcnt:=1;
  Str(lcnt,lskill.maxlvl);

  if (lskill.graph='') and haslevels then
  begin
    lskill.graph:=',';
    for i:=0 to lcnt-1 do
    begin
      Str(levels[i],ls);
      lskill.graph:=lskill.graph+ls+',';
    end;
  end;

  if not AddSkillToBase(lskill) then
    writeln('can''t update ',fname);

  DeleteNode(p);
end;

//----- Classes -----

function AddClassToBase(const anid,aname,atitle,adescr,afile,abase,askill,aicon:string):boolean;
var
  lSQL,lfile,lbase:string;
  vm:pointer;
  i:integer;
begin
  result:=CheckForMod('classes', anid, smodid);
  if not result then
  begin
    lfile:=LowerCase(afile);
    for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';
    lbase:=LowerCase(abase);
    for i:=1 to Length(lbase) do if lbase[i]='\' then lbase[i]:='/';
    lSQL:='INSERT INTO classes (id, name, title, descr, file, base, skills, icon, modid) VALUES ('+
        anid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+FixedText(adescr)+
        ', '''+lfile+''', '''+lbase+''', '+
        FixedText(askill)+', '''+aicon+''', '' '+smodid+' '')';
    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddPlayer(fname:PChar);
var
  p:PTL2Node;
  lskill,ldescr,lid,lname,ltitle,lbase,licon:string;
  i,j:integer;
begin
  p:=ParseDatFile(fname);
  ltitle:='';
  lskill:=',';

  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'BASEFILE') then
    begin
      lbase:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'NAME') then
    begin
      lname:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      ltitle:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DESCRIPTION') then
    begin
      ldescr:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'ICON') then
    begin
      licon:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lid:=p^.children^[i].asString;
    end;

    if CompareWide(p^.children^[i].name,'SKILL') then
    begin
      with p^.children^[i] do
        for j:=0 to childcount-1 do
        begin
          if CompareWide(children^[j].name,'NAME') then
          begin
            lskill:=lskill+string(children^[j].asString)+',';
            break;
          end;
        end;
    end;
  end;
  if lskill=',' then lskill:='';
  if not AddClassToBase(lid,lname,ltitle,ldescr,fname,lbase,lskill,licon) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- main cycle -----

procedure CycleDir(const adir:AnsiString; aproc:tScanProc);
var
  sr:TSearchRec;
  lname:AnsiString;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(lname,aproc);
      end
      else
      begin
        if UpCase(ExtractFileExt(lname))='.DAT' then
        begin
          aproc(PChar(lname));
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

var
  p,pp:PTL2Node;
  modid:int64;
begin
  p:=ParseDatFile('MOD.DAT');
  pp:=FindNode(p,'MOD_ID');
  modid:=pp^.asInteger64;
  DeleteNode(p);

  Str(modid,smodid);

  sqlite3_open(':memory:',@db);
  if CopyFromFile(db,'tl2db2.db')<>SQLITE_OK then
  begin
    writeln('can''t open');
    exit;
  end;
//  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);

  // Pets
  writeln('Go pets!');
  CycleDir('MEDIA\UNITS\MONSTERS\PETS'           ,@AddPet);
  CycleDir('MEDIA\UNITS\MONSTERS\WARBOUNDS'      ,@AddPet);
  CycleDir('MEDIA\UNITS\MONSTERS\BROTHER-IN-ARMS',@AddPet);
{
  sqlite3_exec(db,'End Transaction'  ,nil,nil,nil);
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
}
  // Quests
  writeln('Go quests!');
  CycleDir('MEDIA\QUESTS',@AddQuest);
{
  sqlite3_exec(db,'End Transaction'  ,nil,nil,nil);
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
}
  // Stats
  writeln('Go stats!');
  CycleDir('MEDIA\STATS',@AddStat);
{
  sqlite3_exec(db,'End Transaction'  ,nil,nil,nil);
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
}
  // Recipes
  writeln('Go recipes!');
  CycleDir('MEDIA\RECIPES',@AddRecipe);
{
  sqlite3_exec(db,'End Transaction'  ,nil,nil,nil);
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
}
  // Mobs
  writeln('Go mobs!');
  CycleDir('MEDIA\UNITS\MONSTERS',@AddMob);
{
  sqlite3_exec(db,'End Transaction'  ,nil,nil,nil);
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
}
  // Items
  writeln('Go items!');
  CycleDir('MEDIA\UNITS\ITEMS',@AddItem);
{
  sqlite3_exec(db,'End Transaction'  ,nil,nil,nil);
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
}
  // Items
  writeln('Go props!');
  CycleDir('MEDIA\UNITS\PROPS',@AddProp);
{
  sqlite3_exec(db,'End Transaction'  ,nil,nil,nil);
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
}
  // Skills
  writeln('Go skills!');
  CycleDir('MEDIA\SKILLS',@AddSkill);
{
  sqlite3_exec(db,'End Transaction'  ,nil,nil,nil);
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
}

  // Classes
  writeln('Go classes!');
  CycleDir('MEDIA\UNITS\PLAYERS',@AddPlayer);

//  sqlite3_exec(db,'End Transaction',nil,nil,nil);
  CopyToFile(db,'tl2db2.db');
  sqlite3_close(db);
end.
