{
  description = "Redis Sentinel build from redis/redis";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsMusl = pkgs.pkgsMusl;
        opensslStatic = pkgsMusl.openssl.override { static = true; };
        verInfo = builtins.fromJSON (builtins.readFile ./ver.json);

        redis-sentinel = pkgsMusl.stdenv.mkDerivation {
          pname = "redis-sentinel";
          version = verInfo.rev;

          src = pkgs.fetchFromGitHub {
            owner = "redis";
            repo = "redis";
            rev = verInfo.commit;
            hash = verInfo.hash;
          };

          nativeBuildInputs = with pkgsMusl; [
            pkg-config
          ];

          buildInputs = [
            opensslStatic
          ];

          env = {
            NIX_CFLAGS_COMPILE = "-O3 -fomit-frame-pointer -pipe";
          };

          makeFlags = [
            "PREFIX=$(out)"
            "LDFLAGS=-static"
            "BUILD_TLS=yes"
            "OPTIMIZATION=-O3"
            "USE_SYSTEMD=no"
            "MALLOC=libc"
            "DEBUG="
            "REDIS_CFLAGS=-DREDIS_STATIC=''"
          ];

          buildPhase = ''
            runHook preBuild
            export MAKEFLAGS="-j$NIX_BUILD_CORES"
            make $makeFlags CFLAGS="$NIX_CFLAGS_COMPILE"
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp src/redis-sentinel $out/bin/
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Redis Sentinel - High availability solution for Redis (static build)";
            homepage = "https://redis.io/";
            license = licenses.bsd3;
            platforms = platforms.unix;
            mainProgram = "redis-sentinel";
          };
        };
      in
      {
        packages = {
          default = redis-sentinel;
          redis-sentinel = redis-sentinel;
        };

        apps.default = {
          type = "app";
          program = "${redis-sentinel}/bin/redis-sentinel";
          meta = redis-sentinel.meta;
        };
      }
    );
}
