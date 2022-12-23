# nix-graph-viewer

Simple utility to generate a HTML file to visualize sizes and closure dependency relations interactively.

You ask it to build an HTML file from a Nix store path and it generates a single browsable page with routes and all the cool stuff a single page application has to offer without having to host it anywhere.

To generate an HTML file of your current NixOS generation closure and open it in your default browser you can run:

```
nix run github:lucasew/nix-graph-viewer# -- -i /run/current-system -o /tmp/items.html && xdg-open /tmp/items.html
```

## The stack
This application has basically three parts:

- Frontend: a Svelte application that exposes a function `window.setData` to be used by a script.
- Generator: gets nix-store data from `nix path-info` and generates the JSON that the frontend expects.
- Integration: the Nix part. It builds the frontend based on the data from `package-lock.json` only and exposes the derivations as nix files and the `flake.nix`.

You can `npm install && npm run dev` the frontend directly but to feed it data you will need to import the JSON generated. You can generate the JSON directly by passing `-j true` and can feed it to the application by using `window.setData( content of the json file )` via the browser console. Another approach is to use a `window.setData(require('./path/to/file.json))` with Svelte's onMount function in `App.svelte`.
