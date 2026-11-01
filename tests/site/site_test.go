// Package sitetests builds the site with Hugo and checks facts about the result: the security
// controls of decision 0005 (threat model T3 to T6) and the content validation (requirement R4).
//
// Each test copies the site into its own temporary folder, adds the fixture files it needs and
// runs Hugo there, so no test touches the real content and the tests can run in parallel.
package sitetests

import (
	"errors"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"golang.org/x/net/html"
)

// hugoBinary is the Hugo pinned in the development container (decision 0003).
const hugoBinary = "hugo"

// siteParts returns the parts of the repository a build needs. A function, not a package-level
// slice, so no test can change the list for the others.
func siteParts() []string {
	return []string{"hugo.toml", "archetypes", "assets", "content", "layouts"}
}

// buildResult is what a Hugo run left behind.
type buildResult struct {
	failed    bool   // Hugo exited with an error
	log       string // Hugo's combined output
	outputDir string // the built site, when the build succeeded
}

// repositoryRoot returns the repository root, two levels above this package.
func repositoryRoot(t *testing.T) string {
	t.Helper()
	root, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("finding the repository root: %v", err)
	}
	if _, err := os.Stat(filepath.Join(root, "hugo.toml")); err != nil {
		t.Fatalf("no hugo.toml in %s: %v", root, err)
	}
	return root
}

// newSiteCopy copies the site into a fresh temporary folder and returns that folder.
func newSiteCopy(t *testing.T) string {
	t.Helper()
	root := repositoryRoot(t)
	siteDir := t.TempDir()
	for _, part := range siteParts() {
		copyPart(t, filepath.Join(root, part), filepath.Join(siteDir, part))
	}
	return siteDir
}

// copyPart copies one file or folder of the site.
func copyPart(t *testing.T, source, destination string) {
	t.Helper()
	info, err := os.Stat(source)
	if err != nil {
		t.Fatalf("reading %s: %v", source, err)
	}
	if info.IsDir() {
		err = os.CopyFS(destination, os.DirFS(source))
	} else {
		err = copyFile(source, destination)
	}
	if err != nil {
		t.Fatalf("copying %s: %v", source, err)
	}
}

func copyFile(source, destination string) error {
	content, err := os.ReadFile(source)
	if err != nil {
		return err
	}
	return os.WriteFile(destination, content, 0o644)
}

// writeSiteFile writes content to a path inside the site copy, creating folders as needed.
func writeSiteFile(t *testing.T, siteDir, relativePath, content string) {
	t.Helper()
	path := filepath.Join(siteDir, relativePath)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("creating the folder for %s: %v", relativePath, err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("writing %s: %v", relativePath, err)
	}
}

// copyFixture copies a file from testdata into the site copy.
func copyFixture(t *testing.T, siteDir, fixture, relativePath string) {
	t.Helper()
	content, err := os.ReadFile(filepath.Join("testdata", fixture))
	if err != nil {
		t.Fatalf("reading fixture %s: %v", fixture, err)
	}
	writeSiteFile(t, siteDir, relativePath, string(content))
}

// buildSite runs Hugo on the site copy, with warnings as failures as in the real build
// (decision 0005). Extra environment entries (KEY=value) are added to Hugo's environment only,
// so tests that use them can still run in parallel.
func buildSite(t *testing.T, siteDir string, extraEnvironment ...string) buildResult {
	t.Helper()
	outputDir := filepath.Join(t.TempDir(), "public")
	command := exec.CommandContext(t.Context(), hugoBinary, "--panicOnWarning",
		"--source", siteDir, "--destination", outputDir, "--cacheDir", t.TempDir())
	command.Env = append(os.Environ(), extraEnvironment...)
	output, err := command.CombinedOutput()
	if _, isExitError := errors.AsType[*exec.ExitError](err); err != nil && !isExitError {
		t.Fatalf("running %s: %v", hugoBinary, err)
	}
	return buildResult{failed: err != nil, log: string(output), outputDir: outputDir}
}

// requireBuildSucceeded stops the test when the build failed, showing Hugo's output.
func requireBuildSucceeded(t *testing.T, result buildResult) {
	t.Helper()
	if result.failed {
		t.Fatalf("the build failed:\n%s", result.log)
	}
}

// requireBuildFailedNaming checks that the build failed and that its output names each value.
func requireBuildFailedNaming(t *testing.T, result buildResult, offendingValues ...string) {
	t.Helper()
	if !result.failed {
		t.Fatalf("the build succeeded; it should have failed naming %q", offendingValues)
	}
	for _, value := range offendingValues {
		if !strings.Contains(result.log, value) {
			t.Errorf("the build failed without naming %q:\n%s", value, result.log)
		}
	}
}

// parsePage parses one built page.
func parsePage(t *testing.T, result buildResult, relativePath string) *html.Node {
	t.Helper()
	file, err := os.Open(filepath.Join(result.outputDir, relativePath))
	if err != nil {
		t.Fatalf("opening built page %s: %v", relativePath, err)
	}
	defer file.Close() // read only: a failed close loses nothing
	document, err := html.Parse(file)
	if err != nil {
		t.Fatalf("parsing built page %s: %v", relativePath, err)
	}
	return document
}

// builtPages returns the paths of every HTML page in the built site, relative to it.
func builtPages(t *testing.T, result buildResult) []string {
	t.Helper()
	var pages []string
	err := fs.WalkDir(os.DirFS(result.outputDir), ".", func(path string, entry fs.DirEntry, err error) error {
		if err == nil && !entry.IsDir() && strings.HasSuffix(path, ".html") {
			pages = append(pages, path)
		}
		return err
	})
	if err != nil || len(pages) == 0 {
		t.Fatalf("listing built pages (found %d): %v", len(pages), err)
	}
	return pages
}

// elements returns the element nodes of a document that satisfy matches.
func elements(document *html.Node, matches func(*html.Node) bool) []*html.Node {
	var found []*html.Node
	for node := range document.Descendants() {
		if node.Type == html.ElementNode && matches(node) {
			found = append(found, node)
		}
	}
	return found
}

// attribute returns the value of an element's attribute and whether it is present.
func attribute(node *html.Node, name string) (string, bool) {
	for _, attr := range node.Attr {
		if attr.Key == name {
			return attr.Val, true
		}
	}
	return "", false
}
