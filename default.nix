{ pkgs
, lib
, stdenv
, fetchFromGitHub
, makeWrapper
, python3
, fetchYarnDeps
, fixup_yarn_lock
, nodejs
, yarn
, callPackage
}:

let
  pname = "calcom";
  version = "3.5";

  inherit (stdenv.hostPlatform) system;

  deps = stdenv.mkDerivation {
    name = "${pname}-${version}-deps";

    src = ./.;

    buildInputs = [ pkgs.jq python3 fixup_yarn_lock nodejs nodejs.pkgs.node-pre-gyp nodejs.pkgs.node-gyp yarn ];

    offlineCache = fetchYarnDeps {
      yarnLock = ./yarn.lock;
      sha256 = "sha256-QRPeoAgK0hGO+9g4jPSUIwM93gln2M6E5D9sY0lkZpE=";
    };

    buildPhase = ''
      runHook preBuild
      export HOME=$PWD
      export NODE_OPTIONS=--openssl-legacy-provider
      fixup_yarn_lock yarn.lock
      yarn config --offline set yarn-offline-mirror $offlineCache
      yarn --offline --frozen-lockfile --ignore-scripts --ignore-engines
      patchShebangs node_modules
    '';

    installPhase = ''
      mkdir $out
      cp -r . $out
    '';
  };
in

stdenv.mkDerivation {
  pname = "overleaf";
  version = "3.5";
  src = deps;
  buildInputs = [ nodejs makeWrapper ];


  installPhase = ''
    mkdir -p $out/{share,bin}
    cp -r . $out/share
  '';


  meta = with lib; {
    description = "A web-based collaborative LaTeX editor";
    homepage = "https://github.com/overleaf/overleaf";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ camillemndn julienmalka ];
    platforms = platforms.all;
  };
}

