{{flutter_js}}
{{flutter_build_config}}

// Serve CanvasKit from our own bundle instead of Google's CDN, so the
// game runs fully self-hosted/offline — fitting, for a 1997 game.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
