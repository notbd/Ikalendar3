#!/usr/bin/env bash
#
# Fails when shipped code could contact a host other than splatoon3.ink and assets.splatoon3.ink.
# Shipped code is every tracked file in the four product folders and the package's sources, except
# the Debug-only fixture module. It proves six things:
#
#   1  only `URLSessionTransport.swift` names a networking API (URLSession, Network, WebKit,
#      Safari views, AsyncImage, sockets), so every request goes through an `HTTPTransport`
#   2  only `Data+File.swift` calls a reader that takes a URL and would load an `https` one too
#      (any `contentsOf:` initialiser, such as `Data`'s, `String`'s or `NSImage`'s,
#      `NSImage(byReferencing:)`, ImageIO's `CGImageSource…CreateWithURL` functions, Core
#      Graphics' `CGDataProvider` and `CGPDFDocument` initialisers, `NSAttributedString(url:)`,
#      `LPMetadataProvider`, and every `AV…(url:)` and `InputStream(url:)` initialiser, each
#      also as `.init(url:)` or `.init(byReferencing:)` after a type annotation, such as
#      `let player: AVPlayer = .init(url: address)`, or with that argument wrapped onto a line
#      of its own; the client's `URLRequest` is the one
#      `.init(url:)` let through), and its `Data(readingFile:)` refuses any URL that is not a
#      file's
#   3  only `FeedClient.swift` sends on a transport, and its one `send(to:)` refuses any address
#      `Source.serves` does not accept
#   4  the transport's session follows a redirect only to an address `Source.serves` accepts
#      (`RedirectGuard`), so no answer takes a request anywhere else
#   5  `Source.hosts` is exactly the two hosts, so the feed account's avatar on Nintendo's host
#      (an address the feed carries) is refused like any other
#   6  every address written in shipped code is on the two hosts or is a link the player opens in
#      the browser, Mail or the App Store, listed below with what opens it
#
# Being static, it proves the code's shape; the package tests run the refusals
# (FileReadTests a URL that is not a file's, URLSessionTransportTests the redirects,
# SplatfestArtTests an address off the two hosts).
#
# Usage: scripts/check-hosts.sh
#
# scripts/verify.sh runs it.

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

readonly FEED_HOSTS='"splatoon3.ink", "assets.splatoon3.ink"'
readonly TRANSPORT=Ikalendar3Kit/Sources/IkaCore/Network/URLSessionTransport.swift
readonly CLIENT=Ikalendar3Kit/Sources/IkaCore/Network/FeedClient.swift
readonly SOURCE=Ikalendar3Kit/Sources/IkaCore/Network/Feed.swift
readonly FILE_READER=Ikalendar3Kit/Sources/IkaCore/Data+File.swift

# Hosts of links the player opens; the app never fetches from them.
readonly LINK_HOSTS=(
  'ikalendar.app'         # About: website and privacy policy (also named in the User-Agent)
  'twitter.com'           # About: the developer's profile
  'apps.apple.com'        # About: App Store pages of ikalendar 3 and ikalendar 2
  'github.com'            # About and Credits: source code of ikalendar 3 and splatoon3.ink
  'www.nintendo.com'      # Credits: Splatoon 3's regional sites
  'splatoon.nintendo.com' # Credits: Splatoon 3's global site
)

readonly SHIPPED=(Ikalendar3 Ikalendar3Widgets Ikalendar3Watch Ikalendar3WatchWidgets IkaResources
  Ikalendar3Kit/Sources ':!Ikalendar3Kit/Sources/IkaFixtures')

problems=()

# Prints `git grep` matches of a Perl pattern in shipped files, or nothing.
shipped_matches() {
  local status=0
  git grep -I -n -P "$1" -- "${SHIPPED[@]}" || status=$?
  ((status <= 1)) || exit "$status"
}

network=$(shipped_matches '\b(URLSession|URLSessionConfiguration|NSURLConnection|CFStream\w*|NW(Connection|PathMonitor|Browser|Listener|Endpoint)|WKWebView|SFSafariViewController|ASWebAuthenticationSession|AsyncImage|getaddrinfo|socket)\b|^import (Network|WebKit|SafariServices)\b' \
  | grep -v "^$TRANSPORT:" || true)
[[ -z $network ]] || problems+=("Networking APIs outside $TRANSPORT:"$'\n'"$network")

readers=$(shipped_matches '\bcontentsOf:|\bCG\w+CreateWithURL\b|\bCG(DataProvider|PDFDocument)\(|\bNSImage\(byReferencing:|\bNSAttributedString\(url:|\bLPMetadataProvider\b|\b(AV\w+|InputStream)\(url:|\.init\((url|byReferencing):|^\s*(url|byReferencing):' \
  | grep -v "^$FILE_READER:" | grep -v "^$CLIENT:[0-9]*: *var request: URLRequest = \.init(url:" || true)
[[ -z $readers ]] || problems+=("Readers that take a URL outside $FILE_READER (use Data(readingFile:)):"$'\n'"$readers")
grep -q 'guard url.isFileURL else' "$FILE_READER" \
  || problems+=("$FILE_READER no longer refuses URLs that are not a file's.")

senders=$(shipped_matches '\.send\(' | grep -v "^$CLIENT:" || true)
[[ -z $senders ]] || problems+=("Transport sends outside $CLIENT:"$'\n'"$senders")
grep -q 'guard Source.serves(url) else' "$CLIENT" \
  || problems+=("$CLIENT no longer refuses addresses off the two hosts before it sends.")
{ grep -q 'delegate: RedirectGuard()' "$TRANSPORT" \
  && grep -q 'guard let target = request.url, Source.serves(target) else' "$TRANSPORT"; } \
  || problems+=("$TRANSPORT no longer refuses redirects off the two hosts.")
grep -q "static let hosts: Set<String> = \[$FEED_HOSTS\]" "$SOURCE" \
  || problems+=("Source.hosts in $SOURCE is not exactly [$FEED_HOSTS].")

# Every address in shipped files, as "<file>:<line>: <host>". The plist DTD is a document type,
# never fetched.
addresses=$(shipped_matches 'https?://' | grep -v 'apple.com/DTDs/PropertyList' \
  | perl -ne 'my ($where) = /^([^:]+:\d+):/; print "$where: $1\n" while m{https?://([A-Za-z0-9.-]+)}g')
allowed=$(printf '%s\n' "${FEED_HOSTS//[\", ]/$'\n'}" "${LINK_HOSTS[@]}" | grep -v '^$')
unlisted=$(ALLOWED="$allowed" awk 'BEGIN { n = split(ENVIRON["ALLOWED"], list, "\n"); for (i = 1; i <= n; i++) ok[list[i]] = 1 }
  !($2 in ok)' <<<"$addresses")
[[ -z $unlisted ]] || problems+=("Addresses on hosts that are neither the two feed hosts nor a listed link:"$'\n'"$unlisted")

if ((${#problems[@]} > 0)); then
  printf '%s\n\n' "${problems[@]}" >&2
  exit 1
fi

printf 'Requests only to %s; links to %s\n' "${FEED_HOSTS//\"/}" "$(IFS=,; printf '%s' "${LINK_HOSTS[*]}" | sed 's/,/, /g')"
