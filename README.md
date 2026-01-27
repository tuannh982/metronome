# Metronome

A powerful, programmable metronome built with Flutter.

## Getting Started

To run this project locally, ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

To run the application in a web browser on port 8080, use:

```bash
flutter run --hot -d chrome --web-port=8080
```

## Deployment

To deploy this project to GitHub Pages, you need to build the web application and push the output to the `gh-pages` branch.

### 1. Build the Web App

Run the following command to build the project with the correct base href:

```bash
flutter build web --release --base-href "/metronome/"
```

### 2. Publish to GitHub Pages

Run these commands to push the `build/web` directory to the `gh-pages` branch:

```bash
# Force add the build folder (since it's usually gitignored)
git add build/web -f

# Commit the build
git commit -m "Deploy to GitHub Pages"

# Push the build folder to the gh-pages branch
git subtree push --prefix build/web origin gh-pages

# Clean up (undo the commit but keep the build files)
git reset --hard HEAD~1
```

> [!NOTE]
> Ensure that your GitHub repository settings under **Pages** are set to deploy from the `gh-pages` branch.
