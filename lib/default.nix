{
  mkVm = modulePath: {pkgs}: let
    vm = import ../modules pkgs;
    executable = vm (import modulePath);
  in
    executable;
}
