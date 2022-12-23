{ nodejs
, fetchurl
, stdenvNoCC
, which
}:
let
  inherit (builtins) fromJSON readFile mapAttrs attrNames concatStringsSep;
  lock = fromJSON (readFile ./package-lock.json);
  fetched = mapAttrs (k: v: fetchurl { 
    url = v.resolved;
    sha512 = v.integrity;
  }) lock.dependencies;
in stdenvNoCC.mkDerivation {
  name = "frontend.html";

  nativeBuildInputs = [ nodejs which ];

  unpackPhase = ''
    cp ${./.}/* . -r
    ${concatStringsSep "\n" (map (name: ''
      mkdir -p ${name}
      tar -xf ${fetched."${name}"} -C ${name}
    '') (attrNames fetched))}
    find .
  '';

  buildPhase = ''
    substituteInPlace node_modules/.bin/vite \
      --replace '/usr/bin/env node' "$(which node)"
    mkdir -p dist
    chmod +w -R dist
    npm run build
  '';

  installPhase = ''
    cp dist/index.html $out
  '';
}
