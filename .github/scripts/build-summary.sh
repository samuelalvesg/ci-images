#!/usr/bin/env bash
# Writes the job summary of one image build: what happened, where it came from, which tool versions the image carries.
# Called by _build-image.yml at the end of the job (also when it failed). It only reports: every lookup is allowed to fail.
#
# Environment: NAME VERSION IMAGE TAGS DIGEST HASH HASH_TAG BASE BASE_DIGEST VERSIONS
#              PUBLISH SKIPPED JOB_STATUS STARTED EVENT REF_NAME SHA PR_NUMBER RUN_URL
#   VERSIONS: one `Label=command` per line, run inside the image; the first line of the output is the value.
# The summary goes to $GITHUB_STEP_SUMMARY (or stdout when it is not set, to try the script by hand).
out="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

cell() { local v="${1//|/\\|}"; printf '%s' "${v:0:160}"; }

duration() {
  [ -n "${STARTED:-}" ] || return 0
  local s=$(( $(date +%s) - STARTED ))
  if [ "$s" -ge 60 ]; then printf '%d min %d s' $((s / 60)) $((s % 60)); else printf '%d s' "$s"; fi
}

if [ "${JOB_STATUS:-}" != "success" ]; then
  result="❌ ${JOB_STATUS:-failed}: see the log of the failed step"
elif [ "${SKIPPED:-false}" = "true" ]; then
  result="♻️ reused: the published image already has these exact inputs, nothing was rebuilt"
elif [ "${PUBLISH:-false}" = "true" ]; then
  result="✅ built, tested and published"
else
  result="✅ built and tested, not published (pull request)"
fi

sha="${SHA:-}"
origin="\`${sha:0:7}\` on \`${REF_NAME:-?}\` (${EVENT:-?})"
[ -n "${PR_NUMBER:-}" ] && origin="$origin, pull request #$PR_NUMBER"

local_image=false
if [ "${SKIPPED:-false}" != "true" ] && [ "${JOB_STATUS:-}" = "success" ] && docker image inspect "$IMAGE" >/dev/null 2>&1; then local_image=true; fi

digest="${DIGEST:-}"
if [ -z "$digest" ] && [ "${SKIPPED:-false}" = "true" ] && [ -n "${HASH_TAG:-}" ]; then
  digest="$(docker buildx imagetools inspect "$HASH_TAG" --format '{{.Manifest.Digest}}' 2>/dev/null || true)"
fi

{
  echo "## $NAME $VERSION"
  echo
  echo "$result"
  echo
  echo "| | |"
  echo "|---|---|"
  echo "| Image | \`$IMAGE\` |"
  echo "| Source | $origin · [run](${RUN_URL:-#}) |"
  if [ -n "${BASE:-}" ]; then
    echo "| Base | \`$BASE\`${BASE_DIGEST:+ · \`$BASE_DIGEST\`} |"
  fi
  hash="${HASH:-}"
  [ -n "$hash" ] && echo "| Content hash | \`content-${hash:0:16}\` (inputs: build context, build args, version, base digest, test, workflow) |"
  [ -n "$digest" ] && echo "| Digest | \`$digest\` |"
  if [ "$local_image" = "true" ]; then
    size="$(docker image inspect --format '{{.Size}}' "$IMAGE" 2>/dev/null || true)"
    [ -n "$size" ] && echo "| Size | $(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "$size B") on disk (uncompressed) |"
  fi
  case "${SCAN_OUTCOME:-}" in
    success) echo "| Vulnerability scan | ✅ finished (HIGH and CRITICAL with a fix; the findings are in the step log) |" ;;
    failure) echo "| Vulnerability scan | ⚠️ did not finish (timeout or scanner error); the publication was not blocked |" ;;
  esac
  d="$(duration)"; [ -n "$d" ] && echo "| Job time | $d |"
  echo
} >> "$out"

if [ "$local_image" = "true" ] && [ -n "${VERSIONS:-}" ]; then
  snippet=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    label="${line%%=*}"; cmd="${line#*=}"
    snippet+="printf '%s\t%s\n' $(printf '%q' "$label") \"\$( { $cmd ; } 2>&1 | head -1 )\""$'\n'
  done <<< "$VERSIONS"
  tools="$(docker run --rm -e HOME=/github/home "$IMAGE" bash -c "$snippet" 2>/dev/null || true)"
  if [ -n "$tools" ]; then
    {
      echo "### Inside the image"
      echo
      echo "| Tool | Version |"
      echo "|---|---|"
      while IFS=$'\t' read -r label value; do
        [ -z "$label" ] && continue
        case "$value" in ""|*"command not found"*|*"No such file"*|*"cannot access"*) value="n/a" ;; esac
        echo "| $(cell "$label") | \`$(cell "$value")\` |"
      done <<< "$tools"
      echo
    } >> "$out"
  fi
fi

# The `dev.*` labels the Dockerfiles set (tool versions fixed by build arguments). A reused image is not pulled: its labels come from the registry.
labels=""
if [ "$local_image" = "true" ]; then
  labels="$(docker image inspect --format '{{range $k, $v := .Config.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' "$IMAGE" 2>/dev/null | grep '^dev\.' | sort || true)"
elif [ "${SKIPPED:-false}" = "true" ] && [ -n "${HASH_TAG:-}" ]; then
  labels="$(docker buildx imagetools inspect "$HASH_TAG" --format '{{range $k, $v := .Image.Config.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep '^dev\.' | sort || true)"
fi
if [ -n "$labels" ]; then
  {
    echo "### Labels (build arguments the image was built with)"
    echo
    echo "| Label | Value |"
    echo "|---|---|"
    while IFS='=' read -r k v; do [ -n "$k" ] && echo "| \`$k\` | \`$(cell "$v")\` |"; done <<< "$labels"
    echo
  } >> "$out"
fi

if [ -n "${TAGS:-}" ] && [ "${PUBLISH:-false}" = "true" ] && [ "${SKIPPED:-false}" != "true" ] && [ "${JOB_STATUS:-}" = "success" ]; then
  {
    echo "### Tags published"
    echo
    while IFS= read -r t; do [ -n "$t" ] && echo "- \`$t\`"; done <<< "$TAGS"
    echo
    echo "The vulnerability scan (HIGH and CRITICAL, fixed only) is in the log of the step \"Scan image for vulnerabilities\"."
  } >> "$out"
fi
exit 0
