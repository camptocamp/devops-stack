package distribution

import (
	"path"

	"github.com/camptocamp/camptocamp-devops-stack/internal/config"
)

type GenericDistribution struct {
	Config config.DistributionConfig
}

func (d *GenericDistribution) DistPath() string {
	return path.Join(d.Config.ContainerPlatform, d.Config.Flavor, d.Config.Provider)
}

func (d *GenericDistribution) ArtifactsPath() string {
	return path.Join("distributions", d.DistPath(), "terraform", "terraform.tfstate.d", d.Config.ClusterName)
}
