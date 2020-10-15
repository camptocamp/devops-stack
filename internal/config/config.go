package config

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/jessevdk/go-flags"
	"gopkg.in/yaml.v2"
)

// Config is the main conf
type Config struct {
	ConfigFilePath string `short:"c" long:"config-file" default:"config.yaml" description:"configuration file"`

	BaseDomain string `short:"b" long:"base-domain" env:"BASE_DOMAIN" yaml:"base_domain" default:"127-0-0-1.nip.io" description:"base domain"`

	ClusterName string `short:"C" long:"cluster-name" description:"cluster name"`

	Distribution DistributionConfig `group:"Kubernetes Distribution" yaml:"distribution" description:"Kubernetes distribution"`

	Version bool `short:"V" long:"version" description:"Show version"`
}

// DistributionConfig sets up the k8s distro
type DistributionConfig struct {
	ContainerPlatform string `long:"container-platform" default:"k3s" description:"container platform"`
	Flavor            string `long:"flavor" default:"_" description:"distribution flavor"`
	Provider          string `long:"provider" default:"docker" description:"distribution provider"`
}

// LoadConfigFromYaml loads the config from config file
func (c *Config) LoadConfigFromYaml() *Config {
	fmt.Printf("Loading config from %s\n", c.ConfigFilePath)
	yamlFile, err := ioutil.ReadFile(c.ConfigFilePath)
	if err != nil {
		log.Printf("yamlFile.Get err #%v ", err)
	}

	err = yaml.Unmarshal(yamlFile, c)
	if err != nil {
		log.Fatalf("Unmarshal err: %v", err)
	}

	return c
}

// LoadConfig loads the config from flags & environment
func LoadConfig(version string) *Config {
	var c Config
	parser := flags.NewParser(&c, flags.Default)
	if _, err := parser.Parse(); err != nil {
		os.Exit(1)
	}

	if c.ConfigFilePath != "" {
		if _, err := os.Stat(c.ConfigFilePath); err == nil {
			c.LoadConfigFromYaml()
		} else {
			fmt.Printf("File %s doesn't exists!\n", c.ConfigFilePath)
			os.Exit(1)
		}
	}

	if c.Version {
		fmt.Printf("DevBootOps v%v\n", version)
		os.Exit(0)
	}

	return &c
}
