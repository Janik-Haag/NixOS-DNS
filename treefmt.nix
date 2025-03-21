_: {
  projectRootFile = ".git/config";

  settings.global.excludes = [
    ".envrc"
  ];

  programs = {
    mdformat.enable = true;
    nixfmt.enable = true;
    yamlfmt.enable = true;
  };
}
