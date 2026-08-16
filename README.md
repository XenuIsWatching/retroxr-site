# retroxr.app

The player-facing website for [RetroXR](https://github.com/XenuIsWatching/RetroXR) — what
it is, how to get it, and how to play it.

Built with [Astro Starlight](https://starlight.astro.build/) plus
[starlight-blog](https://github.com/HiDeoo/starlight-blog). Ships zero JavaScript, and
search is built at compile time, so there is no runtime service to keep paid up.

## Running it

```bash
npm install
npm run dev        # http://localhost:4321
npm run build      # fails on a broken internal link, so it is a real gate
npm run preview
```

## Layout

```
src/content/docs/
  index.mdx          the landing page (Starlight's splash template)
  download.mdx       install, including a full Quest sideloading walkthrough
  blog/              the devlog — add a dated .md file and push
  guide/             the manual: playing, cores, platforms, the room, reference
src/components/      Feature, Turntable, Connector — all .astro, no JS shipped
src/assets/          images; Astro optimizes these to responsive webp
public/video/        mp4 clips (Astro does not process video)
public/CNAME         the custom domain — deleting it unsets the domain on deploy
```

## Publishing a devlog post

Add a file to `src/content/docs/blog/` with `title`, `date` (`YYYY-MM-DD`) and
`authors: ryan` in its frontmatter. That is the whole process.

## Where the artwork comes from

Nothing here is drawn by hand. The brand kit is the game repo's `game-icons/`, and the
palette in `src/styles/brand.css` is copied from its `Tools/gen_app_icons.py` — keep the
two in step.

The 3D turntables, connector stills and the plug-seating clip are all rendered from the
game's own models by throwaway Godot probes, kept in `tools/godot-probes/`. To regenerate:

```bash
cp tools/godot-probes/*.gd tools/godot-probes/*.tscn <retroxr>/RetroXR/Tools/
"$godot" --path RetroXR --resolution 320x240 --position 20,20 \
    res://Tools/prop_turntable.tscn -- --subject=rf_switch
```

They must run **windowed, never `--headless`** — a `SubViewport` on `UPDATE_ALWAYS` has no
GPU to service it under the dummy renderer and the run hangs. Frames land in
`RetroXR/probe_out/`; encode them with `imageio`. Delete the probes from the game repo
afterwards, per that project's convention.

## Deploying

`.github/workflows/deploy.yml` builds and publishes to GitHub Pages on a push to `main`.

Two things about the domain, both of which will waste an afternoon if missed:

- **`.app` is HSTS-preloaded**, so browsers refuse plain HTTP to it. Until GitHub has
  issued its certificate and *Enforce HTTPS* is on, the domain is not merely insecure — it
  is unreachable. Verify with `curl -sI`, not a browser.
- **Cloudflare's proxy must stay off** (grey cloud, "DNS only") while that certificate is
  issued, or the HTTP challenge never completes and it never arrives. Only consider the
  orange cloud afterwards, and then only with SSL/TLS set to **Full** — never *Flexible*,
  which loops against Pages' own HTTPS redirect.

## License

Site content and code © Ryan McClelland. RetroXR itself is GPL-3.0 with a linking
exception — see [the game repository](https://github.com/XenuIsWatching/RetroXR).
