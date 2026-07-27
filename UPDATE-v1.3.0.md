# Updating an existing checkout to v1.3.0

1. Switch to the feature branch:

   ```powershell
   git switch feature/doctor
   ```

2. Copy the contents of this archive over the repository root, replacing existing files.

3. Verify and commit:

   ```powershell
   git status
   git add .
   git commit -m "Add lau doctor diagnostics"
   git push -u origin feature/doctor
   ```

4. Open a pull request with `develop` as the base and `feature/doctor` as the compare branch.
