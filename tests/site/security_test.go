package sitetests

import (
	"os/exec"
	"slices"
	"strings"
	"testing"

	"golang.org/x/net/html"
)

// T3: no page shows Hugo's version (disableHugoGeneratorInject; security rule 5).
func TestNoPageHasAGeneratorTag(t *testing.T) {
	t.Parallel()
	result := buildSite(t, newSiteCopy(t))
	requireBuildSucceeded(t, result)
	for _, page := range builtPages(t, result) {
		if tags := elements(parsePage(t, result, page), isGeneratorTag); len(tags) > 0 {
			t.Errorf("%s has a generator meta tag", page)
		}
	}
}

func isGeneratorTag(node *html.Node) bool {
	name, _ := attribute(node, "name")
	return node.Data == "meta" && strings.EqualFold(name, "generator")
}

// T4: code is highlighted with CSS classes, never inline styles (noClasses = false; security
// rule 1). The first check proves the page really contains a code block, so the second cannot
// pass just because there was nothing to highlight.
func TestCodeHighlightingUsesClassesNotInlineStyles(t *testing.T) {
	t.Parallel()
	siteDir := newSiteCopy(t)
	copyFixture(t, siteDir, "code-block.md", "content/code-block-probe.md")
	result := buildSite(t, siteDir)
	requireBuildSucceeded(t, result)
	page := parsePage(t, result, "code-block-probe/index.html")
	if len(elements(page, isElement("pre"))) == 0 {
		t.Fatal("the page has no code block")
	}
	for _, node := range elements(page, hasStyleAttribute) {
		t.Errorf("<%s> has an inline style attribute", node.Data)
	}
	if len(elements(page, hasClass("chroma"))) == 0 {
		t.Error("the code block is not highlighted by classes (no element with class chroma)")
	}
}

func isElement(tag string) func(*html.Node) bool {
	return func(node *html.Node) bool { return node.Data == tag }
}

func hasClass(class string) func(*html.Node) bool {
	return func(node *html.Node) bool {
		classes, _ := attribute(node, "class")
		return slices.Contains(strings.Fields(classes), class)
	}
}

func hasStyleAttribute(node *html.Node) bool {
	_, present := attribute(node, "style")
	return present
}

// T5: raw HTML in Markdown never reaches a page (renderer.unsafe = false; security rule 3).
// Hugo leaves it out and warns, naming the file; the build treats warnings as failures
// (decision 0005), so such a page cannot be published at all. With unsafe = true there is no
// warning and the build succeeds, so this test fails.
func TestRawHTMLInMarkdownStopsTheBuild(t *testing.T) {
	t.Parallel()
	siteDir := newSiteCopy(t)
	copyFixture(t, siteDir, "raw-html.md", "content/raw-html-probe.md")
	result := buildSite(t, siteDir)
	requireBuildFailedNaming(t, result, "raw-html-probe.md", "warning-goldmark-raw-html")
}

// T6: a template cannot fetch from another site during the build (security.http.urls; security
// rule 2). The fixture fetches from a .test address, which never resolves: without the policy the
// build fails too, but from DNS, without naming the policy, so this test still fails then.
func TestRemoteFetchIsRefusedByPolicy(t *testing.T) {
	t.Parallel()
	siteDir := newSiteCopy(t)
	copyFixture(t, siteDir, "remote-fetch-probe.html", "layouts/_shortcodes/remote-fetch-probe.html")
	writeSiteFile(t, siteDir, "content/remote-fetch-probe.md",
		"---\ntitle: Remote fetch probe\n---\n{{< remote-fetch-probe >}}\n")
	requireBuildFailedNaming(t, buildSite(t, siteDir), "security.http.urls")
}

// T6: the build cannot run other programs (security.exec.allow). Hugo runs git when
// enableGitInfo is on, so the site copy is made a git repository and the setting is switched on
// through Hugo's environment. Without the policy, git runs and the build succeeds.
func TestRunningProgramsIsRefusedByPolicy(t *testing.T) {
	t.Parallel()
	siteDir := newSiteCopy(t)
	makeGitRepository(t, siteDir)
	result := buildSite(t, siteDir, "HUGO_ENABLEGITINFO=true")
	requireBuildFailedNaming(t, result, "security.exec.allow")
}

// makeGitRepository commits the site copy, with an identity given on the command line so the
// user's own git configuration is never needed or touched.
func makeGitRepository(t *testing.T, siteDir string) {
	t.Helper()
	identity := []string{"-c", "user.name=site tests", "-c", "user.email=site-tests@example.invalid"}
	for _, arguments := range [][]string{{"init", "--quiet"}, {"add", "--all"}, {"commit", "--quiet", "--message", "fixture"}} {
		command := exec.CommandContext(t.Context(), "git", append(identity, arguments...)...)
		command.Dir = siteDir
		if output, err := command.CombinedOutput(); err != nil {
			t.Fatalf("git %s: %v\n%s", arguments[0], err, output)
		}
	}
}

// T6: each of Hugo's embed shortcodes stops the build, naming the file (layouts/_shortcodes;
// security rule 2). Each case uses arguments the built-in shortcode accepts, so that without the
// override YouTube, Vimeo and Instagram would build and embed. vimeo_simple, x and x_simple
// would fail even then, on the fetch policy; the override must stop them first, so the failure
// must not name that policy.
func TestEmbedShortcodesAreRefused(t *testing.T) {
	t.Parallel()
	cases := []struct{ shortcode, call string }{
		{"youtube", `{{< youtube id="dQw4w9WgXcQ" >}}`},
		{"vimeo", `{{< vimeo id="55073825" >}}`},
		{"vimeo_simple", `{{< vimeo_simple id="55073825" >}}`},
		{"x", `{{< x user="golang" id="1" >}}`},
		{"x_simple", `{{< x_simple user="golang" id="1" >}}`},
		{"instagram", `{{< instagram "CxOWiQNP2MO" >}}`},
	}
	for _, testCase := range cases {
		t.Run(testCase.shortcode, func(t *testing.T) {
			t.Parallel()
			siteDir := newSiteCopy(t)
			writeSiteFile(t, siteDir, "content/embed-probe.md", "---\ntitle: Embed probe\n---\n"+testCase.call+"\n")
			result := buildSite(t, siteDir)
			requireBuildFailedNaming(t, result, "embed-probe.md", `"`+testCase.shortcode+`"`)
			if strings.Contains(result.log, "security.http.urls") {
				t.Errorf("the fetch policy stopped %s, not its override:\n%s", testCase.shortcode, result.log)
			}
		})
	}
}
