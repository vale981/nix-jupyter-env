{
  nixpkgs ? import <nixpkgs> {}
, haskellCompiler ? "ghc7103"
, pythonCompiler ? "python34"
}:

let
  inherit (nixpkgs) stdenv pkgs;

  pythonOverrides =
    {
      overrides = self: super:
        {
          nbstripout = super.buildPythonPackage rec {
            version = "0.2.4a";
            name = "nbstripout-${version}";

            /* Note that 0.2.4 is currently broken with python3 */
            /* src = pkgs.fetchurl { */
            /*   url = "https://pypi.python.org/packages/source/n/nbstripout/${name}.tar.gz"; */
            /*   sha256 = "1gphp7dl8cw5wmylk90vc2jbq4lgp680w3ybv9k0qq6ra2balcyk"; */
            /* }; */
            src = pkgs.fetchgit
              {
                url = "git://github.com/kynan/nbstripout.git";
                sha256 = "12spiwh9wncbrvqhcfnv74zy6qnsxyjl6ma0zknkaxk8ga0bss1z";
                rev = "fe1f767053462254a13c09bed8c5e24ec216a728";
              };

            # TODO: what should build inputs look like?
            buildInputs = with self; [ /*pytest*/ /*nbformat*/ /*jupyter*/ ];
            propagatedBuildInputs = with self; [  ];
            doCheck = false;

            meta =
              {
                description = "strip output from Jupyter and IPython notebooks";
                homepage = "https://github.com/kynan/nbstripout";
                license = pkgs.licenses.mit;
                maintainers = [ ];
              };
          };
        };
    };
  pythonPackages = pkgs.${pythonCompiler + "Packages"} // pythonOverrides.overrides pythonPackages pkgs.${pythonCompiler + "Packages"};

  # It appears to be necessary to use python.buildEnv instead of pkgs.buildEnv in order to maintain the correct PYTHONPATH
  ipython-env = pythonPackages.python.buildEnv.override
                  {
                    extraLibs =
                      with pythonPackages;
                      [
                        jupyter

                        # Python packages (comment/uncomment as needed)
                        /* scipy */
                        /* toolz */
                        /* numpy */
                        /* matplotlib */
                        /* networkx */
                        /* pandas */
                        /* seaborn */

                        # Utilities (notebook formatting, cleaning for git etc)
                        nbstripout  # use this with .gitattributes for clean git commits
                      ];
                  };

  filterDist = src:
    let f = name: type: !(type == "directory" && baseNameOf (toString name) == "dist");
    in builtins.filterSource f src;

  haskellOverrides =
    {
      overrides = self: super:
        let
          callLocalPackage = path: self.callPackage (filterDist path) {};
        in
          {
            # Overides for bleeding-edge ghc 8.0.x (Unfortunately this does not work yet)
            /* monads-tf = pkgs.haskell.lib.doJailbreak super.monads-tf; */
            /* ihaskell = */
            /*   self.callPackage */
            /*   ({ mkDerivation, aeson, base, base64-bytestring # , bin-package-db */
            /*    , bytestring, cereal, cmdargs, containers, directory, filepath, ghc */
            /*    , ghc-parser, ghc-paths, haskeline, haskell-src-exts, hlint, hspec */
            /*    , http-client, http-client-tls, HUnit, sa-kernel, mtl, parsec */
            /*    , process, random, setenv, shelly, split, stm, strict, system-argv0 */
            /*    , text, transformers, unix, unordered-containers, utf8-string, uuid */
            /*    , vector */
            /*    }: */
            /*    mkDerivation { */
            /*      pname = "ihaskell"; */
            /*      version = "0.8.3.0"; */
            /*      sha256 = "c486e0b6342fa6261c671ad6a891f5763f7979bc225781329fe9f913a3833107"; */
            /*      revision = "1"; */
            /*      editedCabalFile = "4079263fe3b633e589775753fe7e3bbab21c800fd7d54c2aa6761478c5019654"; */
            /*      isLibrary = true; */
            /*      isExecutable = true; */
            /*      libraryHaskellDepends = [ */
            /*        aeson base base64-bytestring /*bin-package-db* / bytestring cereal */
            /*        cmdargs containers directory filepath ghc ghc-parser ghc-paths */
            /*        haskeline haskell-src-exts hlint http-client http-client-tls */
            /*        sa-kernel mtl parsec process random shelly split stm strict */
            /*        system-argv0 text transformers unix unordered-containers */
            /*        utf8-string uuid vector */
            /*      ]; */
            /*      ds = [ */
            /*        aeson base /*bin-package-db* / bytestring containers directory ghc */
            /*        sa-kernel process strict text transformers unix */
            /*      ]; */
            /*      testHaskellDepends = [ */
            /*        aeson base base64-bytestring /*bin-package-db* / bytestring cereal */
            /*        cmdargs containers directory filepath ghc ghc-parser ghc-paths */
            /*        haskeline haskell-src-exts hlint hspec http-client http-client-tls */
            /*        HUnit sad-kernel mtl parsec process random setenv shelly split */
            /*        stm strict system-argv0 text transformers unix unordered-containers */
            /*        utf8-string uuid vector */
            /*      ]; */
            /*      doCheck = false; */
            /*      homepage = "http://github.com/gibiansky/IHaskell"; */
            /*      description = "A Haskell backend kernel for the IPython project"; */
            /*      license = stdenv.lib.licenses.mit; */
            /*    }) {}; */
          };
    };
  haskellPackages = pkgs.haskell.packages.${haskellCompiler}.override haskellOverrides;
  ihaskellWithPackages = packages: haskellPackages.ghcWithPackages
    (
      self:
        with self;
        [
          ihaskell

          # IHaskell displayables (comment/uncomment as needed)
          /* ihaskell-display */
          ihaskell-aeson
          ihaskell-basic
          ihaskell-blaze
          ihaskell-charts
          ihaskell-diagrams
          /* ihaskell-hatex */
          /* ihaskell-juicypixels */
          /* ihaskell-magic */
          /* ihaskell-plot */
          /* ihaskell-rlangqq */
          /* ihaskell-static-canvas */
          /* ihaskell-widgets */

          # Haskell packages (comment/uncomment as needed)
          opaleye
          cassava
        ] ++ packages self
    );
  ihaskell-env =
    let
      drv = ihaskellWithPackages
              (
                self:
                  with self;
                  [
                    # Add your own haskell packages here...
                  ]
              );
    in
      pkgs.buildEnv
        {
          name = "ihaskell-env";
          paths = [ drv ];
        };

in

  {
    inherit pythonPackages haskellPackages;
    jupyter-env = pkgs.buildEnv
      {
        name = "jupyter-env";
        paths =
          [
            ipython-env
            ihaskell-env
          ];
      };
  }
