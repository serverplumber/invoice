{ pkgs, projectName }:
{
  streamContainer = name: {
    type = "app";
    program = "${(import ../containers/${name} { inherit pkgs projectName; }).image}";
  };
}
