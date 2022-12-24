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

  httpsrv = builtins.toFile "http.js" ''
// stolen from: https://stackoverflow.com/questions/16333790/node-js-quick-file-server-static-files-over-http
var http = require('http');
var fs = require('fs');
var path = require('path');

http.createServer(function (request, response) {
    console.log('request starting...');

    var filePath = process.env.HTTPD_CACHE_DIR + request.url;
    console.log(request.method, request.url);

    fs.readFile(filePath, function(error, content) {
        if (error) {
            if(error.code == 'ENOENT'){
                fs.readFile('./404.html', function(error, content) {
                    response.writeHead(404);
                    response.end();
                });
            }
            else {
                response.writeHead(500);
                response.end('Sorry, check with the site admin for error: '+error.code+' ..\n');
                response.end(); 
            }
        }
        else {
            response.writeHead(200);
            response.end(content, 'utf-8');
        }
    });

}).listen(parseInt(process.env.HTTPD_PORT));
  '';

in stdenvNoCC.mkDerivation {
  name = "frontend.html";

  nativeBuildInputs = [ nodejs which ];

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
    export HTTPD_CACHE_DIR=$(realpath .)/_cache
    export HTTPD_PORT=1234
    node ${httpsrv} &

    npm install --verbose --no-audit --registry http://127.0.0.1:1234

  '';

  buildPhase = ''
    substituteInPlace node_modules/.bin/vite --replace '/usr/bin/env node' "$(which node)"
    mkdir -p dist
    chmod +w -R dist
    npm run build
  '';

  installPhase = ''
    cp dist/index.html $out
  '';
}
