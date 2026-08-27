/**
 * MovieNest TMDB proxy.
 *
 * A thin, read-only proxy in front of the TMDB REST API. The app calls this
 * function instead of TMDB directly, so the TMDB API key lives only in the
 * server's secret store and never ships inside the mobile binary.
 *
 * Hardening layers:
 *  - Secret Manager holds the TMDB key (never in source, never in the client).
 *  - A path allowlist means the proxy can only reach the endpoints the app
 *    actually uses — it can't be turned into a general-purpose TMDB relay.
 *  - A query-param allowlist strips anything the app doesn't send.
 *  - Firebase App Check (see ENFORCE_APP_CHECK below) restricts the proxy to
 *    requests from genuine builds of this app.
 *  - CDN cache headers keep TMDB traffic (and cost/latency) low.
 */

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

// TMDB key, stored in Secret Manager. Set it once with:
//   firebase functions:secrets:set TMDB_API_KEY
const TMDB_API_KEY = defineSecret("TMDB_API_KEY");

const TMDB_BASE_URL = "https://api.themoviedb.org/3";

// Flip to true only AFTER the Flutter app is sending App Check tokens
// (firebase_app_check wired up + provider registered in main.dart). Enabling it
// before that would reject every request from the app. See SETUP_FIREBASE.md.
const ENFORCE_APP_CHECK = false;

// Only these paths (exact match or prefix) may be proxied. Mirrors the
// endpoints used by TmdbRemoteDataSource in the Flutter app.
const ALLOWED_PATHS = [
  "/trending/movie/week",
  "/movie/popular",
  "/movie/top_rated",
  "/movie/now_playing",
  "/search/movie",
];

// Path patterns with a numeric id, e.g. /movie/123 and /movie/123/credits.
const ALLOWED_PATH_PATTERNS = [
  /^\/movie\/\d+$/,
  /^\/movie\/\d+\/credits$/,
];

// Query params the app is allowed to forward to TMDB. Anything else is dropped.
const ALLOWED_PARAMS = new Set([
  "language",
  "query",
  "include_adult",
  "page",
  "region",
]);

function isAllowedPath(path) {
  if (ALLOWED_PATHS.includes(path)) return true;
  return ALLOWED_PATH_PATTERNS.some((re) => re.test(path));
}

exports.tmdb = onRequest(
  {
    region: "us-central1",
    secrets: [TMDB_API_KEY],
    cors: true,
    memory: "128MiB",
    maxInstances: 10,
    // When true, callers must present a valid Firebase App Check token.
    enforceAppCheck: ENFORCE_APP_CHECK,
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    // req.path is everything after the function name, e.g. "/movie/popular".
    const path = req.path && req.path !== "/" ? req.path : "";
    if (!isAllowedPath(path)) {
      logger.warn("Blocked path", { path });
      res.status(403).json({ error: "Path not allowed" });
      return;
    }

    // Rebuild the querystring from the allowlist only.
    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(req.query)) {
      if (ALLOWED_PARAMS.has(key)) params.set(key, String(value));
    }
    params.set("api_key", TMDB_API_KEY.value());

    const url = `${TMDB_BASE_URL}${path}?${params.toString()}`;

    try {
      const upstream = await fetch(url, {
        headers: { Accept: "application/json" },
      });
      const body = await upstream.text();

      if (!upstream.ok) {
        logger.warn("TMDB error", { path, status: upstream.status });
      }

      // Cache successful reads at the CDN edge to cut cost and latency.
      if (upstream.ok) {
        res.set("Cache-Control", "public, max-age=300, s-maxage=600");
      }
      res.status(upstream.status).type("application/json").send(body);
    } catch (err) {
      logger.error("Proxy request failed", { path, message: err.message });
      res.status(502).json({ error: "Upstream request failed" });
    }
  },
);
