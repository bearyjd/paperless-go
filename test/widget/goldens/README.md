# Golden tests

`matchesGoldenFile` does exact pixel comparison, which is sensitive to the
exact Flutter engine build (font rasterization/anti-aliasing differs by
engine version even with identical fonts loaded). These baselines are
generated against **Flutter 3.41.3** — the version `.github/workflows/ci.yml`
pins — not whatever Flutter is installed locally.

If these fail locally with small pixel-percentage diffs (not a real content
change) and your local `flutter --version` isn't `3.41.3`, that's expected —
trust CI, not your local run. To regenerate correctly:

```bash
# From the flutter/flutter repo, in a worktree so it doesn't disturb your
# regular install:
git worktree add /tmp/flutter-3413 3.41.3

# Copy this repo to scratch so an older Flutter's `pub get` never touches
# the real pubspec.lock:
rsync -a --exclude='.git' --exclude='build' --exclude='.dart_tool' ./ /tmp/scratch/

cd /tmp/scratch
export PUB_CACHE=/tmp/scratch/.pub-cache
/tmp/flutter-3413/bin/flutter pub get
/tmp/flutter-3413/bin/flutter test test/widget/goldens/ --update-goldens

# Copy the results back:
cp test/widget/goldens/goldens/*.png <real-repo>/test/widget/goldens/goldens/
```
