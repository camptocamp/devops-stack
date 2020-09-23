//+build mage

// Mostly this is used for building the website and some dev tasks.
package main

import (
	"fmt"
	"net/url"
	"os"
	"os/user"
	"regexp"
	"strings"

	env "github.com/Netflix/go-env"
	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
	"gopkg.in/src-d/go-git.v4"
	gitconfig "gopkg.in/src-d/go-git.v4/config"
)

type Environment struct {
	BaseDomain string `env:"BASE_DOMAIN,default=127-0-0-1.nip.io"`
	DockerHost string `env:"DOCKER_HOST,default=tcp://127.0.0.1:2376/"`

	RepoUrl      string
	Remote       string
	RemoteBranch string
	RemoteUrl    string

	ClusterName  string
	ArtifactsDir string
}

var environment Environment

// Builds the website.  If needed, it will compact the js as well.
func Build() error {
	mg.Deps(Env)
	//fmt.Printf(environment.BaseDomain)

	out, err := sh.Output("echo", "truc")
	if err != nil {
		return err
	}
	fmt.Printf(out)
	return nil
}

func Debug() error {
	mg.Deps(Env)

	fmt.Println("BASE_DOMAIN =", environment.BaseDomain)
	fmt.Println("DOCKER_HOST =", environment.DockerHost)

	usr, _ := user.Current()
	fmt.Println("UID =", usr.Uid)
	fmt.Println("GID =", usr.Gid)

	fmt.Println("REPO_URL =", environment.RepoUrl)
	fmt.Println("REMOTE =", environment.Remote)
	fmt.Println("REMOTE_BRANCH =", environment.RemoteBranch)
	fmt.Println("REMOTE_URL =", environment.RemoteUrl)

	fmt.Println("CLUSTER_NAME =", environment.ClusterName)
	fmt.Println("ARTIFACTS_DIR =", environment.ArtifactsDir)

	return nil
}

func Env() error {
	es, err := env.UnmarshalFromEnviron(&environment)
	if err != nil {
		return err
	}

	if ciProjectUrl, ok := es["CI_PROJECT_URL"]; ok {
		environment.RepoUrl = ciProjectUrl
		environment.RemoteBranch = es["CI_COMMIT_REF_NAME"]
	} else if githubServerUrl, ok := es["GITHUB_SERVER_URL"]; ok {
		environment.RepoUrl = fmt.Sprintf("%s/%s.git", githubServerUrl, es["GITHUB_REPOSITORY"])
		brSplit := strings.Split(es["GITHUB_REF"], "/")
		environment.RemoteBranch = brSplit[len(brSplit)-1]
	} else {
		dir, err := os.Getwd()
		if err != nil {
			return err
		}
		repo, err := git.PlainOpen(dir)
		if err != nil {
			return err
		}
		br, err := getCurrentBranch(repo)
		if err != nil {
			return err
		}
		environment.Remote = br.Remote
		environment.RemoteBranch = br.Name

		r, err := repo.Remote(br.Remote)
		if err != nil {
			return err
		}

		environment.RemoteUrl = r.Config().URLs[0]

		if _, err := url.Parse(environment.RemoteUrl); err == nil {
			environment.RepoUrl = environment.RemoteUrl
		} else {
			// Not a URL
			re := regexp.MustCompile(`[^@]+@([^:]+):([^/]+)/(.*)\.git`)
			m := re.FindStringSubmatch(environment.RemoteUrl)
			environment.RepoUrl = fmt.Sprintf("https://%s/%s/%s.git", m[1], m[2], m[3])
		}
	}

	environment.ClusterName = environment.RemoteBranch
	environment.ArtifactsDir = fmt.Sprintf("terraform/terraform.tfstate.d/%s", environment.ClusterName)

	return err
}

func getCurrentBranch(repo *git.Repository) (*gitconfig.Branch, error) {
	h, err := repo.Head()
	if err != nil {
		return nil, err
	}

	b := strings.TrimPrefix(h.Name().String(), "refs/heads/")
	fmt.Println("looking for branch", b)
	return repo.Branch(b)
}
