{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  languages = {
    opentofu.enable = true;
  };

  packages = with pkgs; [
    gh
    awscli2
    kubectl
    kubernetes-helm
    argocd
    k9s
  ];

  treefmt = {
    enable = true;
    config.programs = {
      nixfmt.enable = true;
      prettier.enable = true;
      terraform.enable = true;
    };
  };

  git-hooks.hooks = {
    treefmt.enable = true;
  };
}
