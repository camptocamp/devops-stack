//+build mage

// Deploy a K3S environment with ArgoCD and sample apps
package main

import (
	"fmt"
	"net/url"
	"os"
	"os/user"
	"path"
	"regexp"
	"strings"
	"syscall"

	env "github.com/Netflix/go-env"
	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
	"gopkg.in/src-d/go-git.v4"
	gitconfig "gopkg.in/src-d/go-git.v4/config"
)

type Environment struct {
	Home string `env:"HOME"`

	BaseDomain string `env:"BASE_DOMAIN,default=127-0-0-1.nip.io"`
	DockerHost string `env:"DOCKER_HOST,default=tcp://127.0.0.1:2376/"`

	RepoUrl      string
	Remote       string
	RemoteBranch string
	RemoteUrl    string

	ClusterName  string
	ArtifactsDir string

	DockerGid uint32
}

var environment Environment

// Tests the resulting URLs
func Test() error {
	mg.Deps(Deploy)
	return nil
}

// Deploys ArgoCD and apps
func Deploy() error {
	mg.Deps(Provision)
	return nil
}

// Provivisions K3S
func Provision() error {
	mg.Deps(Env)
	return nil
}

// Cleans the deployment
func Clean() error {
	mg.Deps(Env)

	terraformrc, err := os.Create(path.Join(environment.Home, ".terraformrc"))
	if err != nil {
		return err
	}

	usr, _ := user.Current()

	dir, err := os.Getwd()
	if err != nil {
		return err
	}

	// TODO: use Docker go sdk
	sh.Run("docker", "run", "--rm",
		"--group-add", string(environment.DockerGid),
		"--user", fmt.Sprintf("%v:%v", usr.Uid, usr.Gid),
		"-v", "/var/run/docker.sock:/var/run/docker.sock",
		"-v", fmt.Sprintf("%s:/workdir", dir),
		"-v", fmt.Sprintf("%s:/tmp/.terraformrc", terraformrc),
		"-v", fmt.Sprintf("%s:/tmp/.terraform.d", path.Join(environment.Home, ".terraform.d")),
		"--env", "HOME=/tmp",
		"--env", fmt.Sprintf("TF_VAR_k3s_kubeconfig_dir=%s", dir),
		"--env", fmt.Sprintf("CLUSTER_NAME=%s", environment.ClusterName),
		"--entrypoint", "",
		"--workdir", "/workdir",
		"hashicorp/terraform:0.13.3", "/workdir/scripts/destroy.sh",
	)

	err = os.RemoveAll(path.Join(dir, environment.ArtifactsDir))
	if err != nil {
		return err
	}

	return nil
}

// Prints the environment variables
func Debug() error {
	mg.Deps(Env)

	fmt.Println("BASE_DOMAIN =", environment.BaseDomain)
	fmt.Println("DOCKER_HOST =", environment.DockerHost)

	fmt.Println("REPO_URL =", environment.RepoUrl)
	fmt.Println("REMOTE =", environment.Remote)
	fmt.Println("REMOTE_BRANCH =", environment.RemoteBranch)
	fmt.Println("REMOTE_URL =", environment.RemoteUrl)

	fmt.Println("CLUSTER_NAME =", environment.ClusterName)
	fmt.Println("ARTIFACTS_DIR =", environment.ArtifactsDir)

	return nil
}

// Retrieves and computes the environment variables
func Env() error {
	es, err := env.UnmarshalFromEnviron(&environment)
	if err != nil {
		return err
	}

	fi, err := os.Stat("/var/run/docker.sock")
	if err != nil {
		return err
	}
	if stat, ok := fi.Sys().(*syscall.Stat_t); ok {
		environment.DockerGid = stat.Gid
	} else {
		return fmt.Errorf("Failed to get DOCKER_GID")
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
	return repo.Branch(b)
}
