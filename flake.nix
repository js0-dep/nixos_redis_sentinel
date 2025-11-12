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
        verInfo = builtins.fromJSON (builtins.readFile ./ver.json);
        
        redis-sentinel = pkgs.clangStdenv.mkDerivation {
          pname = "redis-sentinel";
          version = verInfo.rev;

          src = pkgs.fetchFromGitHub {
            owner = "redis";
            repo = "redis";
            rev = verInfo.commit;
            hash = verInfo.hash;
          };

          nativeBuildInputs = with pkgs; [ 
            pkg-config
            tcl
            which
          ];

          buildInputs = with pkgs; [
            openssl
            jemalloc
            lua
          ];

          env = {
            NIX_CFLAGS_COMPILE = "-O3 -fomit-frame-pointer -pipe -fstack-protector-strong -D_FORTIFY_SOURCE=2";
          };

          makeFlags = [
            "PREFIX=$(out)"
            "LDFLAGS=-Wl,-O1 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
            "BUILD_TLS=yes"
            "OPTIMIZATION=-O3"
            "USE_SYSTEM_JEMALLOC=yes"
            "USE_SYSTEM_LUA=yes"
            "USE_SYSTEMD=no"
            "DEBUG="
            "REDIS_CFLAGS=-DREDIS_STATIC=''"
          ];

          buildPhase = ''
            runHook preBuild
            export MAKEFLAGS="-j$NIX_BUILD_CORES"
            make redis-sentinel $makeFlags CFLAGS="$NIX_CFLAGS_COMPILE"
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp src/redis-sentinel $out/bin/
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Redis Sentinel - High availability solution for Redis";
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
