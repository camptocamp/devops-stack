package distribution

import (
	"fmt"

	"github.com/camptocamp/camptocamp-devops-stack/internal/config"
)

type Distribution interface {
	DistPath() string
	PreScript() error
	PostScript() error
}

func New(c config.DistributionConfig) (d Distribution, err error) {
	switch c.ContainerPlatform {
	case "k3s":
		return NewK3sDistribution(c), nil
	default:
		return d, fmt.Errorf("Unknown container platform type: %v", c.ContainerPlatform)
	}

	return
}
