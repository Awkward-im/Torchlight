unit TL2Common;

interface

uses
   classes
  ,tl2types
  ;

type
  TTL2ParseType = (ptLite, ptStandard, ptDeep, ptDeepest);

type
  gc_BaseClass = (Berserker, Embermage, Engineer, Outlander);

procedure SaveDump(const aname:string; aptr:pByte; asize:cardinal);


implementation


procedure SaveDump(const aname:string; aptr:pByte; asize:cardinal);
var
  f:file of byte;
begin
  AssignFile(f,aname);
  Rewrite(f);
  BlockWrite(f,aptr^,asize);
  CloseFile(f);
end;

end.
