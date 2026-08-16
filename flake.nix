# #-------------------------------------------------------------#
# | nix-pins — one nixpkgs pin, followed everywhere              |
# #-------------------------------------------------------------#
#
# This flake exports no outputs. Its only job is to own a flake.lock
# that other repos follow, so every project resolves to one nixpkgs
# rev and therefore one stdenv. Two nixpkgs revs share no build
# artifacts at all, so a second rev costs a full toolchain closure.
#
# Consumers follow the inputs; they do not import anything:
#
#   inputs.pins.url = "github:OWNER/nix-pins";
#   inputs.nixpkgs.follows = "pins/nixpkgs";
#   inputs.home-manager.follows = "pins/home-manager";
#
# Admission rule: an input belongs here only when two or more repos
# use it. A consumer fetches every input of this flake when it locks,
# so a dormant input taxes every project. Project-specific inputs stay
# in the project.
#
# Channel: nixpkgs-unstable, not a release branch. It only advances
# after Hydra populates the binary cache, so it is as well cached as a
# release branch; the cost is that stdenv bumps land regularly and
# each one is a world rebuild.
{
  description = "One nixpkgs pin, followed everywhere. Exports no outputs — consumers follow its inputs.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The canonical micro-flake that exists to be followed; pinning it
    # here keeps consumers from each locking their own copy.
    systems.url = "github:nix-systems/default";
  };

  # Intentionally empty. This flake is a pin, not a library — adding
  # outputs invites consumers to import it, which is how a pin repo
  # turns into a framework nobody can upgrade.
  outputs = _: {};
}
