{
  mkVm = {
    modules,
    pkgs,
  }: let
    vm = import ../modules pkgs;
    executable = vm {imports = modules;};
  in
    executable;
}
