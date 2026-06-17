{
  lib,
  stdenv,
  hunspell,
  bash,
  coreutils,
  writeText,
}:

{
  name,
  termsSrc ? null,
  terms ? [ ],
  # checkTerms ? [],
}:
let
  src =
    if termsSrc != null then termsSrc else writeText "terms-${name}" (lib.concatStringsSep "\n" terms);
in
stdenv.mkDerivation {
  name = "hunspell-dict-${name}";

  nativeBuildInputs = [
    hunspell
    bash
    coreutils
  ];

  dontUnpack = true;
  inherit src;

  buildPhase = ''
    runHook preBuild

    mkdir -p dist/share/hunspell
    bash ${./generate.sh} $src dist/share/hunspell/${name}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -rv dist/. $out/

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    test -s $out/share/hunspell/${name}.dic
  '';

  # TODO: assert dictionary checks out!
  #
  # echo "${lib.strings.concatStringsSep " " checkTerms}" | hunspell -l | grep '^$'
}
