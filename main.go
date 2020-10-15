// Deploy a K3S environment with ArgoCD and sample apps
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path"

	"github.com/camptocamp/camptocamp-devops-stack/internal/config"
	"github.com/camptocamp/camptocamp-devops-stack/internal/distribution"
	log "github.com/sirupsen/logrus"
)

var version = "undefined"

func main() {
	c := config.LoadConfig(version)

	action := os.Args[1]
	var err error

	switch action {
	case "test":
		err = test(c)
	case "deploy":
		err = deploy(c)
	case "provision":
		err = provision(c)
	case "clean":
		err = clean(c)
	case "debug":
	default:
		fmt.Errorf("Unknown action %s", action)
	}

	if err != nil {
		fmt.Errorf("%v", err)
	}
}

// Tests the resulting URLs
func test(c *config.Config) error {
	return nil
}

// Deploys ArgoCD and apps
func deploy(c *config.Config) error {
	return nil
}

// Provisions K3S
func provision(c *config.Config) error {
	log.Info("Provision")

	dist, err := distribution.New(c.Distribution)
	if err != nil {
		return fmt.Errorf("Failed to initialize distribution: %v", err)
	}

	if err := dist.PreScript(); err != nil {
		return fmt.Errorf("Failed to execute pre-script: %v", err)
	}

	distPath := dist.DistPath()
	tfPath := path.Join("distributions", distPath, "terraform")

	log.Info("provision: init")
	cmd := exec.Command("terraform", "init", "--upgrade")
	cmd.Dir = tfPath
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("provision: failed to initialize Terraform (1): %v", err)
	}

	log.Info("provision: workspace")
	cmd = exec.Command("terraform", "workspace", "select", c.Distribution.ClusterName)
	cmd.Dir = tfPath
	if err := cmd.Run(); err != nil {
		cmd = exec.Command("terraform", "workspace", "new", c.Distribution.ClusterName)
		cmd.Dir = tfPath
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("provision: failed to create Terraform worspace: %v", err)
		}
	}

	log.Info("provision: init")
	cmd = exec.Command("terraform", "init", "--upgrade")
	cmd.Dir = tfPath
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("provision: failed to initialize Terraform (2): %v", err)
	}

	log.Info("provision: apply")
	cmd = exec.Command("terraform", "apply", "--auto-approve")
	cmd.Dir = tfPath
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("provision: failed to apply Terraform: %v", err)
	}

	log.Info("provision: plan")
	cmd = exec.Command("terraform", "plan", "--detailed-exitcode")
	cmd.Dir = tfPath
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("provision: failed to verify Terraform plan: %v", err)
	}

	if err := dist.PostScript(); err != nil {
		return fmt.Errorf("Failed to execute post-script: %v", err)
	}

	return nil
}

// Cleans the deployment
func clean(c *config.Config) error {
	/*
		dir, err := os.Getwd()
		if err != nil {
			return err
		}

		cmd := exec.Command("./scripts/destroy.sh")
		cmd.Env = os.Environ()

		if err := cmd.Run(); err != nil {
			return err
		}

		err = os.RemoveAll(path.Join(dir, c.ArtifactsDir))
		if err != nil {
			return err
		}

	*/
	return nil
}

// Prints the environment variables
func debug(c *config.Config) error {
	fmt.Println("BASE_DOMAIN =", c.BaseDomain)

	/*
		fmt.Println("REPO_URL =", c.RepoUrl)
		fmt.Println("REMOTE =", c.Remote)
		fmt.Println("REMOTE_BRANCH =", c.RemoteBranch)
		fmt.Println("REMOTE_URL =", c.RemoteUrl)

		fmt.Println("CLUSTER_NAME =", c.ClusterName)
		fmt.Println("ARTIFACTS_DIR =", c.ArtifactsDir)
	*/

	return nil
}

// Retrieves and computes the environment variables
func env() error {
	/*
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
	*/
	return nil
}

/*
func getCurrentBranch(repo *git.Repository) (*gitconfig.Branch, error) {
	h, err := repo.Head()
	if err != nil {
		return nil, err
	}

	b := strings.TrimPrefix(h.Name().String(), "refs/heads/")
	return repo.Branch(b)
}
*/
