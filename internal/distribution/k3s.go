package distribution

import "github.com/camptocamp/camptocamp-devops-stack/internal/config"

type K3sDistribution struct {
	*GenericDistribution
}

func NewK3sDistribution(c config.DistributionConfig) *K3sDistribution {
	return &K3sDistribution{
		&GenericDistribution{c},
	}
}

func (d *K3sDistribution) PreScript() error {
	return nil
}

func (d *K3sDistribution) PostScript() error {
	return nil
}
