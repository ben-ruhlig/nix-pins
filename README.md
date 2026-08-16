# nix-pins

Shared flake inputs to pin in all projects for better binary cache overlap.

This flake **exports no outputs**. Its only job is to own a `flake.lock` that
other repos follow, so every project resolves to one `nixpkgs` rev.

## Why

Two different `nixpkgs` revisions produce two different `stdenv` bootstrap
chains. Nothing built against one is reusable by the other, so a second
revision costs a full toolchain closure on disk and a full set of binary cache
misses. One pin gives every project the same `stdenv`, and therefore the same
store paths.

This does *not* share Nix's evaluation cache between repos. That cache is keyed
on a flake's fingerprint, which includes the whole `flake.lock`, so two repos
never share it. The win is build artifacts, not evaluation.

## Use

Add this flake as an input, then follow its inputs instead of declaring your
own:

```nix
{
  inputs = {
    pins.url = "github:OWNER/nix-pins";

    nixpkgs.follows = "pins/nixpkgs";
    home-manager.follows = "pins/home-manager";
    nix-darwin.follows = "pins/nix-darwin";
    flake-parts.follows = "pins/flake-parts";
    sops-nix.follows = "pins/sops-nix";

    # Project-specific inputs stay declared locally.
    my-thing.url = "github:OWNER/my-thing";
    my-thing.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

`follows = "pins/home-manager"` is transitive: `home-manager` already follows
this flake's `nixpkgs` here, so consumers inherit that alignment without
restating it.

## What belongs here

An input belongs here only when **two or more repos use it**. A consumer
fetches every input of this flake when it locks, so a dormant input taxes every
project. Anything one project needs stays in that project.

Two categories are deliberately absent:

- **A second `nixpkgs`** (a stable branch alongside the main pin). That is the
  exact duplication this repo exists to remove. Pulling one package from a
  second `nixpkgs` drags that package's whole closure, built against a
  different `stdenv`. Add one only against a concrete need, never
  speculatively.
- **Flakes that pin their own `nixpkgs` on purpose.** Some upstreams pin a
  specific revision so their binaries come from their own binary cache. Making
  those follow this pin means building them from source. Deduplicating them
  makes builds slower, not faster.

## Channel

`nixpkgs-unstable`, not a release branch.

`nixpkgs-unstable` advances only after Hydra finishes building and populating
`cache.nixos.org`, so it is as well cached as a release branch. The real cost
of unstable is churn: `stdenv` and `glibc` bumps land regularly, and each one
is a world rebuild.

To change channel, edit `nixpkgs.url` in `flake.nix`, then run
`nix flake update pins` in each consumer.

## Updating

```sh
nix flake update            # in this repo, then commit the lock
nix flake update pins       # in each consumer
```
