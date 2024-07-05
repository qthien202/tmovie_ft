@echo off
fvm flutter build web --release
git status
git add .
git commit -m "feat: new version"
