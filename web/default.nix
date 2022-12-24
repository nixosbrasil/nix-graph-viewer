{ nodejs
, fetchurl
, stdenvNoCC
, which
, lib
, git
, python3
}:
let
  inherit (builtins) fromJSON readFile mapAttrs attrNames attrValues concatStringsSep head split replaceStrings filter hasAttr;
  inherit (lib) reverseList flatten;
  getLockFileFromTarball = src: stdenvNoCC.mkDerivation {
    name = "${src.name}-package-lock.json";
    inherit src;
    preferLocalBuild = true;
    installPhase = ''
      find .
      cp package/package-lock.json $out || echo '{"packages": {}}' > $out
    '';
  };
  fetchItemsFromLock = lockfile: let
      lockdata = fromJSON (readFile lockfile);
    in (map (v:
        ((fetchurl {
          name = head (reverseList (split "/" v.resolved));
          url = v.resolved;
          sha512 = v.integrity;
        }).overrideAttrs (old: { passthru = v; }))
      ) (filter (hasAttr "resolved") (attrValues lockdata.packages)));

  fetched = fetchItemsFromLock ./package-lock.json;

in stdenvNoCC.mkDerivation {
  name = "frontend.html";

  nativeBuildInputs = [ nodejs which python3 ];

  preferLocalBuild = true;

  unpackPhase = ''
    cp ${./.}/* . -r
    mkdir _home -p
    export HOME=$(pwd)/_home
    chmod +w . $HOME -R

    mkdir _cache -p

    ${concatStringsSep "\n" (map (v: ''
      FILENAME="${replaceStrings [ "https://registry.npmjs.org/"] ["$(pwd)/_cache/"] v.resolved}"
      mkdir -p "$(dirname "$FILENAME")"
      ln -s ${v} $FILENAME
    '') fetched)}

    python -m http.server 1234 -d _cache &

    npm install --verbose --no-audit --registry http://127.0.0.1:1234

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
