uses rgman;

var
  aman:TRGManifest;
begin
  aman.init;
  aman.Build('.');
  ManToFile('manout.txt',aman);
  aman.free;
end.