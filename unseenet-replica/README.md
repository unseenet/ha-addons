# Unseenet council replica

Helps run the Unseenet network's own name registrar: a replica of a council
registrar ([UN-RFC 0054](https://unseenet.org/spec/un-rfc-0054/)) that decides
name claims by public rules, together with replicas run by others, so that no
single key holds the network's lists. It works for the one, shared network - it
is not a registrar of your own.

Built on the project's signed image `ghcr.io/unseenet/replica` (published from
Unseenet 0.7.0). See the Documentation tab ([DOCS.md](DOCS.md)) for setup.

**Experimental and pre-alpha** - not security reviewed.
