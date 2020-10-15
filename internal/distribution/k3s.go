package distribution

import (
	"fmt"
	"io/ioutil"
	"os/exec"
	"path"
	"strings"

	"github.com/camptocamp/camptocamp-devops-stack/internal/config"
)

type K3sDistribution struct {
	*GenericDistribution
}

func NewK3sDistribution(c config.DistributionConfig) *K3sDistribution {
	return &K3sDistribution{
		&GenericDistribution{c},
	}
}

func (d *K3sDistribution) PreScript() error {
	switch d.Config.Provider {
	case "docker":
		return d.dockerCopyKubeconfig()
	default:
		return fmt.Errorf("Unknown provider %s for k3s distribution", d.Config.Provider)
	}
	return nil
}

func (d *K3sDistribution) dockerCopyKubeconfig() error {
	src := fmt.Sprintf("k3s-server-%s:/etc/rancher/k3s/k3s.yaml")
	dst := path.Join(d.ArtifactsPath(), "kubeconfig.yaml")
	cmd := exec.Command("docker", "cp", src, dst)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to copy kubeconfig: %v", err)
	}
	conf, err := ioutil.ReadFile(dst)
	if err != nil {
		return fmt.Errorf("failed to read kubeconfig: %v", err)
	}
	newConf := strings.Replace(string(conf), "127.0.0.1", apiIPAddress)

	if err := ioutil.WriteFile(dst, []byte(newConf), 0); err != nil {
		return fmt.Errorf("failed to modify kubeconfig: %v", err)
	}

	return nil
}

func (d *K3sDistribution) PostScript() error {
	return nil
}
