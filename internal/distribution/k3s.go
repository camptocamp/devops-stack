package distribution

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"strings"

	"github.com/camptocamp/camptocamp-devops-stack/internal/config"
	"github.com/hashicorp/terraform/addrs"
	"github.com/hashicorp/terraform/states/statefile"
)

type K3sDistribution struct {
	*GenericDistribution
}

func NewK3sDistribution(c config.DistributionConfig) *K3sDistribution {
	return &K3sDistribution{
		&GenericDistribution{c},
	}
}

func (d *K3sDistribution) BaseDomain() string {
	ipAddress, err := d.apiIPAddress()
	// TODO: error?
	if err != nil {
		return ""
	}
	domain := strings.Replace(ipAddress, ".", "-", -1)
	return fmt.Sprintf(domain, ".nip.io")
}

func (d *K3sDistribution) GetKubeconfig() error {
	switch d.Config.Provider {
	case "docker":
		return d.dockerCopyKubeconfig()
	default:
		return fmt.Errorf("Unknown provider %s for k3s distribution", d.Config.Provider)
	}
	return nil
}

func (d *K3sDistribution) apiIPAddress() (string, error) {
	file := path.Join(d.ArtifactsPath(), "terraform.tfstate")
	state, err := os.Open(file)
	if err != nil {
		return "", fmt.Errorf("failed to read Terraform state file: %v", err)
	}
	sf, err := statefile.Read(state)
	if err != nil {
		return "", fmt.Errorf("failed to parse Terraform state: %v", err)
	}
	attrsJSON := sf.State.Modules["root"].Resources["docker_container.k3s_server"].Instances[addrs.IntKey(0)].Current.AttrsJSON
	attrs := make(map[string]string)
	if err = json.Unmarshal(attrsJSON, &attrs); err != nil {
		return "", fmt.Errorf("failed to unmashal attributes: %v", err)
	}

	if ipAddress, ok := attrs["ip_address"]; ok {
		return ipAddress, nil
	}
	return "", fmt.Errorf("failed to get API IP address from Terraform state")
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
	ipAddress, err := d.apiIPAddress()
	if err != nil {
		return fmt.Errorf("failed to get API IP address: %v", err)
	}
	newConf := strings.Replace(string(conf), "127.0.0.1", ipAddress, -1)

	if err := ioutil.WriteFile(dst, []byte(newConf), 0); err != nil {
		return fmt.Errorf("failed to modify kubeconfig: %v", err)
	}

	return nil
}

func (d *K3sDistribution) ProvisionPostHook() error {
	return nil
}

func (d *K3sDistribution) Values(repoUrl string, targetRevision string) string {
	return ""
}
