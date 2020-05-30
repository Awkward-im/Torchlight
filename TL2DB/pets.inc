{$IFDEF Interface}

function GetTL2Pet (const aid:TL2ID; out amods:string):string; overload;
function GetTL2Pet (const aid:TL2ID                  ):string; overload;

function GetPetIcon(const aid:TL2ID):string;

{$ELSE}

const
  DefaultPets: array [0..20] of record
    id   :TL2ID;
    title:string;
    scale:single;
  end = (
    (id:-8880591480184383566; title:'Cat'        ; scale:0.65),
    (id:-8742058185063171412; title:'Jackalbeast'; scale:0.75),
    (id:-6861078633348114419; title:'Hawk'       ; scale:1   ),
    (id:-6861072635378114419; title:'Swampflyer' ; scale:1   ),
    (id:-6082309300095414029; title:'Papillon'   ; scale:0.8 ),
    (id:-4272058185063171412; title:'Crab'       ; scale:1   ),
    (id:-2472058185064571412; title:'Wolf'       ; scale:0.75),
    (id:-2472058185064571327; title:'Panther'    ; scale:1   ),
    (id:-2472058185032171412; title:'Warbeast'   ; scale:0.8 ),
    (id:-2412341850671171412; title:'Molebeast'  ; scale:1.15),
    (id:-1672582398143053873; title:'Alpaca'     ; scale:1   ),
    (id:-1144795368701180224; title:'Chakawary'  ; scale:0.75),
    (id:-18242231495209399  ; title:'Headcrab'   ; scale:1   ),
    (id:2236371573517850133 ; title:'Torso'      ; scale:1.25),
    (id:2846508072355823983 ; title:'Bulldog'    ; scale:1   ),
    (id:2947367154991955139 ; title:'Panda'      ; scale:1   ),
    (id:6085265292355965406 ; title:'Ferret'     ; scale:1   ),
    (id:6212525112683485562 ; title:'Stag'       ; scale:1   ),
    (id:6516037093941808301 ; title:'Owl'        ; scale:1   ),
    (id:7002609406216574240 ; title:'Spider'     ; scale:0.8 ),
    (id:7846508072355823983 ; title:'Badger'     ; scale:1   )
  );

function GetTL2Pet(const aid:TL2ID; out amods:string):string;
var
  lname:string;
  i:integer;
begin
  if db=nil then
  begin
    amods:='';
    for i:=0 to High(DefaultPets) do
    begin
      if DefaultPets[i].id=aid then
      begin
        result:=DefaultPets[i].title;
        exit;
      end;
    end;
    result:='';
  end
  else
    result:=GetById(aid,'pets','',amods,lname);
end;

function GetTL2Pet(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Pet(aid,lmods);
end;

function GetPetIcon(const aid:TL2ID):string;
var
  lSQL:string;
  vm:pointer;
begin
  result:='';

  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT icon FROM pets WHERE id='+lSQL;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

{$ENDIF}
