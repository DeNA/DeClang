/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestCLIUsesUserProfileFallback(t *testing.T) {
	tmpDir := t.TempDir()
	binPath := filepath.Join(tmpDir, "gen_config_test_bin")
	buildCmd := exec.Command("go", "build", "-o", binPath, "GenConfig.go")
	if out, err := buildCmd.CombinedOutput(); err != nil {
		t.Fatalf("go build failed: %v\n%s", err, out)
	}

	userProfile := filepath.Join(tmpDir, "winhome")
	declangDir := filepath.Join(userProfile, ".DeClang")
	if err := os.MkdirAll(declangDir, 0755); err != nil {
		t.Fatal(err)
	}
	preJSON := `{"build_seed":"hello, i am seed","flatten":[{"name":".*main.*"}]}`
	if err := os.WriteFile(filepath.Join(declangDir, "config.pre.json"), []byte(preJSON), 0644); err != nil {
		t.Fatal(err)
	}

	cmd := exec.Command(binPath, "-seed", "win-seed-1")
	cmd.Env = []string{
		"DECLANG_HOME=",
		"HOME=",
		"USERPROFILE=" + userProfile,
		"PATH=" + os.Getenv("PATH"),
	}
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("expected USERPROFILE fallback to succeed, got err=%v\noutput:\n%s", err, out)
	}

	generatedBytes, err := os.ReadFile(filepath.Join(declangDir, "config.json"))
	if err != nil {
		t.Fatalf("config.json not generated in USERPROFILE: %v", err)
	}

	var cfg Config
	if err := json.Unmarshal(generatedBytes, &cfg); err != nil {
		t.Fatalf("invalid generated json: %v", err)
	}
	if cfg.Build_seed != "win-seed-1" {
		t.Fatalf("expected build_seed 'win-seed-1', got %q", cfg.Build_seed)
	}
	if len(cfg.Flattens) != 1 || len(cfg.Flattens[0].Seed) != 32 {
		t.Fatalf("expected 32-char flatten seed, got %+v", cfg.Flattens)
	}
}

func TestCLIFailsWithoutAnyHomeEnv(t *testing.T) {
	tmpDir := t.TempDir()
	binPath := filepath.Join(tmpDir, "gen_config_test_bin")
	buildCmd := exec.Command("go", "build", "-o", binPath, "GenConfig.go")
	if out, err := buildCmd.CombinedOutput(); err != nil {
		t.Fatalf("go build failed: %v\n%s", err, out)
	}

	cmd := exec.Command(binPath)
	cmd.Env = []string{
		"DECLANG_HOME=",
		"HOME=",
		"USERPROFILE=",
		"PATH=" + os.Getenv("PATH"),
	}
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected failure when all home env vars are empty, output:\n%s", out)
	}
	if strings.Contains(string(out), "/.DeClang//config.pre.json") || strings.Contains(string(out), "\"/.DeClang/") {
		t.Fatalf("unexpected fallback to root directory /.DeClang: %s", out)
	}
}

func TestCLIPathWithTrailingSlashAndRandomSeed(t *testing.T) {
	tmpDir := t.TempDir()
	binPath := filepath.Join(tmpDir, "gen_config_test_bin")
	buildCmd := exec.Command("go", "build", "-o", binPath, "GenConfig.go")
	if out, err := buildCmd.CombinedOutput(); err != nil {
		t.Fatalf("go build failed: %v\n%s", err, out)
	}

	cfgDir := filepath.Join(tmpDir, "cfg")
	if err := os.MkdirAll(cfgDir, 0755); err != nil {
		t.Fatal(err)
	}
	preJSON := `{"build_seed":"hello, i am seed","flatten":[{"name":"foo"}]}`
	if err := os.WriteFile(filepath.Join(cfgDir, "config.pre.json"), []byte(preJSON), 0644); err != nil {
		t.Fatal(err)
	}

	cmd := exec.Command(binPath, "-path", cfgDir+string(os.PathSeparator))
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("expected -path run to succeed, got err=%v\noutput:\n%s", err, out)
	}

	generatedBytes, err := os.ReadFile(filepath.Join(cfgDir, "config.json"))
	if err != nil {
		t.Fatal(err)
	}
	var cfg Config
	if err := json.Unmarshal(generatedBytes, &cfg); err != nil {
		t.Fatal(err)
	}
	if cfg.Build_seed == "hello, i am seed" || len(cfg.Build_seed) != 16 {
		t.Fatalf("expected 16-char randomized build_seed, got %q", cfg.Build_seed)
	}
}

func TestResolveHomeDirPrecedence(t *testing.T) {
	t.Setenv("DECLANG_HOME", "/declang")
	t.Setenv("HOME", "/home")
	t.Setenv("USERPROFILE", `C:\Users\alice`)
	if got := resolveHomeDir(); got != "/declang" {
		t.Fatalf("expected DECLANG_HOME to win, got %q", got)
	}

	t.Setenv("DECLANG_HOME", "")
	if got := resolveHomeDir(); got != "/home" {
		t.Fatalf("expected HOME fallback, got %q", got)
	}

	t.Setenv("HOME", "")
	if got := resolveHomeDir(); got != `C:\Users\alice` {
		t.Fatalf("expected USERPROFILE fallback, got %q", got)
	}

	t.Setenv("USERPROFILE", "")
	if _, err := resolveDefaultConfigDir(); err == nil {
		t.Fatalf("expected error when all home env vars are empty")
	}
}

func TestGenerateConfigFileWriteError(t *testing.T) {
	cfgDir := t.TempDir()
	preJSON := `{"build_seed":"seed","flatten":[{"name":"foo"}]}`
	if err := os.WriteFile(filepath.Join(cfgDir, "config.pre.json"), []byte(preJSON), 0644); err != nil {
		t.Fatal(err)
	}
	// Make target config.json a directory so writing fails.
	if err := os.Mkdir(filepath.Join(cfgDir, "config.json"), 0755); err != nil {
		t.Fatal(err)
	}

	if err := generateConfigFile(cfgDir, ""); err == nil {
		t.Fatalf("expected write error when config.json path is a directory")
	}
}
