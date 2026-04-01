# invoice

This is just invoice Ninja[https://github.com/invoiceninja/invoiceninja]
wrapped in nix for containers and run using podman pods.

I used krump[https://github.com/serverplumber/krump]

Out of hubris I figured this would be straight forward.
I forgot how much of a precious snowflake php applications can
be. Tooling this thing to actually run in production is a serious
project, I'll get back to it later--ha, maybe.

Here's the TODO, on the off chance somebody is looking for a devOps
exercise.

- make an invoiceninja-migration image
- add versioning to the container names, always "latest" is bad
- write a justfile for running migrations
- write a justfile for moving to from various environments

Maybe this is a reason to learn Clan[https://clan.lol]
