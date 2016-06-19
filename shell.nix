{
  nixpkgs ?
    let
      inherit (import <nixpkgs> {}) fetchFromGitHub;
    in
      import
        ( fetchFromGitHub
          {
            owner = "NixOS";
            repo = "nixpkgs";
            rev = "0bd54a6d5d4eba361c5b8ff04dd3c02d6dbfb259";
            sha256 = "10fkcq9f2pmg5985kbxq05jgx9ih7axpqsam3jxkzpyalgd0gwvy";
          }
        ) {}
}:

let
  inherit (nixpkgs) pkgs;
  inherit (import ./release.nix { inherit nixpkgs; }) jupyter-env;
in
  pkgs.stdenv.mkDerivation
    {
      name = "jupyter-env";
      src = ./.;
      buildInputs =
        (
          with pkgs;
          [
            jupyter-env

            # Utilities (comment/uncomment as needed)
            /* cabal2nix */
            /* nixops */
            /* pythonPackages.virtualenv */
            /* pythonPackages.pip */

          ]
        );
      shellHook =
        let
          nc="\\e[0m"; # No Color
          white="\\e[1;37m";
          black="\\e[0;30m";
          blue="\\e[0;34m";
          light_blue="\\e[1;34m";
          green="\\e[0;32m";
          light_green="\\e[1;32m";
          cyan="\\e[0;36m";
          light_cyan="\\e[1;36m";
          red="\\e[0;31m";
          light_red="\\e[1;31m";
          purple="\\e[0;35m";
          light_purple="\\e[1;35m";
          brown="\\e[0;33m";
          yellow="\\e[1;33m";
          grey="\\e[0;30m";
          light_grey="\\e[0;37m";
        in
          # localstate.nixops keeps state (IP addresses etc) local, but we're not checking this into git at present
          # See https://blog.wearewizards.io/how-to-use-nixops-in-a-team
          ''
          echoline() { echo "------------------------------------------------------------------------------------------------------------------------"; }
          fail() {
            echo ""
            echoline
            cleanup
            exit 1
          }
          assert_exist() {
            if [ ! -e "$1" ]; then
              printf "$2\n"
              fail
            fi
          }
          assert_nonempty() {
            if [ -z "$1" ]; then
              printf "$2\n"
              fail
            fi
          }
          cleanup() {
            unset -f echoline
            unset -f fail
            unset -f assert_exist
            unset -f assert_nonempty
            unset -f cleanup
          }

          echoline
          echo "Jupyter shell environment"
          echo ""

          # if [ ! -e secrets.nix ]; then
          #   printf "{ ... }:\n\n{\n}" > secrets.nix
          # fi

          # assert_exist ".env" "Missing ${white}.env${nc} file detected. Please create one with your EC2 credentials before getting started."
          # (
          #   export $(xargs < .env)
          #   assert_nonempty "$EC2_ACCESS_KEY" "Environment variable ${white}\$EC2_ACCESS_KEY${nc} is empty. Please add it to your ${white}.env${nc} file."
          #   assert_nonempty "$EC2_SECRET_KEY" "Environment variable ${white}\$EC2_SECRET_KEY${nc} is empty. Please add it to your ${white}.env${nc} file."
          # ) || exit

          echo "Usage:"
          printf "  ${white}nixops${nc} is aliased to use your ${white}.env${nc} file in order to deploy using EC2 keys.\n"
          printf "  ${white}jupyter-remote${nc} is an alias for ${white}nixops <command> -d jupyter-remote${nc}.\n"
          printf "  ${white}notebook${nc} is an alias for ${white}jupyter-notebook${nc}.\n"
          printf "  ${white}livenotebook${nc} is an alias for ${white}jupyter-notebook${nc} using your ${white}.env${nc} file in order to get a db connection.\n"
          printf "  ${white}liveipython${nc} is an alias for ${white}ipython${nc} using your ${white}.env${nc} file in order to get a db connection.\n"
          printf "  ${white}liveihaskell${nc} is an alias for ${white}ihaskell${nc} using your ${white}.env${nc} file in order to get a db connection.\n"
          echo ""
          echo "E.g."
          printf "  ${white}$ jupyter-remote create ./ec2-spot.nix ${light_grey}# create your deployment${nc}\n"
          printf "  ${white}$ jupyter-remote deploy                ${light_grey}# deploy a spot instance to amazon EC2${nc}\n"
          printf "  ${white}$ jupyter-remote destroy               ${light_grey}# destroy your running instance${nc}\n"
          printf "  ${white}$ notebook                             ${light_grey}# run jupyter notebook without a db connection${nc}\n"
          printf "  ${white}$ livenotebook                         ${light_grey}# run jupyter notebook with a db connection${nc}\n"
          printf "  ${white}$ liveipython                          ${light_grey}# run ipython console  with a db connection${nc}\n"
          printf "  ${white}$ liveihaskell                         ${light_grey}# run ihaskell console with a db connection${nc}\n"
          echo ""

          export NIXOPS_STATE=.localstate.nixops
          alias withenv='env $(xargs < .env)'
          # alias nixops='withenv \nixops' # The slash is used to avoid recursion
          alias jupyter-remote='withenv NIXOPS_DEPLOYMENT=jupyter-remote nixops'
          alias notebook='jupyter notebook'
          alias livenotebook='withenv jupyter notebook'
          alias liveipython='withenv ipython console'
          alias liveihaskell='withenv ipython console --kernel haskell'

          echo "Install git filters..."
          git config filter.nbstripout.clean 'nbstripout'
          git config filter.nbstripout.smudge cat
          git config filter.nbstripout.required true
          # TODO: lhs would be very easy to manage in git, but unfortunately ihaskell convert doesn't handle stdout/stdin
          # git config filter.lhsconvert.clean 'ihaskell convert'
          # git config filter.lhsconvert.smudge cat
          # git config filter.lhsconvert.required true

          echo "Install ihaskell kernel..."
          ${jupyter-env}/bin/ihaskell install -l $(${jupyter-env}/bin/ghc --print-libdir)

          # echo "Run in a local environment so that we can use pip as needed..."
          # virtualenv --python=python3.4 .venv
          # source .venv/bin/activate

          echoline
          cleanup
          '';

  }
