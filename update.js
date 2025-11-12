#!/usr/bin/env zx

import verJson from "@3-/nix/verJson.js";

const ROOT = import.meta.dirname;

await verJson(ROOT, "redis/redis", process.argv[3]);
