{ pkgs ? import <nixpkgs> {}
, template ? pkgs.callPackage ./web {}
}:
pkgs.stdenvNoCC.mkDerivation {
  name = "nix-graph-viewer";

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.python3Minimal ];

  installPhase = ''
    mkdir $out/bin -p
    install -m755 ${./graphify.py} $out/bin/nix-graph-viewer

    patchShebangs $out/bin/nix-graph-viewer

    sed -i 's;^\(TEMPLATE_FILE =\).*$;\1 Path("${template}");' $out/bin/nix-graph-viewer
  '';

  passthru = {
    inherit template;
  };
}
