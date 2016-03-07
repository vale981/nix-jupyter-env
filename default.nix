{ mkDerivation, base, stdenv, bin-package-db }:
mkDerivation {
  pname = "jupyter-env";
  version = "0.1.0.0";
  src = ./.;
  libraryHaskellDepends = [ base ];
  description = "Example environment for running a Jupyter environment in Nix that includes ipython and ihaskell (contributions welcome)";
  license = stdenv.lib.licenses.mit;
}
