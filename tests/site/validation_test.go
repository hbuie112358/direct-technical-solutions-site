package sitetests

import (
	"testing"
)

// R4: a project entry with a missing field or an unknown status stops the build, naming the file
// and the problem; a valid entry builds (layouts/_partials/validate-project.html, hugo.toml
// params.projects).
func TestInvalidProjectEntriesStopTheBuild(t *testing.T) {
	t.Parallel()
	cases := []struct {
		name            string
		frontMatter     string
		offendingValues []string
	}{
		{"missing title", "description: d\nstatus: live\n", []string{"projects/probe.md", "title"}},
		{"missing description", "title: Probe\nstatus: live\n", []string{"projects/probe.md", "description"}},
		{"empty description", "title: Probe\ndescription: ''\nstatus: live\n", []string{"projects/probe.md", "description"}},
		{"missing status", "title: Probe\ndescription: d\n", []string{"projects/probe.md", "status"}},
		{"unknown status", "title: Probe\ndescription: d\nstatus: finished\n", []string{"projects/probe.md", "finished"}},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			t.Parallel()
			siteDir := newSiteCopy(t)
			writeSiteFile(t, siteDir, "content/projects/probe.md", "---\n"+testCase.frontMatter+"---\n")
			requireBuildFailedNaming(t, buildSite(t, siteDir), testCase.offendingValues...)
		})
	}
}

// R4: a valid entry builds, and its status is shown on its page and in the projects list.
func TestValidProjectEntryBuildsAndShowsItsStatus(t *testing.T) {
	t.Parallel()
	siteDir := newSiteCopy(t)
	writeSiteFile(t, siteDir, "content/projects/probe.md",
		"---\ntitle: Probe\ndescription: A test entry.\nstatus: in-development\n---\n")
	result := buildSite(t, siteDir)
	requireBuildSucceeded(t, result)
	for _, page := range []string{"projects/probe/index.html", "projects/index.html"} {
		if len(elements(parsePage(t, result, page), hasClass("status--in-development"))) == 0 {
			t.Errorf("%s does not show the status in-development", page)
		}
	}
}

// The build refuses any Hugo but the pinned one (layouts/_partials/check-hugo-version.html). The
// required version is changed through Hugo's environment (HUGO_PARAMS_*), so no file is edited.
func TestWrongHugoVersionStopsTheBuild(t *testing.T) {
	t.Parallel()
	const impossibleVersion = "0.0.1"
	result := buildSite(t, newSiteCopy(t), "HUGO_PARAMS_REQUIREDHUGOVERSION="+impossibleVersion)
	requireBuildFailedNaming(t, result, impossibleVersion)
}
